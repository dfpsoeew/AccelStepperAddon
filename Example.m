%% Create the Arduino object using the AccelStepperAddon library
a = arduino('COM4', 'Due', 'Libraries', ...
    {'AccelStepperAddon/AccelStepperAddon'}, 'Traceon', true)

%% Create a stepper object with pins D2-D5
s1 = addon(a,'AccelStepperAddon/AccelStepperAddon', {'D2','D3','D4','D5'})

%% Set the maximum speed of the stepper
s1.setMaxSpeed(400)

%% Get the maximum speed of the stepper
s1.maxSpeed()

%% Set the acceleration of the stepper
s1.setAcceleration(400)

%% Get the acceleration of the stepper
s1.acceleration()

%% Enable the stepper to step when a step is due, implementing acceleration 
% and deceleration to reach the target position
s1.startrun()

%% Get the remaining steps
s1.distanceToGo()

%% Move to absolute position 1000
s1.moveTo(1000)

%% Move back 100 steps
s1.move(-100)

%% Get the current target position
s1.targetPosition()

%% Get the current position
s1.currentPosition()

%% Set the current position to 0
s1.setCurrentPosition(0)

%% Check if the stepper is stepping
s1.isRunning()

%% Stop the stepper with deceleration
s1.stop()

%% Disable the corresponding outputs of the stepper
s1.disableOutputs()

%% Enable the corresponding outputs of the stepper
s1.enableOutputs()

%% Create a second stepper
s2 = addon(a,"AccelStepperAddon/AccelStepperAddon", {'D6','D7','D8','D9'})

%% Set the maximum speed of the stepper (limits the value of setSpeed)
s2.setMaxSpeed(400)

%% Set the speed for the constant speed movement
s2.setSpeed(123.456)

%% Get the speed for the constant speed movement
s2.speed()

%% Start movement with constant speed
s2.startrunSpeed()

%% Stop movement immediately
s2.stoprun()

%% Clean up (takes ~20 seconds)
clear a s1 s2
