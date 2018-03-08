// *** Filename: U3IR.c
// *** Author: M. Hernandez
// *** Purpose: Send a TTL Low pulse to FIO3 		
// *** Date: 2-22-2018
// *** version 1.0 -- Initial revision

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>
#include <termios.h>
#include <fcntl.h>  
#include <unistd.h>
#include <dirent.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/time.h>
#include "U3.h"
#include "mex.h"
#include "matrix.h"

#define OPERAND_NAME_LENGTH    32

static HANDLE hDevice;
u3CalibrationInfo caliInfo;
int isDAC1Enabled;

//
// Mex file prototypes
//
int openUE3device();
int closeUE3device();

// Local prototypes
int sendTTLpulse(); 

/* Getaway function */
void mexFunction(int nlhs,      /* number of output (return) arguments */
      mxArray *plhs[],          /* pointer to an array which will hold the output data, each element is of type: mxArray */
      int nrhs,                 /* number of input arguments */
      const mxArray *prhs[]     /* pointer to an array which holds the input data, each element is of type: const mxArray */
      )
{

	/* Create an 1x1 array of unsigned 32-bit integer to store the status  */
    /* This will be the first output argument */
    const size_t dims[] = {1, 1};
    size_t nDims = 2;
    plhs[0] = mxCreateNumericArray(nDims, dims, mxINT32_CLASS, mxREAL);
    int *status;
    status = (int *) mxGetData(plhs[0]);
    
    // Check for at least 1 input argument
    if (nrhs < 1) {
        mexErrMsgTxt("u3IR: Requires at least one input argument.");
    }
    
    // Get the first input argument (operand name)
    char operandName[OPERAND_NAME_LENGTH];
    if (mxIsChar(prhs[0]) != 1)
        mexErrMsgTxt("u3IR: First argument must be an operation string.");
	else
		mxGetString(prhs[0], operandName, sizeof(operandName));
    
    // During open, send the TTL pulse, inside open close 
    // the connection
   if (strcmp(operandName, "open_sendTTL")==0) {
        *status = openUE3device();
    } else if (strcmp(operandName, "close")==0) {
        *status = closeUE3device();
    } else printf("Unknown command name, %s", operandName);
}

//
// Open the USB connection with the device, send TTL and close
//
int openUE3device() 
{
    int status;
        
    if ( (hDevice = openUSBConnection(-1)) == NULL) {
        return 0;  // could not open device
    }
   
    // send the TTL pulse to the arduino to start the LED
    status = sendTTLpulse();
    
    mexPrintf("status of sentTTLpulse: %d\n", status);
            
    if(status==0){
        return 0;
    }
    
    mexPrintf("\nAll OK till TTL pulse sent \n");
    
    // Now close the USB connection 
    status = closeUE3device();
    if(status==0) return 0; // if status is 0 there is an error

     mexPrintf("\nAll OK till closing USB connection \n");

    // Success opening, sending TTL and closing the device 
    return 1;
   
}

int closeUE3device() 
{
    if (hDevice != NULL) {
        closeUSBConnection(hDevice);
        hDevice = NULL;
         mexPrintf("U3 device was closed.\n");
    }
    else {
        mexPrintf("U3 device was not open.\n");
    }
    return(1); 
}

//
// Call to send a simple TTL pulse thru FIO0
//
int sendTTLpulse()
{
    //Set FIO3 to output-high
    printf("\nCalling eDO to set FIO3 to output-HIGH\n");
    if( eDO(hDevice, 1, 3, 1) != 0 )
        return -1;
    
    printf("\nCalling eDO to set FIO3 to output-LOW\n");
    if( eDO(hDevice, 1, 3, 0) != 0 )
        return -1;
    
    printf("\nCalling eDO to set FIO3 to output-HIGH\n");
    if( eDO(hDevice, 1, 3, 1) != 0 )
        return -1;
 
    mexPrintf("\nSuccess in sending the TTL pulse!.\n");
    
    // Success in sending the TTL pulse
    return 1; 
}

