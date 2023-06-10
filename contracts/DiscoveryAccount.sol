// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol';

import '@account-abstraction/contracts/core/BaseAccount.sol';
import './TokenCallbackHandler.sol';

/**
 * minimal account.
 *  this is sample minimal account.
 *  has execute, eth handling methods
 *  has a single signer that can send requests through the entryPoint.
 */
contract DiscoveryAccount is
    BaseAccount,
    TokenCallbackHandler,
    UUPSUpgradeable,
    Initializable
{
    using ECDSA for bytes32;

    // receiver address => allowed?
    mapping(address => bool) public allowedReceivers; // used to send native tokens
    // contract address => allowed?
    mapping(address => bool) public allowedContracts; // used th interact with other contracts

    address public owner;

     // the proposal to recover the account:
    // - any of the recovery addresses can propose a recovery
    // - the other recovery address must confirm the proposal
    address[2] public recover; // When a recovery is proposed, the array is filled with the proposed address and the proposer 

    uint256 public lastRecoveryRequest; // block number of the last recovery request. It is used to prevent multiple recovery requests in a short time and blocks the '
    uint256 public lastTxTimestamp; // last tx block, used to allow recovery only after a certain time
    uint256 public delay = 86400; // delay in seconds before recovery can be executed. 86400 seconds = 1 day
    uint256 public newRecoveryDelay = 86400; // delay in seconds before a new recovery can be executed. 86400 seconds = 1 day

    address public recoveryAddress1; // One of the signers allowed to recover the account
    address public recoveryAddress2; // One of the signers allowed to recover the account

    IEntryPoint private immutable _entryPoint;

    event DiscoveryAccountInitialized(
        IEntryPoint indexed entryPoint,
        address indexed owner
    );
    event RecoverySetup(
        address indexed recoveryAddress1,
        address indexed recoveryAddress2,
        uint256 delay
    );
    event OwnerChanged(address indexed newOwner);

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    modifier onlyRecover() {
        _onlyRecover();
        _;
    }

    /// @inheritdoc BaseAccount
    function entryPoint() public view virtual override returns (IEntryPoint) {
        return _entryPoint;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    constructor(IEntryPoint anEntryPoint) {
        _entryPoint = anEntryPoint;
        _disableInitializers();
    }

    function _onlyOwner() internal view {
        //directly from EOA owner, or through the account itself (which gets redirected through execute())
        require(
            msg.sender == owner || msg.sender == address(this),
            'only owner'
        );
    }

    function _onlyRecover() internal view {
        require(
            msg.sender == recoveryAddress1 || msg.sender == recoveryAddress2,
            'only recovery address'
        );
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(
        address dest,
        uint256 value,
        bytes calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        require(
            (allowedReceivers[dest] == true || allowedContracts[dest] == true),
            'operation not allowed'
        );
        _call(dest, value, func);
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(
        address[] calldata dest,
        bytes[] calldata func
    ) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length, 'wrong array lengths');
        for (uint256 i = 0; i < dest.length; i++) {
            require(
                allowedReceivers[dest[i]] || allowedContracts[dest[i]],
                'operation not allowed'
            );
            _call(dest[i], 0, func[i]);
        }
    }

    /**
     * @dev The _entryPoint member is immutable, to reduce gas consumption.  To upgrade EntryPoint,
     * a new implementation of DiscoveryAccount must be deployed with the new EntryPoint address, then upgrading
     * the implementation by calling `upgradeTo()`
     */
    function initialize(address anOwner) public virtual initializer {
        _initialize(anOwner);
    }

    function _initialize(address anOwner) internal virtual {
        owner = anOwner;
        allowedContracts[
            address(0x9522F29A27CaF4b82C1f22d21eAD2E081A68A899)
        ] = true;
        allowedContracts[
            address(0xe70cDC67C91d5519DD4682cA162E40480773255a)
        ] = true; //aave on sepolia

        allowedReceivers[
            address(0x9522F29A27CaF4b82C1f22d21eAD2E081A68A899)
        ] = true;

        // recovery settings
        delay = 86400; // 86400 seconds = 1 day


        emit DiscoveryAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(
            msg.sender == address(entryPoint()) || msg.sender == owner,
            'account: not Owner or EntryPoint'
        );
    }

    /// implement template method of BaseAccount
    function _validateSignature(
        UserOperation calldata userOp,
        bytes32 userOpHash
    ) internal virtual override returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * check current account deposit in the entryPoint
     */
    function getDeposit() public view returns (uint256) {
        return entryPoint().balanceOf(address(this));
    }

    /**
     * deposit more funds for this account in the entryPoint
     */
    function addDeposit() public payable {
        entryPoint().depositTo{value: msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(
        address payable withdrawAddress,
        uint256 amount
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal view override {
        (newImplementation);
        _onlyOwner();
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
    }


    // edit whitelist

    function initializeAddress(
        address[] memory whitelistContract,
        address[] memory whitelistWallet
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        for (uint i; i < whitelistContract.length; i++) {
            allowedContracts[whitelistContract[i]] = true;
        }

        for (uint j; j < whitelistContract.length; j++) {
            allowedReceivers[whitelistWallet[j]] = true;
        }
    }

    function setAllowedReceiver(
        address receiver,
        bool allowed
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        allowedReceivers[receiver] = allowed;
    }

    function setAllowedContract(
        address contractAddress,
        bool allowed
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        allowedContracts[contractAddress] = allowed;
    }

    function setupRecovery(
        address newRecoveryAddress1,
        address newRecoveryAddress2,
        uint256 delay
    ) public onlyOwner {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        require(newRecoveryAddress1 != address(0), 'invalid address');
        require(newRecoveryAddress2 != address(0), 'invalid address');
        require(newRecoveryAddress1 != newRecoveryAddress2, 'same address');
        recoveryAddress1 = newRecoveryAddress1;
        recoveryAddress2 = newRecoveryAddress2;

        emit RecoverySetup(newRecoveryAddress1, newRecoveryAddress2, delay);
    }

    function proposeRecovery(address newOwner) public onlyRecover {
        require(block.timestamp > lastRecoveryRequest + newRecoveryDelay, "Recover waiting for validation, function not available");
        require(newOwner != address(0), 'invalid address');
        require(newOwner != recoveryAddress1, 'already recovery address');
        require(newOwner != recoveryAddress2, 'already recovery address');
        require(block.timestamp > lastTxTimestamp + delay, 'too soon');
        recover[0] = newOwner;
        recover[1] = msg.sender;
    }

    function approveRecovery(bool approve) public onlyRecover {
        if(approve == false){
            recover[0] = address(0);
            recover[1] = address(0);
            newRecoveryDelay = 0;
            return;
        }
        require(block.number > lastTxTimestamp + delay, 'too soon');
        require(recover[0] != address(0), 'no recovery proposed');
        require(recover[1] == address(0), 'recovery already approved');
        owner = recover[0];
        recover[0] = address(0);
        recover[1] = address(0);
        emit OwnerChanged(owner);
    }
}
