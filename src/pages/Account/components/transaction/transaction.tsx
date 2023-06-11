import {
  Button,
  CardActions,
  CardContent,
  CircularProgress,
  Stack,
  Typography,
} from '@mui/material';
import React from 'react';
import { EthersTransactionRequest } from '../../../Background/services/provider-bridge';
import { TransactionComponentProps } from '../types';

const Transaction = ({
  transaction,
  onComplete,
  onReject,
}: TransactionComponentProps) => {
  const [loader, setLoader] = React.useState<boolean>(false);

  return (
    <>
      <CardContent>
        <Typography variant="h3" gutterBottom>
        ⚠️ Warning 
        </Typography>
        <Typography variant="body1" color="text.secondary">
          You will interact with a contract and issue a transaction.
          <br />
          This can only succeed if you have whitelisted it before.
        </Typography>
        <Typography variant="caption">
          <a href='https://web-app-woad-five.vercel.app/'>Go to Dashboard</a>
        </Typography>
      </CardContent>
      <CardActions sx={{ pl: 4, pr: 4, width: '100%' }}>
        <Stack spacing={2} sx={{ width: '100%' }}>
          <Button
            disabled={loader}
            size="large"
            variant="contained"
            onClick={() => {
              onComplete(transaction, undefined);
              setLoader(true);
            }}
          >
            Continue
            {loader && (
              <CircularProgress
                size={24}
                sx={{
                  position: 'absolute',
                  top: '50%',
                  left: '50%',
                  marginTop: '-12px',
                  marginLeft: '-12px',
                }}
              />
            )}
          </Button>
        </Stack>
      </CardActions>
    </>
  );
};

export default Transaction;
