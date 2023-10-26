/**
 * @file AccelStepperAddon.h
 *
 * Class definition for AccelStepper class that wraps APIs of the AccelStepper library
 * https://www.airspayce.com/mikem/arduino/AccelStepper
 */

#include "LibraryBase.h"
#include "AccelStepper.h"

#define MAX_NUMBER_STEPPERS 4 // Allocate memory for this amount of steppers

// Command ID's
#define CREATE_STEPPER 0x01
#define DELETE_STEPPER 0x02
#define MOVETO_STEPPER 0x03
#define MOVE_STEPPER 0x04
#define SETMAXSPEED_STEPPER 0x05
#define MAXSPEED_STEPPER 0x06
#define SETACCELERATION_STEPPER 0x07
#define ACCELERATION_STEPPER 0x08
#define SETSPEED_STEPPER 0x09
#define SPEED_STEPPER 0x0A
#define DISTANCETOGO_STEPPER 0x0B
#define TARGETPOSITION_STEPPER 0x0C
#define CURRENTPOSITION_STEPPER 0x0D
#define SETCURRENTPOSITION_STEPPER 0x0E
#define STOP_STEPPER 0x0F
#define DISABLEOUTPUTS_STEPPER 0x10
#define ENABLEOUTPUTS_STEPPER 0x11
#define ISRUNNING_STEPPER 0x12
#define STARTRUN_STEPPER 0x13
#define STARTRUNSPEED_STEPPER 0x14
#define STOPRUN_STEPPER 0x15

// Debug Strings
const char MSG_CREATE_STEPPER[] PROGMEM = "STEPPER[%d] = new AccelStepper(%d, %d, %d, %d, %d, %d);\n";
const char MSG_DELETE_STEPPER[] PROGMEM = "delete STEPPER[%d];\n";
const char MSG_MOVETO_STEPPER[] PROGMEM = "STEPPER[%d]->moveTo(%d);\n";
const char MSG_MOVE_STEPPER[] PROGMEM = "STEPPER[%d]->move(%d);\n";
const char MSG_SETMAXSPEED_STEPPER[] PROGMEM = "STEPPER[%d]->setMaxSpeed(%s);\n";
const char MSG_MAXSPEED_STEPPER[] PROGMEM = "STEPPER[%d]->maxSpeed() --> %s;\n";
const char MSG_SETACCELERATION_STEPPER[] PROGMEM = "STEPPER[%d]->setAcceleration(%s);\n";
const char MSG_ACCELERATION_STEPPER[] PROGMEM = "STEPPER[%d]->acceleration() --> %s;\n";
const char MSG_SETSPEED_STEPPER[] PROGMEM = "STEPPER[%d]->setSpeed(%s);\n";
const char MSG_SPEED_STEPPER[] PROGMEM = "STEPPER[%d]->speed() --> %s;\n";
const char MSG_DISTANCETOGO_STEPPER[] PROGMEM = "STEPPER[%d]->distanceToGo() --> %d;\n";
const char MSG_TARGETPOSITION_STEPPER[] PROGMEM = "STEPPER[%d]->targetPosition() --> %d;\n";
const char MSG_CURRENTPOSITION_STEPPER[] PROGMEM = "STEPPER[%d]->currentPosition() --> %d;\n";
const char MSG_SETCURRENTPOSITION_STEPPER[] PROGMEM = "STEPPER[%d]->setCurrentPosition(%d);\n";
const char MSG_STOP_STEPPER[] PROGMEM = "STEPPER[%d]->stop();\n";
const char MSG_DISABLEOUTPUTS_STEPPER[] PROGMEM = "STEPPER[%d]->disableOutputs();\n";
const char MSG_ENABLEOUTPUTS_STEPPER[] PROGMEM = "STEPPER[%d]->enableOutputs();\n";
const char MSG_ISRUNNING_STEPPER[] PROGMEM = "STEPPER[%d]->isRunning() --> %d;\n";
const char MSG_STARTRUN_STEPPER[] PROGMEM = "Enable STEPPER[%d]->run();\n";
const char MSG_STARTRUNSPEED_STEPPER[] PROGMEM = "Enable STEPPER[%d]->runSpeed();\n";
const char MSG_STOPRUN_STEPPER[] PROGMEM = "Disable STEPPER[%d]->run() and runSpeed();\n";
const char MSG_UNKNOWN_CMD[] PROGMEM = "STEPPER[%d]->Unknown Command\n";

// Saves integer and byte array in same memory location
typedef union
{
    int number;
    byte bytes[2];
} VALUEI;

