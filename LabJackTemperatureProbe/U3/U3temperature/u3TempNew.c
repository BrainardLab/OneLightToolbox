// *** Filename: U3Temp.c
// *** Purpose: Read both the internal and Ext temperature 
//			From the EI-1034 sensor and return it 
//			to a function. 
//			Many of the functions are extracted from 
//			The u3Feedback.c file to communicate with the sensor
// *** Date: 11-30-2016

#include <unistd.h>
#include <termios.h>
#include "u3.h"


static struct termios termNew, termOrig;
static int peek = -1;

//
// *** Prototypes
//
int configIO_example(HANDLE hDevice, int enable, int *isDAC1Enabled);
int feedback_setup_example(HANDLE hDevice, u3CalibrationInfo *caliInfo);
int feedback_loop_example(HANDLE hDevice, u3CalibrationInfo *caliInfo, int isDAC1Enabled);
void readU3Temp(double *tempdata);

void setTerm();
int kbhit();
void unsetTerm();

static HANDLE hDevice;
u3CalibrationInfo caliInfo;
int isDAC1Enabled;

int openUE3device();
int closeUE3device();
int readTemperature();

int main(int argc, char **argv)
{
    openUE3device();
    readTemperature();
    closeUE3device();
}

int openUE3device() 
{
    if ( (hDevice = openUSBConnection(-1)) == NULL) {
        return 0;  // could not open device
    }
    
    //Getting calibration information from UE9
    if( getCalibrationInfo(hDevice, &caliInfo) < 0 ) {
        return 0;  // could not get calibration data
    }

    if(configIO_example(hDevice, 1, &dac1Enabled) != 0 ) {}
        return 0;
    }

    feedback_setup_example();
    return(1);    
}

int closeUE3device() 
{
    if (hDevice != NULL) {
        closeUSBConnection(hDevice);
        hDevice = NULL;
    }
    else {
        mexPrintf("U3 device was not open.\n");
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
    getDacBinVoltCalibrated8Bit(caliInfo, 0, 1.5, &sendBuff[30]);
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
    long count;
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
        getAinVoltCalibrated(caliInfo, isDAC1Enabled, 31, recBuff[9] + recBuff[10]*256, &voltageT);

        //printf("AIN0(SE) : %.3f volts\n", voltageT); 

        // This is the Internal Sensor Temperature in Kelvin
        getTempKCalibrated(caliInfo, recBuff[26] + recBuff[27]*256, &temperature);
        
        //printf("Temperature : %.3f K\n", temperature);

        // Get the voltage value and convert this to Farenheit degrees 
        // Per manual, Volts * 100 = Farenheit degrees
        // printf("Temperature Sensor: %.2f Farenheit\n", (voltageT*100));
        // printf("Temperature Sensor (K): %.2f Kelvin\n\n\n\n", ((55.56*voltageT) + 255.37));
        
        tempData[0] = ((1.8)*(temperature-273))+32.0; /* convert K to F */
        tempData[1] = voltageT*100;
        readU3Temp(TempData);

        printf("Temperature Int Sensor : %.2f Farenheit\n", tempdata[0]);        
        printf("Temperature Ext Sensor : %.2f Farenheit\n", tempdata[1]);

        status = 0;
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

    printf("Running U3Temp calls in a loop:\n** Press any key to stop **\n");

    count = 0;
    while( !kbhit() )
    {
        count++;
        printf("Iteration %ld\n", count);

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
        getAinVoltCalibrated(caliInfo, isDAC1Enabled, 31, recBuff[9] + recBuff[10]*256, &voltageT);

        //printf("AIN0(SE) : %.3f volts\n", voltageT); 

        // This is the Internal Sensor Temperature in Kelvin
        getTempKCalibrated(caliInfo, recBuff[26] + recBuff[27]*256, &temperature);
        
        //printf("Temperature : %.3f K\n", temperature);

        // Get the voltage value and convert this to Farenheit degrees 
        // Per manual, Volts * 100 = Farenheit degrees
        // printf("Temperature Sensor: %.2f Farenheit\n", (voltageT*100));
        // printf("Temperature Sensor (K): %.2f Kelvin\n\n\n\n", ((55.56*voltageT) + 255.37));
        
        TempData[0] = ((1.8)*(temperature-273))+32.0; /* convert K to F */
        TempData[1] = voltageT*100;
        printf("Temperature Int Sensor : %.2f Farenheit\n", tempdata[0]);        
        printf("Temperature Ext Sensor : %.2f Farenheit\n", tempdata[1]);

        sleep(1);
    }
    return 0;
}