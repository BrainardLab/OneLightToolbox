// *** Filename: U3Temp.c
// *** Purpose: Read both the internal and Ext temperature 
//			From the EI-1034 sensor and return it 
//			to a function. 
//			Many of the functions are extracted from 
//			The u3Feedback.c file to communicate with the sensor
// *** Date: 11-30-2016

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
#include "u3.h"
#include "mex.h"
#include "matrix.h"

static struct termios termNew, termOrig;
static int peek = -1;

//
// *** Prototypes
//
int configIO_example(HANDLE hDevice, int enable, int *isDAC1Enabled);
int feedback_setup_example();

#define OPERAND_NAME_LENGTH    32

static HANDLE hDevice;
u3CalibrationInfo caliInfo;
int isDAC1Enabled;

int amUE3device();
int openUE3device();
int closeUE3device();
double readTemperature(double *tmpData);

/* Getaway function */
void mexFunction(int nlhs,      /* number of output (return) arguments */
      mxArray *plhs[],          /* pointer to an array which will hold the output data, each element is of type: mxArray */
      int nrhs,                 /* number of input arguments */
      const mxArray *prhs[]     /* pointer to an array which holds the input data, each element is of type: const mxArray */
      )
{

	/* Create an 1x1 array of unsigned 32-bit integer to store the status  */
    /* This will be the first output argument */
    const int dims[] = {1, 1};
    int nDims = 2;
    plhs[0] = mxCreateNumericArray(nDims, dims, mxINT32_CLASS, mxREAL);
    int *status;
    status = (int *) mxGetData(plhs[0]);
    
    // Check for at least 1 input argument
    if (nrhs < 1) {
        mexErrMsgTxt("LJTemperatureProbe: Requires at least one input argument.");
    }
    
    // Get the first input argument (operand name)
    char operandName[OPERAND_NAME_LENGTH];
    if (mxIsChar(prhs[0]) != 1)
        mexErrMsgTxt("LJTemperatureProbe: First argument must be an operation string.");
	else
		mxGetString(prhs[0], operandName, sizeof(operandName));
    
    if (strcmp(operandName, "identify")==0) {
        *status = amUE3device();
    }
    else if (strcmp(operandName, "open")==0) {
        *status = openUE3device();
    }
    else if (strcmp(operandName, "close")==0) {
        *status = closeUE3device();
    }
    else if (strcmp(operandName, "measure")==0) {
        
        /* Create matrix for second output (uncorrected Ydata) */
        int mrows, ncols;
        mrows = 1; ncols = 2;
        plhs[1] = mxCreateDoubleMatrix(mrows,ncols, mxREAL);
                
        /* Create a C pointer to a copy of the tempData  */
        double *tempData;
        tempData = mxGetPr(plhs[1]);
                
        readTemperature(tempData);
        
        *status = 0; 
    }
    else  {
        printf("Unknown command name, %s", operandName);
    }
}

int amUE3device()
{
    // return 1, if UEdev, 0 otherwise
    return(1);
}

int openUE3device() 
{
    int status;
        
    if ( (hDevice = openUSBConnection(-1)) == NULL) {
        return 0;  // could not open device
    }
    
    //Getting calibration information from U3
    if( getCalibrationInfo(hDevice, &caliInfo) < 0 ) {
        return 0;  // could not get calibration data
    }

    if(configIO_example(hDevice, 1, &isDAC1Enabled) != 0 ) {
        return 0;
    }


    status = feedback_setup_example();
    if (status!=0) {
        return 0;
    }
    else {
        return 1;
    }
}

int closeUE3device() 
{
    if (hDevice != NULL) {
        closeUSBConnection(hDevice);
        hDevice = NULL;
    }
    else {
        //mexPrintf("U3 device was not open.\n");
    }
    return(1); 
}



//
//Sends a ConfigIO low-level command that configures the FIOs, DAC, Timers and
//Counters for this example.
//
int configIO_example(HANDLE hDevice, int enable, int *isDAC1Enabled)
{
    uint8 sendBuff[12], recBuff[12];
    uint8 timerCounterConfig, fioAnalog;
    uint16 checksumTotal;
    int sendChars, recChars;

    if( enable == 0 )
    {
        timerCounterConfig = 64;  //Disabling timers (bits 0 and 1) and Counters
                                  //(bits 2 and 3), setting TimerCounterPinOffset
                                  //to 4 (bits 4-7)
        fioAnalog = 255;  //Setting all FIOs to analog
    }
    else
    {
        timerCounterConfig = 74;  //Enabling 2 timers (bits 0 and 1), Counter 1 (bit 3)
                                  //and setting TimerCounterPinOffset (bits 4-7) to
                                  //4.  Note that Counter 0 will not be available
                                  //since the timer clock will use a divisor in this
                                  //example.  Also, for hardware version 1.30, HV
                                  //models need to have a TimerCounterPinOffset of 4-8,
                                  //otherwise an error will occur since FIO0-FIO3 can only
                                  //be analog inputs.

        fioAnalog = 3;  //Setting FIO0 (bit 0) and FIO1 (bit 1) to analog input.  Note that
                        //hardware version 1.30, U3-HV models will always have FIO0-4 set as
                        //analog inputs, and will ignore setting chages.  In this case, FIO2
                        //and FIO3 will ignore the the digital setting and still be analog
                        //inputs.
    }

    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = (uint8)(0x03);  //Number of data words
    sendBuff[3] = (uint8)(0x0B);  //Extended command number

    sendBuff[6] = 5;  //Writemask : Setting writemask for timerCounterConfig (bit 0)
                      //and FIOAnalog (bit 2)

    sendBuff[7] = 0;  //Reserved
    sendBuff[8] = timerCounterConfig;  //TimerCounterConfig
    sendBuff[9] = 0;  //DAC1 enable : not enabling, though could already be enabled.
                      //If U3 hardware version 1.30, DAC1 is always enabled.
    sendBuff[10] = fioAnalog;  //FIOAnalog
    sendBuff[11] = 0;  //EIOAnalog : Not setting anything
    extendedChecksum(sendBuff, 12);

    //Sending command to U3
    if( (sendChars = LJUSB_Write(hDevice, sendBuff, 12)) < 12 )
    {
        if( sendChars == 0 )
            printf("ConfigIO error : write failed\n");
        else
            printf("ConfigIO error : did not write all of the buffer\n");
        return -1;
    }

    //Reading response from U3
    if( (recChars = LJUSB_Read(hDevice, recBuff, 12)) < 12 )
    {
        if( recChars == 0 )
            printf("ConfigIO error : read failed\n");
        else
            printf("ConfigIO error : did not read all of the buffer\n");
        return -1;
    }

    checksumTotal = extendedChecksum16(recBuff, 12);
    if( (uint8)((checksumTotal / 256 ) & 0xFF) != recBuff[5] )
    {
        printf("ConfigIO error : read buffer has bad checksum16(MSB)\n");
        return -1;
    }

    if( (uint8)(checksumTotal & 0xFF) != recBuff[4] )
    {
        printf("ConfigIO error : read buffer has bad checksum16(LBS)\n");
        return -1;
    }

    if( extendedChecksum8(recBuff) != recBuff[0] )
    {
        printf("ConfigIO error : read buffer has bad checksum8\n");
        return -1;
    }

    if( recBuff[1] != (uint8)(0xF8) || recBuff[2] != (uint8)(0x03) || recBuff[3] != (uint8)(0x0B) )
    {
        printf("ConfigIO error : read buffer has wrong command bytes\n");
        return -1;
    }

    if( recBuff[6] != 0 )
    {
        printf("ConfigIO error : read buffer received errorcode %d\n", recBuff[6]);
        return -1;
    }

    if( recBuff[8] != timerCounterConfig )
    {
        printf("ConfigIO error : TimerCounterConfig did not get set correctly\n");
        return -1;
    }

    if( recBuff[10] != fioAnalog && recBuff[10] != (fioAnalog|(0x0F)) )
    {
        printf("ConfigIO error : FIOAnalog(%d) did not set correctly\n", recBuff[10]);
        return -1;
    }

    *isDAC1Enabled = (int)recBuff[9];

    return 0;
}