HANDLE openUSBConnection(int localID)
{
    uint8 buffer[38];  //send size of 26, receive size of 38
    uint16 checksumTotal = 0;
    uint32 numDevices = 0;
    uint32 dev;
    int i, serial;
    HANDLE hDevice = 0;

    numDevices = LJUSB_GetDevCount(U3_PRODUCT_ID);
    if( numDevices == 0 )
    {
        printf("Open error: No U3 devices could be found\n");
        return NULL;
    }

    for( dev = 1;  dev <= numDevices; dev++ )
    {
        hDevice = LJUSB_OpenDevice(dev, 0, U3_PRODUCT_ID);
        if( hDevice != NULL )
        {
            if( localID < 0 )
            {
                return hDevice;
            }
            else
            {
                checksumTotal = 0;

                //Setting up a ConfigU3 command
                buffer[1] = (uint8)(0xF8);
                buffer[2] = (uint8)(0x0A);
                buffer[3] = (uint8)(0x08);

                for( i = 6; i < 38; i++ )
                    buffer[i] = (uint8)(0x00);

                extendedChecksum(buffer, 26);

                if( LJUSB_Write(hDevice, buffer, 26) != 26 )
                    goto locid_error;

                if( LJUSB_Read(hDevice, buffer, 38) != 38 )
                    goto locid_error;

                checksumTotal = extendedChecksum16(buffer, 38);
                if( (uint8)((checksumTotal / 256) & 0xFF) != buffer[5] )
                    goto locid_error;

                if( (uint8)(checksumTotal & 0xFF) != buffer[4] )
                    goto locid_error;

                if( extendedChecksum8(buffer) != buffer[0] )
                    goto locid_error;

                if( buffer[1] != (uint8)(0xF8) || buffer[2] != (uint8)(0x10) ||
                    buffer[3] != (uint8)(0x08) )
                    goto locid_error;

                if( buffer[6] != 0 )
                    goto locid_error;

                //Check local ID
                if( (int)buffer[21] == localID )
                    return hDevice;

                //Check serial number
                serial = (int)(buffer[15] + buffer[16]*256 + buffer[17]*65536 +
                               buffer[18]*16777216);
                if( serial == localID )
                    return hDevice;

                //No matches, not our device
                LJUSB_CloseDevice(hDevice);
            } //else localID >= 0 end
        } //if hDevice != NULL end
    } //for end

    printf("Open error: could not find a U3 with a local ID or serial number of %d\n", localID);
    return NULL;

locid_error:
    printf("Open error: problem when checking local ID\n");
    return NULL;
}


void closeUSBConnection(HANDLE hDevice)
{
    LJUSB_CloseDevice(hDevice);
}



// ed0 - used to toggle a pin 
long eDO(HANDLE Handle, long ConfigIO, long Channel, long State)
{
    uint8 sendDataBuff[4];
    uint8 Errorcode, ErrorFrame, FIOAnalog, EIOAnalog;
    uint8 curFIOAnalog, curEIOAnalog, curTCConfig;
    long error;

    if( Channel < 0 || Channel > 19 )
    {
        printf("eD0 error: Invalid DI channel\n");
        return -1;
    }

    if( ConfigIO != 0 && Channel <= 15 )
    {
        FIOAnalog = 255;
        EIOAnalog = 255;

        //Setting Channel to digital using FIOAnalog and EIOAnalog
        if( Channel <= 7 )
            FIOAnalog = 255 - pow(2, Channel);
        else
            EIOAnalog = 255 - pow(2, (Channel - 8));

        //Using ConfigIO to get current FIOAnalog and EIOAnalog settings
        error = ehConfigIO(Handle, 0, 0, 0, 0, 0, &curTCConfig, NULL, &curFIOAnalog, &curEIOAnalog);
        if( error != 0 )
            return error;

        if( !(FIOAnalog == curFIOAnalog && EIOAnalog == curEIOAnalog) )
        {
            //Using ConfigIO to get current FIOAnalog and EIOAnalog settings
            FIOAnalog = FIOAnalog & curFIOAnalog;
            EIOAnalog = EIOAnalog & curEIOAnalog;

            //Using ConfigIO to set new FIOAnalog and EIOAnalog settings
            error = ehConfigIO(Handle, 12, curTCConfig, 0, FIOAnalog, EIOAnalog, NULL, NULL, &curFIOAnalog, &curEIOAnalog);
            if( error != 0 )
                return error;
        }
    }

    /* Setting up Feedback command to set digital Channel to output and to set the state */
    sendDataBuff[0] = 13;  //IOType is BitDirWrite
    sendDataBuff[1] = Channel + 128;  //IONumber(bits 0-4) + Direction (bit 7)

    sendDataBuff[2] = 11;  //IOType is BitStateWrite
    sendDataBuff[3] = Channel + 128*((State > 0) ? 1 : 0);  //IONumber(bits 0-4) + State (bit 7)

    if( ehFeedback(Handle, sendDataBuff, 4, &Errorcode, &ErrorFrame, NULL, 0) < 0 )
        return -1;
    if( Errorcode )
        return (long)Errorcode;

    return 0;
}

