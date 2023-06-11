import {
  Box,
  Button,
  CardActions,
  CardContent,
  Typography,
} from '@mui/material';
import { Stack } from '@mui/system';
import React from 'react';
import { OnboardingComponent, OnboardingComponentProps } from '../types';

const Onboarding: OnboardingComponent = ({
  onOnboardingComplete,
}: OnboardingComponentProps) => {
  return (
    <Box sx={{ padding: 2 }}>
      <CardContent>
        <Typography variant="h3" gutterBottom>
        🌈Welcome to Discovery Account!
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Here is a new way to interact with DeFI on 
           <b> Ethereum ecosystem with Optimism & Scroll !</b>
          <br />
          By continuing, you will generate your account (AA : an abstracted account) 
          which will lead to the simplest use of DeFI you’ve never witnessed !
          <br />
        </Typography>
        
      </CardContent>
      <CardActions sx={{ pl: 4, pr: 4, width: '100%' }}>
        <Stack spacing={2} sx={{ width: '100%' }}>
          <Button
            size="large"
            variant="contained"
            onClick={() => onOnboardingComplete()}
          >
            Onboard ⏭
          </Button>
        </Stack>
      </CardActions>
    </Box>
  );
};

export default Onboarding;