//Sends a Feedback low-level command that configures digital directions, states,
//timer modes and DAC0 for this example.  Will work with U3 hardware versions
//1.20, 1.21 and 1.30 LV.
int feedback_setup_example()
{
    uint8 sendBuff[32], recBuff[18];
    uint16 checksumTotal;
    int sendChars, recChars;

    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = 13;  //Number of data words (.5 word for echo, 8 words for
                       //IOTypes and data, and .5 words for the extra byte)
    sendBuff[3] = (uint8)(0x00);  //Extended command number

    sendBuff[6] = 0;  //Echo

    sendBuff[7] = 13;  //IOType is BitDirWrite
    sendBuff[8] = 130;  //IONumber (bits 0 - 4) is 2 and Direction (bit 7) is
                        //output

    sendBuff[9] = 13;  //IOType is BitDirWrite
    sendBuff[10] = 3;  //IONumber (bits 0 - 4) is 3 and Direction (bit 7) is
                       //input

    sendBuff[11] = 11;  //IOType is BitStateWrite
    sendBuff[12] = 2;  //IONumber (bits 0 - 4) is 2 and State (bit 7) is low

    sendBuff[13] = 43;  //IOType is Timer0Config
    sendBuff[14] = 0;  //TimerMode is 16 bit PWM output (mode 0)
    sendBuff[15] = 0;  //Value LSB
    sendBuff[16] = 0;  //Value MSB, Whole value is 32768

    sendBuff[17] = 42;  //IOType is Timer0
    sendBuff[18] = 1;  //UpdateReset
    sendBuff[19] = 0;  //Value LSB
    sendBuff[20] = 128;  //Value MSB, Whole Value is 32768

    sendBuff[21] = 45;  //IOType is Timer1Config
    sendBuff[22] = 1;  //TimerMode is 8 bit PWM output (mode 1)
    sendBuff[23] = 0;  //Value LSB
    sendBuff[24] = 0;  //Value MSB, Whole value is 32768

    sendBuff[25] = 44;  //IOType is Timer1
    sendBuff[26] = 1;  //UpdateReset
    sendBuff[27] = 0;  //Value LSB
    sendBuff[28] = 128;  //Value MSB, Whole Value is 32768

    sendBuff[29] = 34;  //IOType is DAC0 (8-bit)

    //Value is 1.5 volts (in binary form)
    getDacBinVoltCalibrated8Bit(&caliInfo, 0, 1.5, &sendBuff[30]);
    sendBuff[31] = 0;  //Extra byte

    extendedChecksum(sendBuff, 32);

    //Sending command to U3
    if( (sendChars = LJUSB_Write(hDevice, sendBuff, 32)) < 32 )
    {
        if( sendChars == 0 )
            printf("Feedback setup error : write failed\n");
        else
            printf("Feedback setup error : did not write all of the buffer\n");
        return -1;
    }

    //Reading response from U3
    if( (recChars = LJUSB_Read(hDevice, recBuff, 18)) < 18 )
    {
        if( recChars == 0 )
        {
            printf("Feedback setup error : read failed\n");
            return -1;
        }
        else
            printf("Feedback setup error : did not read all of the buffer\n");
    }

    checksumTotal = extendedChecksum16(recBuff, 18);
    if( (uint8)((checksumTotal / 256 ) & 0xFF) != recBuff[5] )
    {
        printf("Feedback setup error : read buffer has bad checksum16(MSB)\n");
        return -1;
    }

    if( (uint8)(checksumTotal & 0xFF) != recBuff[4] )
    {
        printf("Feedback setup error : read buffer has bad checksum16(LBS)\n");
        return -1;
    }

    if( extendedChecksum8(recBuff) != recBuff[0] )
    {
        printf("Feedback setup error : read buffer has bad checksum8\n");
        return -1;
    }

    if( recBuff[1] != (uint8)(0xF8) || recBuff[2] != 6 || recBuff[3] != (uint8)(0x00) )
    {
        printf("Feedback setup error : read buffer has wrong command bytes \n");
        return -1;
    }

    if( recBuff[6] != 0 )
    {
        printf("Feedback setup error : received errorcode %d for frame %d in Feedback response. \n", recBuff[6], recBuff[7]);
        return -1;
    }

    return 0;
}




//Calls a Feedback low-level call to read AIN0, AIN1, FIO3, Counter1(FIO6) and
//temperature.  Will work with U3 hardware versions 1.20, 1.21 and 1.30 LV.
double readTemperature(double *tempData)
{
    uint8 sendBuff[32], recBuff[28];
    uint16 checksumTotal;
    int sendChars, recChars;
 
    double  voltageT,    // Voltage to store the temperature for the Temp Sensor */ 
            temperature; // Internal sensor Temperature


    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = 13;  //Number of data words (.5 word for echo, 12.5 words for
                       //IOTypes)
    sendBuff[3] = (uint8)(0x00);  //Extended command number

    sendBuff[6] = 0;  //Echo

    sendBuff[7] = 1;  //IOType is AIN
    sendBuff[8] = 0;  //Positive channel (bits 0-4) is 0, LongSettling (bit 6)
                      //is not set and QuickSample (bit 7) is not set
    sendBuff[9] = 31;  //Negative channel is 31 (SE)

    sendBuff[10] = 1;  //IOType is AIN
    sendBuff[11] = 1;  //Positive channel (bits 0-4) is 1, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[12] = 31;  //Negative channel is 31 (SE)

    sendBuff[13] = 1;  //IOType is AIN
    sendBuff[14] = 0;  //Positive channel (bits 0-4) is 0, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[15] = 1;  //Negative channel is 1 (FIO1)

    sendBuff[16] = 1;  //IOType is AIN
    sendBuff[17] = 1;  //Positive channel (bits 0-4) is 1, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[18] = 0;  //Negative channel is 0 (FIO0)

    sendBuff[19] = 1;  //IOType is AIN
    sendBuff[20] = 0;  //Positive channel (bits 0-4) is 0, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[21] = 30;  //Negative channel is 30 (Vref)

    sendBuff[22] = 1;  //IOType is AIN
    sendBuff[23] = 1;  //Positive channel (bits 0-4) is 1, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[24] = 30;  //Negative channel is 30 (Vref)

    sendBuff[25] = 10;  //IOType is BitStateRead
    sendBuff[26] = 3;  //IO number is 3 (FIO3)

    sendBuff[27] = 55;  //IOType is Counter1
    sendBuff[28] = 0;  //Reset (bit 0) is not set

    sendBuff[29] = 1;  //IOType is AIN
    sendBuff[30] = 30;  //Positive channel is 30 (temp sensor)
    sendBuff[31] = 31;  //Negative channel is 31 (SE)

    extendedChecksum(sendBuff, 32);


        printf("Measuring temp\n");

        //Sending command to U3
        if( (sendChars = LJUSB_Write(hDevice,  sendBuff, 32)) < 32 )
        {
            if( sendChars == 0 )
              printf("Feedback loop error : write failed\n");
            else
              printf("Feedback loop error : did not write all of the buffer\n");
            return -1;
        }

        //Reading response from U3
        if( (recChars = LJUSB_Read(hDevice, recBuff, 28)) < 28 )
        {
            if( recChars == 0 )
            {
                printf("Feedback loop error : read failed\n");
                return -1;
            }
            else
                printf("Feedback loop error : did not read all of the expected buffer\n");
        }

        if( recChars < 10 )
        {
            printf("Feedback loop error : response is not large enough\n");
            return -1;
        }

        checksumTotal = extendedChecksum16(recBuff, recChars);
        if( (uint8)((checksumTotal / 256 ) & 0xFF) != recBuff[5] )
        {
            printf("Feedback loop error : read buffer has bad checksum16(MSB)\n");
            return -1;
        }

        if( (uint8)(checksumTotal & 0xFF) != recBuff[4] )
        {
            printf("Feedback loop error : read buffer has bad checksum16(LBS)\n");
            return -1;
        }

        if( extendedChecksum8(recBuff) != recBuff[0] )
        {
            printf("Feedback loop error : read buffer has bad checksum8\n");
            return -1;
        }

        if( recBuff[1] != (uint8)(0xF8) ||  recBuff[3] != (uint8)(0x00) )
        {
            printf("Feedback loop error : read buffer has wrong command bytes \n");
            return -1;
        }

        if( recBuff[6] != 0 )
        {
            printf("Feedback loop error : received errorcode %d for frame %d ", recBuff[6], recBuff[7]); 
            switch( recBuff[7] )
            {
                case 1: printf("(AIN(SE))\n"); break;
                case 2: printf("(AIN(SE))\n"); break;
                case 3: printf("(AIN(Neg. chan. 1))\n"); break;
                case 4: printf("(AIN(Neg. chan. 0))\n"); break;
                case 5: printf("(AIN(Neg. chan. Vref))\n"); break;
                case 6: printf("(AIN(Neg. chan. Vref))\n"); break;
                case 7: printf("(BitStateRead for FIO3)\n"); break;
                case 8: printf("(Counter1)\n"); break;
                case 9: printf("(Temp. Sensor\n"); break;
                default: printf("(Unknown)\n"); break;
            }
            return -1;
        }
        // Use FIO0 as the analog input to connect the EI-1034 Temp Sensor
        getAinVoltCalibrated(&caliInfo, isDAC1Enabled, 31, recBuff[9] + recBuff[10]*256, &voltageT);

        //printf("AIN0(SE) : %.3f volts\n", voltageT); 

        // This is the Internal Sensor Temperature in Kelvin
        getTempKCalibrated(&caliInfo, recBuff[26] + recBuff[27]*256, &temperature);
        
        //printf("Temperature : %.3f K\n", temperature);

        // Get the voltage value and convert this to Farenheit degrees 
        // Per manual, Volts * 100 = Farenheit degrees
        // printf("Temperature Sensor: %.2f Farenheit\n", (voltageT*100));
        // printf("Temperature Sensor (K): %.2f Kelvin\n\n\n\n", ((55.56*voltageT) + 255.37));
        
        tempData[0] = ((1.8)*(temperature-273))+32.0; /* convert K to F */
        tempData[1] = voltageT*100;
 
        printf("Temperature Int Sensor : %.2f Farenheit\n", tempData[0]);        
        printf("Temperature Ext Sensor : %.2f Farenheit\n", tempData[1]);

        int status;
        status = 0;
        return(status);
}