// Saves long and byte array in same memory location
typedef union
{
    long number;
    byte bytes[4];
} VALUEL;

// Saves float and byte array in same memory location
typedef union
{
    float number;
    byte bytes[4];
} VALUEF;

class AccelStepperAddon : public LibraryBase
{
public:
    // Allocate memory for multiple steppers
    AccelStepper *steppers[MAX_NUMBER_STEPPERS];

public:
    // Steppers in 'run()' mode
    bool runEnabled[MAX_NUMBER_STEPPERS];

public:
    // Steppers in 'runSpeed()' mode
    bool runSpeedEnabled[MAX_NUMBER_STEPPERS];

public:
    // Constructor
    AccelStepperAddon(MWArduinoClass &a)
    {
        // Define the library name
        libName = "AccelStepperAddon/AccelStepperAddon";
        // Register the library to the server
        a.registerLibrary(this);
    }

public:
    // Override the default loop method of the LibraryBase class
    void loop()
    {
        for (int i = 0; i < MAX_NUMBER_STEPPERS; i++)
        {
            if (runEnabled[i])
            {
                steppers[i]->run(); // Call run() method from Stepper Library
            }
            else if (runSpeedEnabled[i])
            {
                steppers[i]->runSpeed(); // Call runSpeed() method from Stepper Library
            }
        }
    }

public:
    void commandHandler(byte cmdID, byte *dataIn, unsigned int payloadSize)
    {

        switch (cmdID)
        {

        case CREATE_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Get interface from dataIn
            byte interface = dataIn[1];
            // Get pins from dataIn
            byte pins[4] = {dataIn[2], dataIn[3], dataIn[4], dataIn[5]};
            // Get enable from dataIn
            bool enable = dataIn[6];
            // Create new stepper at pins
            steppers[stepperID] = new AccelStepper(interface, pins[0], pins[1], pins[2], pins[3], enable);
            // Print debug string and pins
            debugPrint(MSG_CREATE_STEPPER, stepperID, interface, pins[0], pins[1], pins[2], pins[3], enable);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case DELETE_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Make NULL
            steppers[stepperID] = NULL;
            // Print debug string
            debugPrint(MSG_DELETE_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case MOVETO_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            VALUEL value;
            value.bytes[0] = dataIn[1];
            value.bytes[1] = dataIn[2];
            value.bytes[2] = dataIn[3];
            value.bytes[3] = dataIn[4];
            // Call moveTo() method from Stepper Library
            steppers[stepperID]->moveTo(value.number);
            // Print debug string
            debugPrint(MSG_MOVETO_STEPPER, stepperID, value.number);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case MOVE_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            VALUEL value;
            value.bytes[0] = dataIn[1];
            value.bytes[1] = dataIn[2];
            value.bytes[2] = dataIn[3];
            value.bytes[3] = dataIn[4];
            // Call move() method from Stepper Library
            steppers[stepperID]->move(value.number);
            // Print debug string
            debugPrint(MSG_MOVE_STEPPER, stepperID, value.number);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case SETMAXSPEED_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            VALUEF value;
            value.bytes[0] = dataIn[1];
            value.bytes[1] = dataIn[2];
            value.bytes[2] = dataIn[3];
            value.bytes[3] = dataIn[4];
            // Call setMaxSpeed() method from Stepper Library
            steppers[stepperID]->setMaxSpeed(value.number);
            // Print debug string, convert Float to String for debugPrint
            debugPrint(MSG_SETMAXSPEED_STEPPER, stepperID, String(value.number).c_str());
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case MAXSPEED_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call maxSpeed() method from Stepper Library
            VALUEF value;
            value.number = steppers[stepperID]->maxSpeed();
            // Print debug string
            debugPrint(MSG_MAXSPEED_STEPPER, stepperID, String(value.number).c_str());
            // Send response
            sendResponseMsg(cmdID, value.bytes, 4);
            break;
        }

        case SETACCELERATION_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            VALUEF value;
            value.bytes[0] = dataIn[1];
            value.bytes[1] = dataIn[2];
            value.bytes[2] = dataIn[3];
            value.bytes[3] = dataIn[4];
            // Call setAcceleration() method from Stepper Library
            steppers[stepperID]->setAcceleration(value.number);
            // Print debug string, convert Float to String for debugPrint
            debugPrint(MSG_SETACCELERATION_STEPPER, stepperID, String(value.number).c_str());
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case ACCELERATION_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call acceleration() method from Stepper Library
            VALUEF value;
            value.number = steppers[stepperID]->acceleration();
            // Print debug string
            debugPrint(MSG_ACCELERATION_STEPPER, stepperID, String(value.number).c_str());
            // Send response
            sendResponseMsg(cmdID, value.bytes, 4);
            break;
        }

        case SETSPEED_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            VALUEF value;
            value.bytes[0] = dataIn[1];
            value.bytes[1] = dataIn[2];
            value.bytes[2] = dataIn[3];
            value.bytes[3] = dataIn[4];
            // Call setSpeed() method from Stepper Library
            steppers[stepperID]->setSpeed(value.number);
            // Print debug string, convert Float to String for debugPrint
            debugPrint(MSG_SETSPEED_STEPPER, stepperID, String(value.number).c_str());
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case SPEED_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call speed() method from Stepper Library
            VALUEF value;
            value.number = steppers[stepperID]->speed();
            // Print debug string
            debugPrint(MSG_SPEED_STEPPER, stepperID, String(value.number).c_str());
            // Send response
            sendResponseMsg(cmdID, value.bytes, 4);
            break;
        }