// <MH> ehFeedback -- called from ed0
long ehFeedback(HANDLE hDevice, uint8 *inIOTypesDataBuff, long inIOTypesDataSize, uint8 *outErrorcode, uint8 *outErrorFrame, uint8 *outDataBuff, long outDataSize)
{
    uint8 *sendBuff, *recBuff;
    uint16 checksumTotal;
    int sendChars, recChars, sendDWSize, recDWSize;
    int commandBytes, ret, i;

    ret = 0;
    commandBytes = 6;

    if( ((sendDWSize = inIOTypesDataSize + 1)%2) != 0 )
        sendDWSize++;
    if( ((recDWSize = outDataSize + 3)%2) != 0 )
        recDWSize++;

    sendBuff = (uint8 *)malloc(sizeof(uint8)*(commandBytes + sendDWSize));
    recBuff = (uint8 *)malloc(sizeof(uint8)*(commandBytes + recDWSize));
    if( sendBuff == NULL || recBuff == NULL )
    {
        ret = -1;
        goto cleanmem;
    }

    sendBuff[sendDWSize + commandBytes - 1] = 0;

    /* Setting up Feedback command */
    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = sendDWSize/2;  //Number of data words (.5 word for echo, 1.5
                                 //                      words for IOTypes)
    sendBuff[3] = (uint8)(0x00);  //Extended command number

    sendBuff[6] = 0;  //Echo

    for( i = 0; i < inIOTypesDataSize; i++ )
        sendBuff[i+commandBytes+1] = inIOTypesDataBuff[i];

    extendedChecksum(sendBuff, (sendDWSize+commandBytes));

    //Sending command to U3
    if( (sendChars = LJUSB_Write(hDevice, sendBuff, (sendDWSize+commandBytes))) < sendDWSize+commandBytes )
    {
        if( sendChars == 0 )
            printf("ehFeedback error : write failed\n");
        else
            printf("ehFeedback error : did not write all of the buffer\n");
        ret = -1;
        goto cleanmem;
    }

    //Reading response from U3
    if( (recChars = LJUSB_Read(hDevice, recBuff, (commandBytes+recDWSize))) < commandBytes+recDWSize )
    {
        if( recChars == -1 )
        {
            printf("ehFeedback error : read failed\n");
            ret = -1;
            goto cleanmem;
        }
        else if( recChars < 8 )
        {
            printf("ehFeedback error : response buffer is too small\n");
            ret = -1;
            goto cleanmem;
        }
        else
            printf("ehFeedback error : did not read all of the expected buffer (received %d, expected %d )\n", recChars, commandBytes+recDWSize);
    }

    checksumTotal = extendedChecksum16(recBuff, recChars);
    if( (uint8)((checksumTotal / 256 ) & 0xff) != recBuff[5] )
    {
        printf("ehFeedback error : read buffer has bad checksum16(MSB)\n");
        ret = -1;
        goto cleanmem;
    }

    if( (uint8)(checksumTotal & 0xff) != recBuff[4] )
    {
        printf("ehFeedback error : read buffer has bad checksum16(LBS)\n");
        ret = -1;
        goto cleanmem;
    }

    if( extendedChecksum8(recBuff) != recBuff[0] )
    {
        printf("ehFeedback error : read buffer has bad checksum8\n");
        ret = -1;
        goto cleanmem;
    }

    if( recBuff[1] != (uint8)(0xF8) || recBuff[3] != (uint8)(0x00) )
    {
        printf("ehFeedback error : read buffer has wrong command bytes \n");
        ret = -1;
        goto cleanmem;
    }

    *outErrorcode = recBuff[6];
    *outErrorFrame = recBuff[7];

    for( i = 0; i+commandBytes+3 < recChars && i < outDataSize; i++ )
        outDataBuff[i] = recBuff[i+commandBytes+3];

cleanmem:
    free(sendBuff);
    free(recBuff);
    sendBuff = NULL;
    recBuff = NULL;

    return ret;
}


