# AccelStepperAddon - MATLAB Interface for Arduino Stepper Motor Control

MATLAB add-on that allows to control stepper motors through an Arduino board by interfacing the powerful [AccelStepper](https://www.arduino.cc/reference/en/libraries/accelstepper/) library. It is inspired by the [DHT22 add-on](https://mathworks.com/matlabcentral/fileexchange/72441-dht22-add-on-library-for-arduino) provided by MATLAB and follows the [MATLAB Arduino add-on library guide](https://www.mathworks.com/help/matlab/arduinoio-custom-arduino-libraries.html).

Confirmed to work in MATLAB 2023b on Arduino Pro Mini, Uno R3, and Due using the common 28BYJ-48 stepper motors with ULN2003A controllers.

## How to install

- Install the [MATLAB Support Package for Arduino](https://www.mathworks.com/hardware-support/arduino-matlab.html).
- Copy the [AccelStepper library files](https://www.arduino.cc/reference/en/libraries/accelstepper/) into a new folder `AccelStepper` created in your MATLAB Arduino library folder, typically located in `C:\ProgramData\MATLAB\SupportPackages\R2023b\aIDE\libraries`.
- Create a folder `+arduinoioaddons` in your working directory.
- Create a folder `+AccelStepperAddon` inside this folder.
- Paste the files of this project into it.
- Your folder structure should now look like [this](https://www.mathworks.com/help/matlab/supportpkg/create-custom-folder-structure.html).

## Usage examples
See `Example.m` for the complete code example.

Create the Arduino object using the AccelStepperAddon library:
```Matlab
a = arduino('COM4', 'Due', 'Libraries', ...
    {'AccelStepperAddon/AccelStepperAddon'}, 'Traceon', true)
```

Create a stepper object with pins D2-D5:
```Matlab
s1 = addon(a,'AccelStepperAddon/AccelStepperAddon', {'D2','D3','D4','D5'})
```

Set the maximum speed of the stepper:
```Matlab
s1.setMaxSpeed(400)
```

Get the maximum speed of the stepper:
```Matlab
s1.maxSpeed()
```

Set the acceleration of the stepper:
```Matlab
s1.setAcceleration(400)
```

Get the acceleration of the stepper:
```Matlab
s1.acceleration()
```

Enable the stepper to step when a step is due, implementing acceleration and deceleration to reach the target position:
```Matlab
s1.startrun()
```

Get the remaining steps:
```Matlab
s1.distanceToGo()
```

Move to absolute position 1000:
```Matlab
s1.moveTo(1000)
```

Move back 100 steps:
```Matlab
s1.move(-100)
```

Get the current target position:
```Matlab
s1.targetPosition()
```

Get the current position:
```Matlab
s1.currentPosition()
```

Set the current position to 0:
```Matlab
s1.setCurrentPosition(0)
```

Check if the stepper is stepping:
```Matlab
s1.isRunning()
```

Stop the stepper with deceleration:
```Matlab
s1.stop()
```

Disable the corresponding outputs of the stepper:
```Matlab
s1.disableOutputs()
```

Enable the corresponding outputs of the stepper:
```Matlab
s1.enableOutputs()
```

Create a second stepper:
```Matlab
s2 = addon(a,"AccelStepperAddon/AccelStepperAddon", 'DRIVER', {'D7', 'D8'})
```

Set the minimum pulse width allowed by the stepper driver:
```Matlab
s2.setMinPulseWidth(50)
```

Set the enable pin for the stepper driver (default ''):
```Matlab
s2.setEnablePin('D6')
```

Invert the enable pin:
```Matlab
s2.setPinsInverted(false, false, true)
```

Set the maximum speed of the stepper:
```Matlab
s2.setMaxSpeed(400)
```

This limits the value of setSpeed, but there is a quirk in the AccelStepper library: After decreasing the value of setMaxSpeed below the value of setSpeed, AccelStepper respects this updated limit only if the value of setSpeed is also *changed*; increasing the value of setMaxSpeed above the value of setSpeed, however, is respected even after calling setSpeed() with the *current* speed.

Set the speed for the constant speed movement:
```Matlab
s2.setSpeed(123.456)
```

Get the speed for the constant speed movement:
```Matlab
s2.speed()
```

Start movement with constant speed:
```Matlab
s2.startrunSpeed()
```

Stop movement immediately:
```Matlab
s2.stoprun()
```

Clean up (takes ~20 seconds):
```Matlab
clear a s1 s2
```

## Notes
The following AccelStepper library functions are *not* implemented in this interface yet:

- `runToPosition`
- `runSpeedToPosition`
- `runToNewPosition`

Note that for the 28BYJ-48 stepper the middle two pins must be swapped physically (initialized with `{'D2','D3','D4','D5'}`) or in software (initialized with `{'D2','D4','D3','D5'}`).

The maximum number of steppers is currently hardcoded to `MAX_NUMBER_STEPPERS = 4` in `AccelStepperAddon.h` and `AccelStepperAddon.m` to reduce the allocated memory. It can be changed before building and flashing the Arduino.

## References

- The interfaced library: https://www.airspayce.com/mikem/arduino/AccelStepper  
- Following the MATLAB Arduino add-on library guide: https://www.mathworks.com/help/matlab/arduinoio-custom-arduino-libraries.html
- Following the MATLAB example: https://www.mathworks.com/matlabcentral/fileexchange/72441-dht22-add-on-library-for-arduino
- Example of the add-on folder structure: https://www.mathworks.com/help/matlab/supportpkg/create-custom-folder-structure.html