//Calls a Feedback low-level call to read AIN0, AIN1, FIO3, Counter1(FIO6) and
//temperature.  Will work with U3 hardware versions 1.20, 1.21 and 1.30 LV.
int feedback_loop_example()
{
    uint8 sendBuff[32], recBuff[28];
    uint16 checksumTotal;
    int sendChars, recChars;
    long count;
    double  voltageT,    // Voltage to store the temperature for the Temp Sensor */ 
            temperature, // Internal sensor Temperature
            TempData[2]; // both internal and external temperature array

    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = 13;  //Number of data words (.5 word for echo, 12.5 words for
                       //IOTypes)
    sendBuff[3] = (uint8)(0x00);  //Extended command number

    sendBuff[6] = 0;  //Echo

    sendBuff[7] = 1;  //IOType is AIN
    sendBuff[8] = 0;  //Positive channel (bits 0-4) is 0, LongSettling (bit 6)
                      //is not set and QuickSample (bit 7) is not set
    sendBuff[9] = 31;  //Negative channel is 31 (SE)

    sendBuff[10] = 1;  //IOType is AIN
    sendBuff[11] = 1;  //Positive channel (bits 0-4) is 1, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[12] = 31;  //Negative channel is 31 (SE)

    sendBuff[13] = 1;  //IOType is AIN
    sendBuff[14] = 0;  //Positive channel (bits 0-4) is 0, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[15] = 1;  //Negative channel is 1 (FIO1)

    sendBuff[16] = 1;  //IOType is AIN
    sendBuff[17] = 1;  //Positive channel (bits 0-4) is 1, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[18] = 0;  //Negative channel is 0 (FIO0)

    sendBuff[19] = 1;  //IOType is AIN
    sendBuff[20] = 0;  //Positive channel (bits 0-4) is 0, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[21] = 30;  //Negative channel is 30 (Vref)

    sendBuff[22] = 1;  //IOType is AIN
    sendBuff[23] = 1;  //Positive channel (bits 0-4) is 1, LongSettling (bit 6)
                       //is not set and QuickSample (bit 7) is not set
    sendBuff[24] = 30;  //Negative channel is 30 (Vref)

    sendBuff[25] = 10;  //IOType is BitStateRead
    sendBuff[26] = 3;  //IO number is 3 (FIO3)

    sendBuff[27] = 55;  //IOType is Counter1
    sendBuff[28] = 0;  //Reset (bit 0) is not set

    sendBuff[29] = 1;  //IOType is AIN
    sendBuff[30] = 30;  //Positive channel is 30 (temp sensor)
    sendBuff[31] = 31;  //Negative channel is 31 (SE)

    extendedChecksum(sendBuff, 32);



        //Sending command to U3
        if( (sendChars = LJUSB_Write(hDevice,  sendBuff, 32)) < 32 )
        {
            if( sendChars == 0 )
              printf("Feedback loop error : write failed\n");
            else
              printf("Feedback loop error : did not write all of the buffer\n");
            return -1;
        }

        //Reading response from U3
        if( (recChars = LJUSB_Read(hDevice, recBuff, 28)) < 28 )
        {
            if( recChars == 0 )
            {
                printf("Feedback loop error : read failed\n");
                return -1;
            }
            else
                printf("Feedback loop error : did not read all of the expected buffer\n");
        }

        if( recChars < 10 )
        {
            printf("Feedback loop error : response is not large enough\n");
            return -1;
        }

        checksumTotal = extendedChecksum16(recBuff, recChars);
        if( (uint8)((checksumTotal / 256 ) & 0xFF) != recBuff[5] )
        {
            printf("Feedback loop error : read buffer has bad checksum16(MSB)\n");
            return -1;
        }

        if( (uint8)(checksumTotal & 0xFF) != recBuff[4] )
        {
            printf("Feedback loop error : read buffer has bad checksum16(LBS)\n");
            return -1;
        }

        if( extendedChecksum8(recBuff) != recBuff[0] )
        {
            printf("Feedback loop error : read buffer has bad checksum8\n");
            return -1;
        }

        if( recBuff[1] != (uint8)(0xF8) ||	recBuff[3] != (uint8)(0x00) )
        {
            printf("Feedback loop error : read buffer has wrong command bytes \n");
            return -1;
        }

        if( recBuff[6] != 0 )
        {
            printf("Feedback loop error : received errorcode %d for frame %d ", recBuff[6], recBuff[7]); 
            switch( recBuff[7] )
            {
                case 1: printf("(AIN(SE))\n"); break;
                case 2: printf("(AIN(SE))\n"); break;
                case 3: printf("(AIN(Neg. chan. 1))\n"); break;
                case 4: printf("(AIN(Neg. chan. 0))\n"); break;
                case 5: printf("(AIN(Neg. chan. Vref))\n"); break;
                case 6: printf("(AIN(Neg. chan. Vref))\n"); break;
                case 7: printf("(BitStateRead for FIO3)\n"); break;
                case 8: printf("(Counter1)\n"); break;
                case 9: printf("(Temp. Sensor\n"); break;
                default: printf("(Unknown)\n"); break;
            }
            return -1;
        }
        // Use FIO0 as the analog input to connect the EI-1034 Temp Sensor
        getAinVoltCalibrated(&caliInfo, isDAC1Enabled, 31, recBuff[9] + recBuff[10]*256, &voltageT);

        //printf("AIN0(SE) : %.3f volts\n", voltageT); 

        // This is the Internal Sensor Temperature in Kelvin
        getTempKCalibrated(&caliInfo, recBuff[26] + recBuff[27]*256, &temperature);
        
        //printf("Temperature : %.3f K\n", temperature);

        // Get the voltage value and convert this to Farenheit degrees 
        // Per manual, Volts * 100 = Farenheit degrees
        // printf("Temperature Sensor: %.2f Farenheit\n", (voltageT*100));
        // printf("Temperature Sensor (K): %.2f Kelvin\n\n\n\n", ((55.56*voltageT) + 255.37));
        
        TempData[0] = ((1.8)*(temperature-273))+32.0; /* convert K to F */
        TempData[1] = voltageT*100;
        printf("Temperature Int Sensor : %.2f Farenheit\n", TempData[0]);        
        printf("Temperature Ext Sensor : %.2f Farenheit\n", TempData[1]);

    return 0;
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


void normalChecksum(uint8 *b, int n)
{
    b[0] = normalChecksum8(b, n);
}


void extendedChecksum(uint8 *b, int n)
{
    uint16 a;

    a = extendedChecksum16(b, n);
    b[4] = (uint8)(a & 0xFF);
    b[5] = (uint8)((a/256) & 0xFF);
    b[0] = extendedChecksum8(b);
}


uint8 normalChecksum8(uint8 *b, int n)
{
    int i;
    uint16 a, bb;

    //Sums bytes 1 to n-1 unsigned to a 2 byte value. Sums quotient and
    //remainder of 256 division.  Again, sums quotient and remainder of
    //256 division.
    for( i = 1, a = 0; i < n; i++ )
        a += (uint16)b[i];

    bb = a / 256;
    a = (a - 256*bb) + bb;
    bb = a / 256;

    return (uint8)((a - 256*bb) + bb);
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


long getTickCount()
{
    struct timeval tv;

    gettimeofday(&tv, NULL);

    return (tv.tv_sec * 1000) + (tv.tv_usec / 1000);
}


long isCalibrationInfoValid(u3CalibrationInfo *caliInfo)
{
    if( caliInfo == NULL )
        goto invalid;
    if( caliInfo->prodID != 3 )
        goto invalid;
    return 1;
invalid:
    printf("Error: Invalid calibration info.\n");
    return 0;
}


long isTdacCalibrationInfoValid(u3TdacCalibrationInfo *caliInfo)
{
    if( caliInfo == NULL )
        goto invalid;
    if( caliInfo->prodID != 3 )
        goto invalid;
    return 1;
invalid:
    printf("Error: Invalid LJTDAC calibration info.\n");
    return 0;
}


long getCalibrationInfo(HANDLE hDevice, u3CalibrationInfo *caliInfo)
{
    uint8 sendBuffer[8], recBuffer[40];
    uint8 cU3SendBuffer[26], cU3RecBuffer[38];
    int sentRec = 0, offset = 0, i = 0;

    /* Sending ConfigU3 command to get hardware version and see if HV */
    cU3SendBuffer[1] = (uint8)(0xF8);  //Command byte
    cU3SendBuffer[2] = (uint8)(0x0A);  //Number of data words
    cU3SendBuffer[3] = (uint8)(0x08);  //Extended command number

    //Setting WriteMask0 and all other bytes to 0 since we only want to read the
    //response
    for( i = 6; i < 26; i++ )
        cU3SendBuffer[i] = 0;

    extendedChecksum(cU3SendBuffer, 26);

    sentRec = LJUSB_Write(hDevice, cU3SendBuffer, 26);
    if( sentRec < 26 )
    {
        if( sentRec == 0 )
            goto writeError0;
        else
            goto writeError1;
    }

    sentRec = LJUSB_Read(hDevice, cU3RecBuffer, 38);
    if( sentRec < 38 )
    {
        if( sentRec == 0 )
            goto readError0;
        else
            goto readError1;
    }

    if( cU3RecBuffer[1] != (uint8)(0xF8) || cU3RecBuffer[2] != (uint8)(0x10) ||
        cU3RecBuffer[3] != (uint8)(0x08))
        goto commandByteError;

    caliInfo->hardwareVersion = cU3RecBuffer[14] + cU3RecBuffer[13]/100.0;
    if( (cU3RecBuffer[37] & 18) == 18 )
        caliInfo->highVoltage = 1;
    else
        caliInfo->highVoltage = 0;

    for( i = 0; i < 5; i++ )
    {
        /* Reading block i from memory */
        sendBuffer[1] = (uint8)(0xF8);  //Command byte
        sendBuffer[2] = (uint8)(0x01);  //Cumber of data words
        sendBuffer[3] = (uint8)(0x2D);  //Extended command number
        sendBuffer[6] = 0;
        sendBuffer[7] = (uint8)i;  //Blocknum = i
        extendedChecksum(sendBuffer, 8);

        sentRec = LJUSB_Write(hDevice, sendBuffer, 8);
        if( sentRec < 8 )
        {
            if( sentRec == 0 )
                goto writeError0;
            else
                goto writeError1;
        }

        sentRec = LJUSB_Read(hDevice, recBuffer, 40);
        if( sentRec < 40 )
        {
            if( sentRec == 0 )
                goto readError0;
            else
                goto readError1;
        }

        if( recBuffer[1] != (uint8)(0xF8) || recBuffer[2] != (uint8)(0x11) ||
            recBuffer[3] != (uint8)(0x2D) )
            goto commandByteError;

        offset = i * 4;

        //Block data starts on byte 8 of the buffer
        caliInfo->ccConstants[offset] = FPuint8ArrayToFPDouble(recBuffer + 8, 0);
        caliInfo->ccConstants[offset + 1] = FPuint8ArrayToFPDouble(recBuffer + 8, 8);
        caliInfo->ccConstants[offset + 2] = FPuint8ArrayToFPDouble(recBuffer + 8, 16);
        caliInfo->ccConstants[offset + 3] = FPuint8ArrayToFPDouble(recBuffer + 8, 24);
    }

    caliInfo->prodID = 3;

    return 0;

writeError0:
    printf("Error : getCalibrationInfo write failed\n");
    return -1;
writeError1:
    printf("Error : getCalibrationInfo did not write all of the buffer\n");
    return -1;
readError0:
    printf("Error : getCalibrationInfo read failed\n");
    return -1;
readError1:
    printf("Error : getCalibrationInfo did not read all of the buffer\n");
    return -1;
commandByteError:
    printf("Error : getCalibrationInfo received wrong command bytes for ReadMem\n");
    return -1;
}


long getTdacCalibrationInfo( HANDLE hDevice, u3TdacCalibrationInfo *caliInfo, uint8 DIOAPinNum)
{
    int err;
    uint8 options, speedAdjust, sdaPinNum, sclPinNum;
    uint8 address, numByteToSend, numBytesToRec, errorcode;
    uint8 bytesComm[1], bytesResp[32];
    uint8 ackArray[4];

    err = 0;

    //Setting up I2C command for LJTDAC
    options = 0;  //I2COptions : 0
    speedAdjust = 0;  //SpeedAdjust : 0 (for max communication speed of about
                      //130 kHz)
    sdaPinNum = DIOAPinNum+1;  //SDAPinNum : FIO channel connected to pin DIOB
    sclPinNum = DIOAPinNum;  //SCLPinNum : FIO channel connected to pin DIOA
    address = (uint8)(0xA0);  //Address : h0xA0 is the address for EEPROM
    numByteToSend = 1;  //NumI2CByteToSend : 1 byte for the EEPROM address
    numBytesToRec = 32;  //NumI2CBytesToReceive : getting 32 bytes starting at
                         //EEPROM address specified in I2CByte0

    bytesComm[0] = 64;  //I2CByte0 : Memory Address (starting at address 64,
                        //                           DACA Slope)

    //Performing I2C low-level call
    err = I2C(hDevice, options, speedAdjust, sdaPinNum,
              sclPinNum, address, numByteToSend, numBytesToRec, 
              bytesComm, &errorcode, ackArray, bytesResp);

    if( errorcode != 0 )
    {
        printf("Getting LJTDAC calibration info error : received errorcode %d in response\n", errorcode);
        err = -1;
    }

    if( err == -1 )
        return err;

    caliInfo->ccConstants[0] = FPuint8ArrayToFPDouble(bytesResp, 0);
    caliInfo->ccConstants[1] = FPuint8ArrayToFPDouble(bytesResp, 8);
    caliInfo->ccConstants[2] = FPuint8ArrayToFPDouble(bytesResp, 16);
    caliInfo->ccConstants[3] = FPuint8ArrayToFPDouble(bytesResp, 24);
    caliInfo->prodID = 3;

    return err;
}


double FPuint8ArrayToFPDouble(uint8 *buffer, int startIndex)
{
    uint32 resultDec = 0, resultWh = 0;

    resultDec = (uint32)buffer[startIndex] |
                ((uint32)buffer[startIndex + 1] << 8) |
                ((uint32)buffer[startIndex + 2] << 16) |
                ((uint32)buffer[startIndex + 3] << 24);

    resultWh = (uint32)buffer[startIndex + 4] |
                ((uint32)buffer[startIndex + 5] << 8) |
                ((uint32)buffer[startIndex + 6] << 16) |
                ((uint32)buffer[startIndex + 7] << 24);

    return ( (double)((int)resultWh) + (double)(resultDec)/4294967296.0 );
}


long getAinVoltCalibrated(u3CalibrationInfo *caliInfo, int dacEnabled, uint8 negChannel, uint16 bytesVolt, double *analogVolt)
{
    if( isCalibrationInfoValid(caliInfo) == 0 )
        return -1;

    if( caliInfo->hardwareVersion >= 1.30 )
    {
        if( caliInfo->highVoltage == 1 )
        {
            printf("getAinVoltCalibrated error: cannot handle U3-HV device.  Please use getAinVoltCalibrated_hw130 function.\n");
            return -1;
        }
        else
            return getAinVoltCalibrated_hw130(caliInfo, 0, negChannel, bytesVolt, analogVolt);
    }

    if( negChannel <= 15 || negChannel == 30 )
    {
        if( dacEnabled == 0 )
            *analogVolt = caliInfo->ccConstants[2]*((double)bytesVolt) + caliInfo->ccConstants[3];
        else
            *analogVolt = (bytesVolt/65536.0)*caliInfo->ccConstants[11]*2.0 - caliInfo->ccConstants[11];
    }
    else if( negChannel == 31 )
    {
        if( dacEnabled == 0 )
            *analogVolt = caliInfo->ccConstants[0]*((double)bytesVolt) + caliInfo->ccConstants[1];
        else
            *analogVolt = (bytesVolt/65536.0)*caliInfo->ccConstants[11];
    }
    else
    {
        printf("getAinVoltCalibrated error: invalid negative channel.\n");
        return -1;
    }

    return 0;
}


long getAinVoltCalibrated_hw130(u3CalibrationInfo *caliInfo, uint8 positiveChannel, uint8 negChannel, uint16 bytesVolt, double *analogVolt)
{
    if( isCalibrationInfoValid(caliInfo) == 0 )
        return -1;

    if( caliInfo->hardwareVersion < 1.30 )
    {
        printf("getAinVoltCalibrated_hw130 error: cannot handle U3 hardware versions < 1.30 .  Please use getAinVoltCalibrated function.\n");
        return -1;
    }

    if( negChannel <= 15 || negChannel == 30 )
    {
        if( caliInfo->highVoltage == 0
            || (caliInfo->highVoltage == 1 && positiveChannel >= 4 && negChannel >= 4) )
        {
            *analogVolt = caliInfo->ccConstants[2]*((double)bytesVolt) + caliInfo->ccConstants[3];
        }
        else if( caliInfo->hardwareVersion >= 1.30 && caliInfo->highVoltage == 1 )
        {
            printf("getAinVoltCalibrated_hw130 error: invalid negative channel for U3-HV.\n");
            return -1;
        }
    }
    else if( negChannel == 31 )
    {
        if( caliInfo->highVoltage == 1 && positiveChannel < 4 )
            *analogVolt = caliInfo->ccConstants[12+positiveChannel]*((double)bytesVolt) + caliInfo->ccConstants[16+positiveChannel];
        else
            *analogVolt = caliInfo->ccConstants[0]*((double)bytesVolt) + caliInfo->ccConstants[1];
    }
    else if( negChannel == 32 )  //Special range (binary value should be from a
                                 //diff. AIN reading with negative channel 30)
    {
        if( caliInfo->highVoltage == 1 && positiveChannel < 4 )
        {
            *analogVolt = (caliInfo->ccConstants[2]*((double)bytesVolt) + caliInfo->ccConstants[3] + caliInfo->ccConstants[9]) * caliInfo->ccConstants[12 + positiveChannel] / caliInfo->ccConstants[0] +
                           caliInfo->ccConstants[16 + positiveChannel];
        }
        else
        {
            *analogVolt = caliInfo->ccConstants[2]*((double)bytesVolt) + caliInfo->ccConstants[3] + caliInfo->ccConstants[9];
        }
    }
    else
    {
        printf("getAinVoltCalibrated_hw130 error: invalid negative channel.\n");
        return -1;
    }

    return 0;
}


long getDacBinVoltCalibrated(u3CalibrationInfo *caliInfo, int dacNumber, double analogVolt, uint8 *bytesVolt)
{
    return getDacBinVoltCalibrated8Bit(caliInfo, dacNumber, analogVolt, bytesVolt);
}


long getDacBinVoltCalibrated8Bit(u3CalibrationInfo *caliInfo, int dacNumber, double analogVolt, uint8 *bytesVolt8)
{
    double tBytesVolt;

    if( isCalibrationInfoValid(caliInfo) == 0 )
        return -1;

    if( dacNumber < 0 || dacNumber > 2 )
    {
        printf("getDacBinVoltCalibrated8Bit error: invalid channelNumber.\n");
        return -1;
    }
    tBytesVolt = analogVolt*caliInfo->ccConstants[4 + dacNumber*2] +   caliInfo->ccConstants[5 + dacNumber*2];

    //Checking to make sure bytesVolt will be a value between 0 and 255.  Too
    //high of an analogVoltage (about 4.95 and above volts) or too low (below 0
    //volts) will cause a value not between 0 and 255.
    if( tBytesVolt < 0 )
        tBytesVolt = 0;
    else if( tBytesVolt > 255 && caliInfo->hardwareVersion < 1.30 )
        tBytesVolt = 255;

    *bytesVolt8 = (uint8)tBytesVolt;

    return 0;
}


long getDacBinVoltCalibrated16Bit(u3CalibrationInfo *caliInfo, int dacNumber, double analogVolt, uint16 *bytesVolt16)
{
    double tBytesVolt;

    if( isCalibrationInfoValid(caliInfo) == 0 )
        return -1;

    if( dacNumber < 0 || dacNumber > 2 )
    {
        printf("getDacBinVoltCalibrated16Bit error: invalid channelNumber.\n");
        return -1;
    }

    if( caliInfo->hardwareVersion < 1.30 )
        tBytesVolt = analogVolt*caliInfo->ccConstants[4 + dacNumber*2] +   caliInfo->ccConstants[5 + dacNumber*2];
    else
        tBytesVolt = analogVolt*caliInfo->ccConstants[4 + dacNumber*2]*256 +   caliInfo->ccConstants[5 + dacNumber*2]*256;

    //Checking to make sure bytesVolt will be a value between 0 and 255/65535.
    //Too high of an analogVoltage (about 4.95 and above volts) or too low
    //(below 0 volts) will cause a value not between 0 and 255/65535.
    if( tBytesVolt < 0 )
        tBytesVolt = 0;
    if( tBytesVolt > 65535 && caliInfo->hardwareVersion >= 1.30 )
        tBytesVolt = 65535;
    else if( tBytesVolt > 255 && caliInfo->hardwareVersion < 1.30 )
        tBytesVolt = 255;

    *bytesVolt16 = (uint16)tBytesVolt;

    return 0;
}


long getTdacBinVoltCalibrated(u3TdacCalibrationInfo *caliInfo, int dacNumber, double analogVolt, uint16 *bytesVolt)
{
    uint32 tBytesVolt;

    if( isTdacCalibrationInfoValid(caliInfo) == 0 )
        return -1;

    if( dacNumber < 0 || dacNumber > 2 )
    {
        printf("getTdacBinVoltCalibrated error: invalid channelNumber.\n");
        return -1;
    }

    tBytesVolt = analogVolt*caliInfo->ccConstants[dacNumber*2] + caliInfo->ccConstants[dacNumber*2 + 1];

    //Checking to make sure bytesVolt will be a value between 0 and 65535.
    if( tBytesVolt > 65535 )
        tBytesVolt = 65535;

    *bytesVolt = (uint16)tBytesVolt;

    return 0;
}

long getTempKCalibrated(u3CalibrationInfo *caliInfo, uint32 bytesTemp, double *kelvinTemp)
{
    if( isCalibrationInfoValid(caliInfo) == 0 )
        return -1;

    *kelvinTemp = caliInfo->ccConstants[8]*((double)bytesTemp);
    return 0;
}


long getAinVoltUncalibrated(int dacEnabled, uint8 negChannel, uint16 bytesVolt, double *analogVolt)
{
    U3_CALIBRATION_INFO_DEFAULT.hardwareVersion = 1.20;
    U3_CALIBRATION_INFO_DEFAULT.highVoltage = 0;
    return getAinVoltCalibrated(&U3_CALIBRATION_INFO_DEFAULT, dacEnabled, negChannel, bytesVolt, analogVolt);
}


long getAinVoltUncalibrated_hw130(int highVoltage, uint8 positiveChannel, uint8 negChannel, uint16 bytesVolt, double *analogVolt)
{
    U3_CALIBRATION_INFO_DEFAULT.hardwareVersion = 1.30;
    U3_CALIBRATION_INFO_DEFAULT.highVoltage = highVoltage;
    return getAinVoltCalibrated_hw130(&U3_CALIBRATION_INFO_DEFAULT, positiveChannel, negChannel, bytesVolt, analogVolt);
}


long getDacBinVoltUncalibrated(int dacNumber, double analogVolt, uint8 *bytesVolt)
{
    U3_CALIBRATION_INFO_DEFAULT.hardwareVersion = 1.20;
    U3_CALIBRATION_INFO_DEFAULT.highVoltage = 0;
    return getDacBinVoltCalibrated(&U3_CALIBRATION_INFO_DEFAULT, dacNumber, analogVolt, bytesVolt);
}


long getDacBinVoltUncalibrated8Bit(int dacNumber, double analogVolt, uint8 *bytesVolt8)
{
    U3_CALIBRATION_INFO_DEFAULT.hardwareVersion = 1.20;
    U3_CALIBRATION_INFO_DEFAULT.highVoltage = 0;
    return getDacBinVoltCalibrated8Bit(&U3_CALIBRATION_INFO_DEFAULT, dacNumber, analogVolt, bytesVolt8);
}


long getDacBinVoltUncalibrated16Bit(int dacNumber, double analogVolt, uint16 *bytesVolt16)
{
    U3_CALIBRATION_INFO_DEFAULT.hardwareVersion = 1.30;
    U3_CALIBRATION_INFO_DEFAULT.highVoltage = 0;
    return getDacBinVoltCalibrated16Bit(&U3_CALIBRATION_INFO_DEFAULT, dacNumber, analogVolt, bytesVolt16);
}


long getTempKUncalibrated(uint16 bytesTemp, double *kelvinTemp)
{
    U3_CALIBRATION_INFO_DEFAULT.hardwareVersion = 1.20;
    U3_CALIBRATION_INFO_DEFAULT.highVoltage = 0;
    return getTempKCalibrated(&U3_CALIBRATION_INFO_DEFAULT, bytesTemp, kelvinTemp);
}


long I2C(HANDLE hDevice, uint8 I2COptions, uint8 SpeedAdjust, uint8 SDAPinNum, uint8 SCLPinNum, uint8 Address, uint8 NumI2CBytesToSend, uint8 NumI2CBytesToReceive, uint8 *I2CBytesCommand, uint8 *Errorcode, uint8 *AckArray, uint8 *I2CBytesResponse)
{
    uint8 *sendBuff, *recBuff;
    uint16 checksumTotal = 0;
    uint32 ackArrayTotal, expectedAckArray;
    int sendChars, recChars, sendSize, recSize;
    int i, ret;

    *Errorcode = 0;
    ret = 0;
    sendSize = 6 + 8 + ((NumI2CBytesToSend%2 != 0)?(NumI2CBytesToSend + 1):(NumI2CBytesToSend));
    recSize = 6 + 6 + ((NumI2CBytesToReceive%2 != 0)?(NumI2CBytesToReceive + 1):(NumI2CBytesToReceive));

    sendBuff = (uint8 *)malloc(sizeof(uint8)*sendSize);
    recBuff = (uint8 *)malloc(sizeof(uint8)*recSize);

    sendBuff[sendSize - 1] = 0;

    //I2C command
    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = (sendSize - 6) / 2;  //Number of data words = 4 + NumI2CBytesToSend
    sendBuff[3] = (uint8)(0x3B);  //extended command number

    sendBuff[6] = I2COptions;  //I2COptions
    sendBuff[7] = SpeedAdjust;  //SpeedAdjust
    sendBuff[8] = SDAPinNum;  //SDAPinNum
    sendBuff[9] = SCLPinNum;  //SCLPinNum
    sendBuff[10] = Address;  //Address
    sendBuff[11] = 0;  //Reserved
    sendBuff[12] = NumI2CBytesToSend;  //NumI2CByteToSend
    sendBuff[13] = NumI2CBytesToReceive;  //NumI2CBytesToReceive

    for( i = 0; i < NumI2CBytesToSend; i++ )
        sendBuff[14 + i] = I2CBytesCommand[i];  //I2CByte

    extendedChecksum(sendBuff, sendSize);

    //Sending command to U3
    sendChars = LJUSB_Write(hDevice, sendBuff, sendSize);
    if( sendChars < sendSize )
    {
        if( sendChars == 0 )
            printf("I2C Error : write failed\n");
        else
            printf("I2C Error : did not write all of the buffer\n");
        ret = -1;
        goto cleanmem;
    }

    //Reading response from U3
    recChars = LJUSB_Read(hDevice, recBuff, recSize);
    if( recChars < recSize )
    {
        if( recChars == 0 )
            printf("I2C Error : read failed\n");
        else
        {
            printf("I2C Error : did not read all of the buffer\n");
            if( recChars >= 12 )
                *Errorcode = recBuff[6];
        }
        ret = -1;
        goto cleanmem;
    }

    *Errorcode = recBuff[6];

    AckArray[0] = recBuff[8];
    AckArray[1] = recBuff[9];
    AckArray[2] = recBuff[10];
    AckArray[3] = recBuff[11];

    for( i = 0; i < NumI2CBytesToReceive; i++ )
        I2CBytesResponse[i] = recBuff[12 + i];

    if( (uint8)(extendedChecksum8(recBuff)) != recBuff[0] )
    {
        printf("I2C Error : read buffer has bad checksum (%d)\n", recBuff[0]);
        ret = -1;
    }

    if( recBuff[1] != (uint8)(0xF8) )
    {
        printf("I2C Error : read buffer has incorrect command byte (%d)\n", recBuff[1]);
        ret = -1;
    }

    if( recBuff[2] != (uint8)((recSize - 6)/2) )
    {
        printf("I2C Error : read buffer has incorrect number of data words (%d)\n", recBuff[2]);
        ret = -1;
    }

    if( recBuff[3] != (uint8)(0x3B) )
    {
        printf("I2C Error : read buffer has incorrect extended command number (%d)\n", recBuff[3]);
        ret = -1;
    }

    checksumTotal = extendedChecksum16(recBuff, recSize);
    if( (uint8)((checksumTotal / 256) & 0xff) != recBuff[5] || (uint8)(checksumTotal & 255) != recBuff[4])
    {
        printf("I2C error : read buffer has bad checksum16 (%u)\n", checksumTotal);
        ret = -1;
    }

    //ackArray should ack the Address byte in the first ack bit, but did not 
    //until firmware 1.44
    ackArrayTotal = AckArray[0] + AckArray[1]*256 + AckArray[2]*65536 + AckArray[3]*16777216;
    expectedAckArray = pow(2.0,  NumI2CBytesToSend+1)-1;
    if( ackArrayTotal != expectedAckArray )
        printf("I2C error : expected an ack of %u, but received %u\n", expectedAckArray, ackArrayTotal);

cleanmem:
    free(sendBuff);
    free(recBuff);
    sendBuff = NULL;
    recBuff = NULL;

    return ret;
}


long eAIN(HANDLE Handle, u3CalibrationInfo *CalibrationInfo, long ConfigIO, long *DAC1Enable, long ChannelP, long ChannelN, double *Voltage, long Range, long Resolution, long Settling, long Binary, long Reserved1, long Reserved2)
{
    uint8 sendDataBuff[3], recDataBuff[2];
    uint8 FIOAnalog, EIOAnalog, curFIOAnalog, curEIOAnalog;
    uint8 curTCConfig, settling, quicksample, Errorcode;
    uint8 ErrorFrame, outDAC1Enable;
    uint16 bytesVT;
    int hv, isSpecialRange = 0;
    long error;
    double hwver;

    if( isCalibrationInfoValid(CalibrationInfo) == 0 )
    {
        printf("eAIN error: calibration information is required");
        return -1;
    }

    hwver = CalibrationInfo->hardwareVersion;
    hv = CalibrationInfo->highVoltage;

    if( ChannelP < 0 || (ChannelP > 15 && ChannelP != 30 && ChannelP != 31) )
    {
        printf("eAIN error: Invalid positive channel\n");
        return -1;
    }

    if( ChannelN < 0 ||
        (ChannelN > 15 && ChannelN != 30 && ChannelN != 31 && ChannelN != 32) ||
        (hwver >= 1.30 && hv == 1 && ((ChannelP < 4 && ChannelN != 31 && ChannelN != 32) ||
        ChannelN < 4)) )
    {
        printf("eAIN error: Invalid negative channel\n");
        return -1;
    }
    if( ChannelN == 32 )
    {
        isSpecialRange = 1;
        ChannelN = 30;  //Set to 30 for the feedback packet. We'll set it back
                        //to 32 for conversion.
    }

    if( ConfigIO != 0 && !(hwver >= 1.30 && hv == 1 && ChannelP < 4) )
    {
        FIOAnalog = 0;
        EIOAnalog = 0;

        //Setting ChannelP and ChannelN channels to analog using FIOAnalog and
        //EIOAnalog
        if( ChannelP <= 7 )
            FIOAnalog = pow(2, ChannelP);
        else if( ChannelP <= 15 )
            EIOAnalog = pow(2, (ChannelP - 8));

        if( ChannelN <= 7 )
            FIOAnalog = FIOAnalog | (int)pow(2, ChannelN);
        else if( ChannelN <= 15 )
            EIOAnalog = EIOAnalog | (int)pow(2, (ChannelN - 8));

        //Using ConfigIO to get current FIOAnalog and EIOAnalog settings
        if( (error = ehConfigIO(Handle, 0, 0, 0, 0, 0, &curTCConfig, &outDAC1Enable, &curFIOAnalog, &curEIOAnalog)) != 0 )
            return error;

        *DAC1Enable = outDAC1Enable;

        if( !(FIOAnalog == curFIOAnalog && EIOAnalog == curEIOAnalog) )
        {
            //Creating new FIOAnalog and EIOAnalog settings
            FIOAnalog = FIOAnalog | curFIOAnalog;
            EIOAnalog = EIOAnalog | curEIOAnalog;

            //Using ConfigIO to set new FIOAnalog and EIOAnalog settings
            if( (error = ehConfigIO(Handle, 12, curTCConfig, 0, FIOAnalog, EIOAnalog, NULL, NULL, &curFIOAnalog, &curEIOAnalog)) != 0 )
                return error;
        }
    }

    /* Setting up Feedback command to read analog input */
    sendDataBuff[0] = 1;    //IOType is AIN

    settling = (Settling != 0) ? 1 : 0;
    quicksample = (Resolution != 0) ? 1 : 0;
    sendDataBuff[1] = (uint8)ChannelP + settling*64 + quicksample*128;  //Positive channel (bits 0-4), LongSettling (bit 6)
                                                                        //QuickSample (bit 7)
    sendDataBuff[2] = (uint8)ChannelN;  //Negative channel

    if( ehFeedback(Handle, sendDataBuff, 3, &Errorcode, &ErrorFrame, recDataBuff, 2) < 0 )
        return -1;
    if( Errorcode )
        return (long)Errorcode;

    bytesVT = recDataBuff[0] + recDataBuff[1]*256;

    if( isSpecialRange )
    {
        ChannelN = 32; // Change the negative channel back to 32 from 30 for conversion.
    }

    if( Binary != 0 )
    {
        *Voltage = (double)bytesVT;
    }
    else
    {
        if( ChannelP == 30 )
        {
            if( getTempKCalibrated(CalibrationInfo, bytesVT, Voltage) < 0 )
                return -1;
        }
        else
        {
            if( hwver < 1.30 )
                error = getAinVoltCalibrated(CalibrationInfo, (int)(*DAC1Enable), ChannelN, bytesVT, Voltage);
            else
                error = getAinVoltCalibrated_hw130(CalibrationInfo, ChannelP, ChannelN, bytesVT, Voltage);
            if( error < 0 )
                return -1;
        }
    }

    return 0;
}


long eDAC(HANDLE Handle, u3CalibrationInfo *CalibrationInfo, long ConfigIO, long Channel, double Voltage, long Binary, long Reserved1, long Reserved2)
{
    uint8 sendDataBuff[3];
    uint8 byteV, DAC1Enabled, Errorcode, ErrorFrame;
    uint16 bytesV;
    long error, sendSize;

    if( isCalibrationInfoValid(CalibrationInfo) == 0 )
    {
        printf("eDAC error: calibration information is required");
        return -1;
    }

    if( Channel < 0 || Channel > 1 )
    {
        printf("eDAC error: Invalid DAC channel\n");
        return -1;
    }

    if( ConfigIO != 0 && Channel == 1 && CalibrationInfo->hardwareVersion < 1.30 )
    {
        //Using ConfigIO to enable DAC1
        error = ehConfigIO(Handle, 2, 0, 1, 0, 0, NULL, &DAC1Enabled, NULL, NULL);
        if( error != 0 )
            return error;
    }

    /* Setting up Feedback command to set DAC */
    if( CalibrationInfo->hardwareVersion < 1.30 )
    {
        sendSize = 2;

        sendDataBuff[0] = 34 + Channel;  //IOType is DAC0/1 (8 bit)

        if( getDacBinVoltCalibrated8Bit(CalibrationInfo, (int)Channel, Voltage, &byteV) < 0 )
            return -1;

        sendDataBuff[1] = byteV;  //Value
    }
    else
    {
        sendSize = 3;

        sendDataBuff[0] = 38 + Channel;  //IOType is DAC0/1 (16 bit)

        if( getDacBinVoltCalibrated16Bit(CalibrationInfo, (int)Channel, Voltage, &bytesV) < 0 )
            return -1;

        sendDataBuff[1] = (uint8)(bytesV&255);  //Value LSB
        sendDataBuff[2] = (uint8)((bytesV&65280)/256);  //Value MSB
    }

    if( ehFeedback(Handle, sendDataBuff, sendSize, &Errorcode, &ErrorFrame, NULL, 0) < 0 )
        return -1;
    if( Errorcode )
        return (long)Errorcode;

    return 0;
}


long eDI(HANDLE Handle, long ConfigIO, long Channel, long *State)
{
    uint8 sendDataBuff[4], recDataBuff[1];
    uint8 Errorcode, ErrorFrame, FIOAnalog, EIOAnalog;
    uint8 curFIOAnalog, curEIOAnalog, curTCConfig;
    long error;

    if( Channel < 0 || Channel > 19 )
    {
        printf("eDI error: Invalid DI channel\n");
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
            //Creating new FIOAnalog and EIOAnalog settings
            FIOAnalog = FIOAnalog & curFIOAnalog;
            EIOAnalog = EIOAnalog & curEIOAnalog;

            //Using ConfigIO to set new FIOAnalog and EIOAnalog settings
            error = ehConfigIO(Handle, 12, curTCConfig, 0, FIOAnalog, EIOAnalog, NULL, NULL, &curFIOAnalog, &curEIOAnalog);
            if( error != 0 )
                return error;
        }
    }

    /* Setting up Feedback command to set digital Channel to input and to read from it */
    sendDataBuff[0] = 13;  //IOType is BitDirWrite
    sendDataBuff[1] = Channel;  //IONumber(bits 0-4) + Direction (bit 7)

    sendDataBuff[2] = 10;  //IOType is BitStateRead
    sendDataBuff[3] = Channel;  //IONumber

    if( ehFeedback(Handle, sendDataBuff, 4, &Errorcode, &ErrorFrame, recDataBuff, 1) < 0 )
        return -1;
    if( Errorcode )
        return (long)Errorcode;

    *State = recDataBuff[0];
    return 0;
}


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


long eTCConfig(HANDLE Handle, long *aEnableTimers, long *aEnableCounters, long TCPinOffset, long TimerClockBaseIndex, long TimerClockDivisor, long *aTimerModes, double *aTimerValues, long Reserved1, long Reserved2)
{
    uint8 sendDataBuff[8];
    uint8 FIOAnalog, EIOAnalog, curFIOAnalog, curEIOAnalog;
    uint8 TimerCounterConfig, curTimerCounterConfig, Errorcode, ErrorFrame;
    int sendDataBuffSize, numTimers, numCounters, i;
    long error;

    if( TCPinOffset < 0 && TCPinOffset > 8 )
    {
        printf("eTCConfig error: Invalid TimerCounterPinOffset\n");
        return -1;
    }

    /* ConfigTimerClock */
    if( TimerClockBaseIndex == LJ_tc2MHZ || TimerClockBaseIndex ==  LJ_tc6MHZ ||
        TimerClockBaseIndex == LJ_tc24MHZ || TimerClockBaseIndex == LJ_tc500KHZ_DIV ||
        TimerClockBaseIndex == LJ_tc2MHZ_DIV || TimerClockBaseIndex == LJ_tc6MHZ_DIV ||
        TimerClockBaseIndex == LJ_tc24MHZ_DIV)
    {
        TimerClockBaseIndex = TimerClockBaseIndex - 10;
    }
    else if( TimerClockBaseIndex == LJ_tc4MHZ || TimerClockBaseIndex ==  LJ_tc12MHZ ||
             TimerClockBaseIndex == LJ_tc48MHZ || TimerClockBaseIndex == LJ_tc1MHZ_DIV ||
             TimerClockBaseIndex == LJ_tc4MHZ_DIV || TimerClockBaseIndex == LJ_tc12MHZ_DIV ||
             TimerClockBaseIndex == LJ_tc48MHZ_DIV)
    {
        TimerClockBaseIndex = TimerClockBaseIndex - 20;
    }

    error = ehConfigTimerClock(Handle, (uint8)(TimerClockBaseIndex + 128), (uint8)TimerClockDivisor, NULL, NULL);
    if( error != 0 )
        return error;

    //Using ConfigIO to get current FIOAnalog and curEIOAnalog settings
    error = ehConfigIO(Handle, 0, 0, 0, 0, 0, NULL, NULL, &curFIOAnalog, &curEIOAnalog);
    if( error != 0 )
        return error;

    numTimers = 0;
    numCounters = 0;
    TimerCounterConfig = 0;
    FIOAnalog = 255;
    EIOAnalog = 255;

    for( i = 0; i < 2; i++ )
    {
        if( aEnableTimers[i] != 0 )
            numTimers++;
        else
            i = 999;
    }

    for( i = 0; i < 2; i++ )
    {
        if( aEnableCounters[i] != 0 )
        {
            numCounters++;
            TimerCounterConfig += pow(2, (i+2));
        }
    }

    TimerCounterConfig += numTimers + TCPinOffset*16;

    for( i = 0; i < numCounters + numTimers; i++ )
    {
        if( i + TCPinOffset < 8 )
            FIOAnalog = FIOAnalog - pow(2, i + TCPinOffset);
        else
            EIOAnalog = EIOAnalog - pow(2, (i + TCPinOffset - 8));
    }

    FIOAnalog = FIOAnalog & curFIOAnalog;
    EIOAnalog = EIOAnalog & curEIOAnalog;
    error = ehConfigIO(Handle, 13, TimerCounterConfig, 0, FIOAnalog, EIOAnalog, &curTimerCounterConfig, NULL, &curFIOAnalog, &curEIOAnalog);
    if( error != 0 )
        return error;

    if( numTimers > 0 )
    {
        /* Feedback */
        for( i = 0; i < 8; i++ )
            sendDataBuff[i] = 0;

        for( i = 0; i < numTimers; i++ )
        {
            sendDataBuff[i*4] = 43 + i*2;  //TimerConfig
            sendDataBuff[1 + i*4] = (uint8)aTimerModes[i];  //TimerMode
            sendDataBuff[2 + i*4] = (uint8)(((long)aTimerValues[i])&0x00ff);  //Value LSB
            sendDataBuff[3 + i*4] = (uint8)((((long)aTimerValues[i])&0xff00)/256);  //Value MSB
        }

        sendDataBuffSize = 4 * numTimers;

        if( ehFeedback(Handle, sendDataBuff, sendDataBuffSize, &Errorcode, &ErrorFrame, NULL, 0) < 0 )
            return -1;
        if( Errorcode )
            return (long)Errorcode;
    }

    return 0;
}


long eTCValues(HANDLE Handle, long *aReadTimers, long *aUpdateResetTimers, long *aReadCounters, long *aResetCounters, double *aTimerValues, double *aCounterValues, long Reserved1, long Reserved2)
{
    uint8 sendDataBuff[12], recDataBuff[16], Errorcode, ErrorFrame;
    int sendDataBuffSize, recDataBuffSize, i, j;
    int numTimers, dataCountCounter, dataCountTimer;

    /* Feedback */
    numTimers = 0;
    dataCountCounter = 0;
    dataCountTimer = 0;
    sendDataBuffSize = 0;
    recDataBuffSize = 0;

    for( i = 0; i < 2; i++ )
    {
        if( aReadTimers[i] != 0 || aUpdateResetTimers[i] != 0 )
        {
            sendDataBuff[sendDataBuffSize] = 42 + i*2;  //Timer
            sendDataBuff[1 + sendDataBuffSize] = ((aUpdateResetTimers[i] != 0) ? 1 : 0);  //UpdateReset
            sendDataBuff[2 + sendDataBuffSize] = (uint8)(((long)aTimerValues[i])&0x00ff);  //Value LSB
            sendDataBuff[3 + sendDataBuffSize] = (uint8)((((long)aTimerValues[i])&0xff00)/256);  //Value MSB
            sendDataBuffSize += 4;
            recDataBuffSize += 4;
            numTimers++;
        }
    }

    for( i = 0; i < 2; i++ )
    {
        if( aReadCounters[i] != 0 || aResetCounters[i] != 0 )
        {
            sendDataBuff[sendDataBuffSize] = 54 + i;  //Counter
            sendDataBuff[1 + sendDataBuffSize] = ((aResetCounters[i] != 0) ? 1 : 0);  //Reset
            sendDataBuffSize += 2;
            recDataBuffSize += 4;
        }
    }

    if( ehFeedback(Handle, sendDataBuff, sendDataBuffSize, &Errorcode, &ErrorFrame, recDataBuff, recDataBuffSize) < 0 )
        return -1;
    if( Errorcode )
        return (long)Errorcode;

    for( i = 0; i < 2; i++ )
    {
        aTimerValues[i] = 0;
        if( aReadTimers[i] != 0 )
        {
            for( j = 0; j < 4; j++ )
                aTimerValues[i] += (double)((long)recDataBuff[j + dataCountTimer*4]*pow(2, 8*j));
        }
        if( aReadTimers[i] != 0 || aUpdateResetTimers[i] != 0 )
            dataCountTimer++;

        aCounterValues[i] = 0;
        if( aReadCounters[i] != 0 )
        {
            for( j = 0; j < 4; j++ )
                aCounterValues[i] += (double)((long)recDataBuff[j + numTimers*4 + dataCountCounter*4]*pow(2, 8*j));
        }
        if( aReadCounters[i] != 0 || aResetCounters[i] != 0 )
            dataCountCounter++;
    }

    return 0;
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


long ehConfigTimerClock(HANDLE hDevice, uint8 inTimerClockConfig, uint8 inTimerClockDivisor, uint8 *outTimerClockConfig, uint8 *outTimerClockDivisor)
{
    uint8 sendBuff[10], recBuff[10];
    uint16 checksumTotal;
    int sendChars, recChars;

    sendBuff[1] = (uint8)(0xF8);  //Command byte
    sendBuff[2] = (uint8)(0x02);  //Number of data words
    sendBuff[3] = (uint8)(0x0A);  //Extended command number

    sendBuff[6] = 0;  //Reserved
    sendBuff[7] = 0;  //Reserved

    sendBuff[8] = inTimerClockConfig;  //TimerClockConfig
    sendBuff[9] = inTimerClockDivisor;  //TimerClockDivisor
    extendedChecksum(sendBuff, 10);

    //Sending command to U3
    if( (sendChars = LJUSB_Write(hDevice, sendBuff, 10)) < 10 )
    {
        if( sendChars == 0 )
            printf("ehConfigTimerClock error : write failed\n");
        else
            printf("ehConfigTimerClock error : did not write all of the buffer\n");
        return -1;
    }

    //Reading response from U3
    if( (recChars = LJUSB_Read(hDevice, recBuff, 10)) < 10 )
    {
        if( recChars == 0 )
            printf("ehConfigTimerClock error : read failed\n");
        else
            printf("ehConfigTimerClock error : did not read all of the buffer\n");
        return -1;
    }

    checksumTotal = extendedChecksum16(recBuff, 10);
    if( (uint8)((checksumTotal / 256 ) & 0xff) != recBuff[5] )
    {
        printf("ehConfigTimerClock error : read buffer has bad checksum16(MSB)\n");
        return -1;
    }

    if( (uint8)(checksumTotal & 0xff) != recBuff[4] )
    {
        printf("ehConfigTimerClock error : read buffer has bad checksum16(LBS)\n");
        return -1;
    }

    if( extendedChecksum8(recBuff) != recBuff[0] )
    {
        printf("ehConfigTimerClock error : read buffer has bad checksum8\n");
        return -1;
    }

    if( recBuff[1] != (uint8)(0xF8) || recBuff[2] != (uint8)(0x02) || recBuff[3] != (uint8)(0x0A) )
    {
        printf("ehConfigTimerClock error : read buffer has wrong command bytes\n");
        return -1;
    }

    if( outTimerClockConfig != NULL )
        *outTimerClockConfig = recBuff[8];

    if( outTimerClockDivisor != NULL )
        *outTimerClockDivisor = recBuff[9];

    if( recBuff[6] != 0 )
    {
        printf("ehConfigTimerClock error : read buffer received errorcode %d\n", recBuff[6]);
        return recBuff[6];
    }

    return 0;
}


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