        case DISTANCETOGO_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call distanceToGo() method from Stepper Library
            VALUEL value;
            value.number = steppers[stepperID]->distanceToGo();
            // Print debug string
            debugPrint(MSG_DISTANCETOGO_STEPPER, stepperID, value.number);
            // Send response
            sendResponseMsg(cmdID, value.bytes, 4);
            break;
        }

        case TARGETPOSITION_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call targetPosition() method from Stepper Library
            VALUEL value;
            value.number = steppers[stepperID]->targetPosition();
            // Print debug string
            debugPrint(MSG_TARGETPOSITION_STEPPER, stepperID, value.number);
            // Send response
            sendResponseMsg(cmdID, value.bytes, 4);
            break;
        }

        case CURRENTPOSITION_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call currentPosition() method from Stepper Library
            VALUEL value;
            value.number = steppers[stepperID]->currentPosition();
            // Print debug string
            debugPrint(MSG_CURRENTPOSITION_STEPPER, stepperID, value.number);
            // Send response
            sendResponseMsg(cmdID, value.bytes, 4);
            break;
        }

        case SETCURRENTPOSITION_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            VALUEL value;
            value.bytes[0] = dataIn[1];
            value.bytes[1] = dataIn[2];
            value.bytes[2] = dataIn[3];
            value.bytes[3] = dataIn[4];
            // Call setCurrentPosition() method from Stepper Library
            steppers[stepperID]->setCurrentPosition(value.number);
            // Print debug string
            debugPrint(MSG_SETCURRENTPOSITION_STEPPER, stepperID, value.number);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case STOP_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call stop() method from Stepper Library
            steppers[stepperID]->stop();
            // Print debug string
            debugPrint(MSG_STOP_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case DISABLEOUTPUTS_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call disableOutputs() method from Stepper Library
            steppers[stepperID]->disableOutputs();
            // Print debug string
            debugPrint(MSG_DISABLEOUTPUTS_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case ENABLEOUTPUTS_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call enableOutputs() method from Stepper Library
            steppers[stepperID]->enableOutputs();
            // Print debug string
            debugPrint(MSG_ENABLEOUTPUTS_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case ISRUNNING_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Call isRunning() method from Stepper Library
            byte value = steppers[stepperID]->isRunning() ? (byte)1 : (byte)0;
            // Print debug string
            debugPrint(MSG_ISRUNNING_STEPPER, stepperID, value);
            // Send response
            sendResponseMsg(cmdID, &value, 1);
            break;
        }

        case STARTRUN_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Enable stepper for mode 'run()'
            runEnabled[stepperID] = true;
            runSpeedEnabled[stepperID] = false;
            // Print debug string
            debugPrint(MSG_STARTRUN_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case STARTRUNSPEED_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Enable stepper for mode 'runSpeed()'
            runEnabled[stepperID] = false;
            runSpeedEnabled[stepperID] = true;
            // Print debug string
            debugPrint(MSG_STARTRUNSPEED_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        case STOPRUN_STEPPER:
        {
            // Get stepper ID from dataIn
            byte stepperID = dataIn[0];
            // Stop the stepper
            runEnabled[stepperID] = false;
            runSpeedEnabled[stepperID] = false;
            // Print debug string
            debugPrint(MSG_STOPRUN_STEPPER, stepperID);
            // Send response
            sendResponseMsg(cmdID, 0, 0);
            break;
        }

        default:
        {
            // Print debug string
            debugPrint(MSG_UNKNOWN_CMD);
            break;
        }
        }
    }
};