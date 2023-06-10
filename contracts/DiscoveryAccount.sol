// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.12;

/* solhint-disable avoid-low-level-calls */
/* solhint-disable no-inline-assembly */
/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

import "@account-abstraction/contracts/core/BaseAccount.sol";
import "./TokenCallbackHandler.sol";

/**
  * minimal account.
  *  this is sample minimal account.
  *  has execute, eth handling methods
  *  has a single signer that can send requests through the entryPoint.
  */
contract DiscoveryAccount is BaseAccount, TokenCallbackHandler, UUPSUpgradeable, Initializable {
    using ECDSA for bytes32;

    // receiver address => allowed?
    mapping(address => bool) public allowedReceivers; // used to send native tokens
    // contract address => allowed?
    mapping(address => bool) public allowedContracts; // used th interact with other contracts
    // contract address => function signature => disallowed?
    mapping(address => mapping(string => bool)) public disallowedFunctions;


    address public owner;

    IEntryPoint private immutable _entryPoint;

    event DiscoveryAccountInitialized(IEntryPoint indexed entryPoint, address indexed owner);

    modifier onlyOwner() {
        _onlyOwner();
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
        require(msg.sender == owner || msg.sender == address(this), "only owner");
    }

    /**
     * execute a transaction (called directly from owner, or by entryPoint)
     */
    function execute(address dest, uint256 value, bytes calldata func) external {
        _requireFromEntryPointOrOwner();
        require(isOperationAllowed(dest, value, func), "operation not allowed");
        _call(dest, value, func);
    }

    function isOperationAllowed(address dest, uint256 value, bytes calldata func) public view returns (bool) {
        // extract function name from func
        require(
            (allowedReceivers[dest]|| allowedContracts[dest]),
            "operation not allowed"
        );
        return true;
    }

    /**
     * execute a sequence of transactions
     */
    function executeBatch(address[] calldata dest, bytes[] calldata func) external {
        _requireFromEntryPointOrOwner();
        require(dest.length == func.length, "wrong array lengths");
        for (uint256 i = 0; i < dest.length; i++) {
            isOperationAllowed(dest[i], 0, func[i]);
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
        emit DiscoveryAccountInitialized(_entryPoint, owner);
    }

    // Require the function call went through EntryPoint or owner
    function _requireFromEntryPointOrOwner() internal view {
        require(msg.sender == address(entryPoint()) || msg.sender == owner, "account: not Owner or EntryPoint");
    }

    /// implement template method of BaseAccount
    function _validateSignature(UserOperation calldata userOp, bytes32 userOpHash)
    internal override virtual returns (uint256 validationData) {
        bytes32 hash = userOpHash.toEthSignedMessageHash();
        if (owner != hash.recover(userOp.signature))
            return SIG_VALIDATION_FAILED;
        return 0;
    }

    function _call(address target, uint256 value, bytes memory data) internal {
        (bool success, bytes memory result) = target.call{value : value}(data);
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
        entryPoint().depositTo{value : msg.value}(address(this));
    }

    /**
     * withdraw value from the account's deposit
     * @param withdrawAddress target to send to
     * @param amount to withdraw
     */
    function withdrawDepositTo(address payable withdrawAddress, uint256 amount) public onlyOwner {
        entryPoint().withdrawTo(withdrawAddress, amount);
    }

    function _authorizeUpgrade(address newImplementation) internal view override {
        (newImplementation);
        _onlyOwner();
    }


    // edit whitelist

    function setAllowedReceiver(address receiver, bool allowed) public onlyOwner {
        allowedReceivers[receiver] = allowed;
    }

    function setAllowedContract(address contractAddress, bool allowed) public onlyOwner {
        allowedContracts[contractAddress] = allowed;
    }

    function setDisallowedFunction(address contractAddress, string memory functionSignature, bool disallowed) public onlyOwner {
        disallowedFunctions[contractAddress][functionSignature] = disallowed;
    }



    // utils

    // this code assumes that the callData only contains the function selector as its first 4 bytes. 
    // If your callData includes additional parameters or data, you would need to modify the code 
    // accordingly to extract the function selector correctly

    // function extractFunctionName(bytes calldata callData) public pure returns (string memory) {
    //     bytes4 functionSelector;
    //     if (callData.length >= 4) {
    //         assembly {
    //             let a := mload(0x40)
    //             let b := add(a, 32)
    //             calldatacopy(a, 4, 32)
    //             calldatacopy(b, add(4, 32), 32)
    //             let result := add(mload(a), mload(b))
    //         }
    //     }

    //     // Convert the function selector to a string
    //     string memory functionName = functionSelectorToString(functionSelector);

    //     return functionName;
    // }

    // function functionSelectorToString(bytes4 selector) internal pure returns (string memory) {
    //     bytes memory signature = new bytes(4);
    //     signature[0] = bytes1(selector);
    //     signature[1] = bytes1(selector << 8);
    //     signature[2] = bytes1(selector << 16);
    //     signature[3] = bytes1(selector << 24);

    //     bytes memory functionNameBytes = new bytes(32);
    //     uint length = 0;

    //     // Find the end of the function name
    //     for (uint i = 0; i < 32; i++) {
    //         if (signature[i] == 0x00) {
    //             break;
    //         }
    //         functionNameBytes[i] = signature[i];
    //         length++;
    //     }

    //     bytes memory trimmedFunctionNameBytes = new bytes(length);
    //     for (uint i = 0; i < length; i++) {
    //         trimmedFunctionNameBytes[i] = functionNameBytes[i];
    //     }

    //     return string(trimmedFunctionNameBytes);
    // }
/*
    function processCallData(bytes memory callData) public pure returns (string memory) {
        // Decode the call data using ethers.js
        (bytes4 selector, ) = abi.decode(callData, (bytes4, bytes));

        // Get the function name from the selector
        bytes memory functionName = abi.decode(bytes4ToString(selector), (string));

        // convert bytes to string


        return "";
    }

    // Utility function to convert bytes4 to string
    function bytes4ToString(bytes4 _bytes4) public pure returns (string memory) {
        bytes memory byteArray = new bytes(4);
        for (uint256 i = 0; i < 4; i++) {
            byteArray[i] = bytes1(uint8(uint32(_bytes4) / (2**(8*(3 - i)))));
        }
        return string(byteArray);
    }*/
}