// U3.c support
u3CalibrationInfo U3_CALIBRATION_INFO_DEFAULT = {
    3,
    1.31,
    0,
    //Nominal Values
    {   0.000037231,
        0.0,
        0.000074463,
        -2.44,
        51.717,
        0.0,
        51.717,
        0.0,
        0.013021,
        2.44,
        3.66,
        3.3,
        0.000314,
        0.000314,
        0.000314,
        0.000314,
        -10.3,
        -10.3,
        -10.3,
        -10.3}
};


void extendedChecksum(uint8 *b, int n)
{
    uint16 a;

    a = extendedChecksum16(b, n);
    b[4] = (uint8)(a & 0xFF);
    b[5] = (uint8)((a/256) & 0xFF);
    b[0] = extendedChecksum8(b);
}

uint16 extendedChecksum16(uint8 *b, int n)
{
    int i, a = 0;

    //Sums bytes 6 to n-1 to a unsigned 2 byte value
    for( i = 6; i < n; i++ )
        a += (uint16)b[i];

    return a;
}


uint8 extendedChecksum8(uint8 *b)
{
    int i, a, bb;

    //Sums bytes 1 to 5. Sums quotient and remainder of 256 division. Again,
    //sums quotient and remainder of 256 division.
    for( i = 1, a = 0; i < 6; i++ )
        a += (uint16)b[i];

    bb=a / 256;
    a=(a - 256*bb) + bb;
    bb=a / 256;

    return (uint8)((a - 256*bb) + bb);
}

long ehConfigIO(HANDLE hDevice, uint8 inWriteMask, uint8 inTimerCounterConfig, uint8 inDAC1Enable, uint8 inFIOAnalog, uint8 inEIOAnalog, uint8 *outTimerCounterConfig, uint8 *outDAC1Enable, uint8 *outFIOAnalog, uint8 *outEIOAnalog)
{
    uint8 sendBuff[12], recBuff[12];
    uint16 checksumTotal;
    int sendChars, recChars;

    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = (uint8)(0x03);  //Number of data words
    sendBuff[3] = (uint8)(0x0B);  //Extended command number

    sendBuff[6] = inWriteMask;  //Writemask

    sendBuff[7] = 0;  //Reserved
    sendBuff[8] = inTimerCounterConfig;  //TimerCounterConfig
    sendBuff[9] = inDAC1Enable;  //DAC1 enable : not enabling
    sendBuff[10] = inFIOAnalog;  //FIOAnalog
    sendBuff[11] = inEIOAnalog;  //EIOAnalog
    extendedChecksum(sendBuff, 12);

    //Sending command to U3
    if( (sendChars = LJUSB_Write(hDevice, sendBuff, 12)) < 12 )
    {
        if( sendChars == 0 )
            printf("ehConfigIO error : write failed\n");
        else
            printf("ehConfigIO error : did not write all of the buffer\n");
        return -1;
    }

    //Reading response from U3
    if( (recChars = LJUSB_Read(hDevice, recBuff, 12)) < 12 )
    {
        if( recChars == 0 )
            printf("ehConfigIO error : read failed\n");
        else
            printf("ehConfigIO error : did not read all of the buffer\n");
        return -1;
    }

    checksumTotal = extendedChecksum16(recBuff, 12);
    if( (uint8)((checksumTotal / 256 ) & 0xff) != recBuff[5] )
    {
        printf("ehConfigIO error : read buffer has bad checksum16(MSB)\n");
        return -1;
    }

    if( (uint8)(checksumTotal & 0xff) != recBuff[4] )
    {
        printf("ehConfigIO error : read buffer has bad checksum16(LBS)\n");
        return -1;
    }

    if( extendedChecksum8(recBuff) != recBuff[0] )
    {
        printf("ehConfigIO error : read buffer has bad checksum8\n");
        return -1;
    }

    if( recBuff[1] != (uint8)(0xF8) || recBuff[2] != (uint8)(0x03) || recBuff[3] != (uint8)(0x0B) )
    {
        printf("ehConfigIO error : read buffer has wrong command bytes\n");
        return -1;
    }

    if( recBuff[6] != 0 )
    {
        printf("ehConfigIO error : read buffer received errorcode %d\n", recBuff[6]);
        return (int)recBuff[6];
    }

    if( outTimerCounterConfig != NULL )
        *outTimerCounterConfig = recBuff[8];
    if( outDAC1Enable != NULL )
        *outDAC1Enable = recBuff[9];
    if( outFIOAnalog != NULL )
        *outFIOAnalog = recBuff[10];
    if( outEIOAnalog != NULL )
        *outEIOAnalog = recBuff[11];

    return 0;
}

