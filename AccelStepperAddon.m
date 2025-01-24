classdef AccelStepperAddon < matlabshared.addon.LibraryBase & matlab.mixin.CustomDisplay
    % AccelStepperAddon - MATLAB Interface for Arduino Stepper Motor Control
    %
    % Create an AccelStepperAddon device object to control stepper motors
    % via the Arduino AccelStepper library.
    %
    % See also https://www.airspayce.com/mikem/arduino/AccelStepperAddon
    % Based on https://de.mathworks.com/matlabcentral/fileexchange/72441-dht22-add-on-library-for-arduino

    properties (Access = private, Constant = true)
        CREATE_STEPPER              = hex2dec('01')
        DELETE_STEPPER              = hex2dec('02')
        MOVETO_STEPPER              = hex2dec('03')
        MOVE_STEPPER                = hex2dec('04')
        SETMAXSPEED_STEPPER         = hex2dec('05')
        MAXSPEED_STEPPER            = hex2dec('06')
        SETACCELERATION_STEPPER     = hex2dec('07')
        ACCELERATION_STEPPER        = hex2dec('08')
        SETSPEED_STEPPER            = hex2dec('09')
        SPEED_STEPPER               = hex2dec('0A')
        DISTANCETOGO_STEPPER        = hex2dec('0B')
        TARGETPOSITION_STEPPER      = hex2dec('0C')
        CURRENTPOSITION_STEPPER     = hex2dec('0D')
        SETCURRENTPOSITION_STEPPER  = hex2dec('0E')
        STOP_STEPPER                = hex2dec('0F')
        DISABLEOUTPUTS_STEPPER      = hex2dec('10')
        ENABLEOUTPUTS_STEPPER       = hex2dec('11')
        SETMINPULSEWIDTH_STEPPER    = hex2dec('12')
        SETENABLEPIN_STEPPER        = hex2dec('13')
        SETPINSINVERTED_STEPPER     = hex2dec('14')
        ISRUNNING_STEPPER           = hex2dec('15')
        STARTRUN_STEPPER            = hex2dec('16')
        STARTRUNSPEED_STEPPER       = hex2dec('17')
        STOPRUN_STEPPER             = hex2dec('18')

        MAX_NUMBER_STEPPERS = 4 % Value needs to match the one in AccelStepperAddon.h
    end

    properties (Constant)
        MotorInterfaceType = struct('FUNCTION', 0, ...
            'DRIVER', 1, ...
            'FULL2WIRE', 2, ...
            'FULL3WIRE', 3, ...
            'FULL4WIRE', 4, ...
            'HALF3WIRE', 6, ...
            'HALF4WIRE', 8);
    end

    properties (Access = protected, Constant = true)
        LibraryName = 'AccelStepperAddon/AccelStepperAddon'
        DependentLibraries = {}
        LibraryHeaderFiles = {'AccelStepper/AccelStepper.h'}
        CppHeaderFile = fullfile(arduinoio.FilePath(mfilename('fullpath')), 'src', 'AccelStepperAddon.h')
        CppClassName = 'AccelStepperAddon'
    end

    properties (Access = private)
        StepperID;
        ResourceOwner = 'AccelStepperAddon/AccelStepperAddon';
    end

    properties (SetAccess = private) % Default constructor arguments
        Interface = 4; % Default interface 'FULL4WIRE'
        Pins = {'D2', 'D3', 'D4', 'D5'}; % Default stepper pins
        Enable = true; % Enable by default
        EnablePin = ''; % Use no enable pin by default
    end

    % Constructor Method
    methods (Hidden, Access = public)
        function obj = AccelStepperAddon(parentObj, varargin)
            %ACCELSTEPPERADDON Create an AccelStepperAddon object.
            %   s = addon(a,'AccelStepperAddon/AccelStepperAddon', interface, arduinoPins, enable)
            %   Interfaces the constructor method of the Arduino
            %   AccelStepper library. Refer to its documentation for more
            %   details. In short, the parameters are:
            %   interface: (optional) Motor interface type (default
            %   'FULL4WIRE')
            %   arduinoPins: (optional) Arduino digital pin numbers for
            %   motor pins. Provide a cell array of strings/chars giving
            %   the names of the Arduino pins assigned to this stepper
            %   (default {'D2','D3','D4','D5'}).
            %   enable (optional): If this is true (the default),
            %   enableOutputs() will be called to enable the output pins at
            %   construction time.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.moveTo(1000)
            %       s.setMaxSpeed(400)
            %       s.setAcceleration(400)
            %       s.startrun()
            %       s.distanceToGo()
            %
            %   See also ARDUINO, ADDON

            for i = 1:numel(varargin)
                if ischar(varargin{i})
                    obj.Interface = obj.MotorInterfaceType.(varargin{i});
                elseif iscell(varargin{i}) && numel(varargin{i}) < 5
                    obj.Pins = varargin{i};
                elseif islogical(varargin{i})
                    obj.Enable = varargin{i};
                else
                    warning('Unexpected datatype in constructor method ''AccelStepperAddon''.')
                end
            end

            obj.Parent = parentObj;

            try
                %Get new ID for stepper. Validate it.
                obj.StepperID = getResourceCount(obj.Parent, 'AccelStepperAddon');
                if obj.StepperID >= obj.MAX_NUMBER_STEPPERS
                    error('AccelStepperAddon:AccelStepperAddon:ValueError', 'Maximum supported number of steppers (= %d) has been reached.', obj.MAX_NUMBER_STEPPERS);
                end

                % Validate Uniqueness of Pin Resource
                for arduinoPin = obj.Pins
                    terminal = getTerminalsFromPins(obj.Parent, arduinoPin);
                    owner = getResourceOwner(obj.Parent, terminal);
                    if ~isempty(owner)
                        error('AccelStepperAddon:AccelStepperAddon:DuplicatePin', 'Arduino pin %s is registered with %s object. Sharing of pin is not supported.', arduinoPin, owner);
                    end
                end

                % Initialize Property: Arduino Pins
                for i = 1:numel(obj.Pins)
                    arduinoPin = obj.Pins{i};
                    if ischar(arduinoPin) || isstring(arduinoPin)
                        obj.Pins{i} = char(arduinoPin);
                    else
                        error('AccelStepperAddon:AccelStepperAddon:InvalidPin', 'arduinoPin argument expects a char or string but received %s.', class(arduinoPin));
                    end
                end

                % Setup the Pins for use
                cellfun(@(x)configurePinResource(obj.Parent, x, obj.ResourceOwner, 'DigitalOutput'), obj.Pins);
                % Increment current resource count
                incrementResourceCount(obj.Parent, 'AccelStepperAddon');
                % Create Stepper
                createStepper(obj);
            catch e
                throwAsCaller(e);
            end
        end
    end

    % Destructor Method
    methods (Access = protected)
        function delete(obj)
            try
                parentObj = obj.Parent;
                cellfun(@(x)configurePinResource(parentObj, x, obj.ResourceOwner, 'Unset'), obj.Pins);
                if ~isempty(obj.EnablePin)
                    configurePinResource(parentObj, obj.EnablePin, obj.ResourceOwner, 'Unset');
                end
                decrementResourceCount(obj.Parent, 'AccelStepperAddon');
                deleteStepper(obj);
            catch
                % Do not throw any errors
            end
        end
    end

    methods (Access = private)
        % Create Stepper
        function createStepper(obj)
            cmdID = obj.CREATE_STEPPER;
            terminals = cellfun(@(x)getTerminalsFromPins(obj.Parent, x), obj.Pins);
            terminals = [terminals, zeros(1, 4-numel(terminals))];
            sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, obj.Interface, terminals, obj.Enable]);
        end
        % Delete Stepper
        function deleteStepper(obj)
            cmdID = obj.DELETE_STEPPER;
            sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
        end
        % Create Enable Pin
        function createEnablePin(obj)
            cmdID = obj.SETENABLEPIN_STEPPER;
            if isempty(obj.EnablePin)
                terminal = 0; % No pin assigned
            else
                terminal = getTerminalsFromPins(obj.Parent, obj.EnablePin);
            end
            sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, terminal]);
        end
    end

    methods (Access = public)
        function moveTo(obj, absolute)
            %MOVETO Set the target position. The run() function will try to
            %move the motor (at most one step per call) from the current
            %position to the target position set by the most recent call to
            %this function. Caution: moveTo() also recalculates the speed
            %for the next step.  If you are trying to use constant speed
            %movements, you should call setSpeed() after calling moveTo().
            %   absolute: The desired absolute position. Negative is
            %   anticlockwise from the 0 position.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.moveTo(200)
            %
            %   See also ARDUINO, ADDON, STARTRUN, STOPRUN, MOVE

            cmdID = obj.MOVETO_STEPPER;

            try
                % Data is send in bytes. Split long up in four bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(int32(absolute), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function move(obj, relative)
            %MOVE Set the target position relative to the current position.
            %   relative: The desired position relative to the current
            %   position. Negative is anticlockwise from the current
            %   position.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.move(200)
            %
            %   See also ARDUINO, ADDON, STARTRUN, STOPRUN, MOVETO

            cmdID = obj.MOVE_STEPPER;

            try
                % Data is send in bytes. Split long up in four bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(int32(relative), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function setMaxSpeed(obj, speed)
            %SETMAXSPEED Sets the maximum permitted speed. The run()
            %function will accelerate up to the speed set by this function.
            %Caution: the maximum speed achievable depends on your
            %processor and clock speed. The default maxSpeed is 1.0 steps
            %per second.
            %   speed: The desired maximum speed in steps per second. Must
            %   be > 0. Caution: Speeds that exceed the maximum speed
            %   supported by the processor may Result in non-linear
            %   accelerations and decelerations.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.setMaxSpeed(200)
            %
            %   See also ARDUINO, ADDON, SETACCELERATION, SETSPEED,
            %   MAXSPEED

            cmdID = obj.SETMAXSPEED_STEPPER;

            try
                % Data is send in bytes. Split float (=single) up in four bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(single(speed), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function val = maxSpeed(obj)
            %MAXSPEED Returns the maximum speed configured for this stepper
            %that was previously set by setMaxSpeed()
            %   val: The currently configured maximum speed
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.maxSpeed()
            %
            %   See also ARDUINO, ADDON, SETMAXSPEED

            cmdID = obj.MAXSPEED_STEPPER;

            try
                val = sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
                % Convert bytes to float (=single)
                val = typecast(uint8(val), 'single');
            catch e
                throwAsCaller(e);
            end
        end

        function setAcceleration(obj, acceleration)
            %SETACCELERATION Sets the acceleration/deceleration rate.
            %   acceleration: The desired acceleration in steps per second
            %   per second. Must be > 0.0. This is an expensive call since
            %   it requires a square root to be calculated. Dont call more
            %   often than needed
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.setAcceleration(200)
            %
            %   See also ARDUINO, ADDON, SETMAXSPEED, SETSPEED,
            %   ACCELERATION

            cmdID = obj.SETACCELERATION_STEPPER;

            try
                % Data is send in bytes. Split float (=single) up in four bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(single(acceleration), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function val = acceleration(obj)
            %ACCELERATION Returns the acceleration/deceleration rate
            %configured for this stepper that was previously set by
            %setAcceleration()
            %   val: The currently configured acceleration/deceleration
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.acceleration()
            %
            %   See also ARDUINO, ADDON, SETACCELERATION

            cmdID = obj.ACCELERATION_STEPPER;

            try
                val = sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
                % Convert bytes to float (=single)
                val = typecast(uint8(val), 'single');
            catch e
                throwAsCaller(e);
            end
        end

        function setSpeed(obj, speed)
            %SETSPEED Sets the desired constant speed for use with
            %runSpeed().
            %   speed: The desired constant speed in steps per second.
            %   Positive is clockwise. Speeds of more than 1000 steps per
            %   second are unreliable. Very slow speeds may be set (eg
            %   0.00027777 for once per hour, approximately. Speed accuracy
            %   depends on the Arduino crystal. Jitter depends on how
            %   frequently you call the runSpeed() function. The speed will
            %   be limited by the current value of setMaxSpeed()
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.setSpeed(200)
            %
            %   See also ARDUINO, ADDON, SETACCELERATION, SETMAXSPEED,
            %   SPEED

            cmdID = obj.SETSPEED_STEPPER;

            try
                % Data is send in bytes. Split float (=single) up in four bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(single(speed), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function val = speed(obj)
            %SPEED The most recently set speed.
            %   val: the most recent speed in steps per second
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.speed()
            %
            %   See also ARDUINO, ADDON, SETSPEED

            cmdID = obj.SPEED_STEPPER;

            try
                val = sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
                % Convert bytes to float (=single)
                val = typecast(uint8(val), 'single');
            catch e
                throwAsCaller(e);
            end
        end

        function val = distanceToGo(obj)
            %DISTANCETOGO The distance from the current position to the
            %target position.
            %   val: the distance from the current position to the target
            %   position in steps. Positive is clockwise from the current
            %   position.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.distanceToGo()
            %
            %   See also ARDUINO, ADDON, MOVE, MOVETO, TARGETPOSITION,
            %   CURRENTPOSITION

            cmdID = obj.DISTANCETOGO_STEPPER;

            try
                val = sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
                % Convert bytes to int32
                val = typecast(uint8(val), 'int32');
            catch e
                throwAsCaller(e);
            end
        end

        function val = targetPosition(obj)
            %TARGETPOSITION The most recently set target position.
            %   val: the target position in steps. Positive is clockwise
            %   from the 0 position.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.targetPosition()
            %
            %   See also ARDUINO, ADDON, MOVE, MOVETO, DISTANCETOGO,
            %   CURRENTPOSITION

            cmdID = obj.TARGETPOSITION_STEPPER;

            try
                val = sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
                % Convert bytes to int32
                val = typecast(uint8(val), 'int32');
            catch e
                throwAsCaller(e);
            end
        end

        function val = currentPosition(obj)
            %CURRENTPOSITION The current motor position.
            %   val: the current motor position in steps. Positive is
            %   clockwise from the 0 position.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.currentPosition()
            %
            %   See also ARDUINO, ADDON, MOVE, MOVETO, DISTANCETOGO,
            %   TARGETPOSITION

            cmdID = obj.CURRENTPOSITION_STEPPER;

            try
                val = sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
                % Convert bytes to int32
                val = typecast(uint8(val), 'int32');
            catch e
                throwAsCaller(e);
            end
        end

        function setCurrentPosition(obj, position)
            %SETCURRENTPOSITION Resets the current position of the motor,
            %so that wherever the motor happens to be right now is
            %considered to be the new 0 position. Useful for setting a zero
            %position on a stepper after an initial hardware positioning
            %move. Has the side effect of setting the current motor speed
            %to 0.
            %   position: The position in steps of wherever the motor
            %   happens to be right now.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.setCurrentPosition(0)
            %
            %   See also ARDUINO, ADDON, CURRENTPOSITION

            cmdID = obj.SETCURRENTPOSITION_STEPPER;

            try
                % Data is send in bytes. Split long up in four bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(int32(position), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function stop(obj)
            %STOP Sets a new target position that causes the stepper to
            %stop as quickly as possible, using the current speed and
            %acceleration parameters.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.stop()
            %
            %   See also ARDUINO, ADDON, STARTRUN, STARTRUNSPEED, STOPRUN

            cmdID = obj.STOP_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
            catch e
                throwAsCaller(e);
            end
        end

        function disableOutputs(obj)
            %DISABLEOUTPUTS Disable motor pin outputs by setting them all
            %LOW
            %   Depending on the design of your electronics this may turn
            %   off the power to the motor coils, saving power. This is
            %   useful to support Arduino low power modes: disable the
            %   outputs during sleep and then reenable with enableOutputs()
            %   before stepping again. If the enable Pin is defined, sets
            %   it to OUTPUT mode and clears the pin to disabled.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.disableOutputs()
            %
            %   See also ARDUINO, ADDON, ENABLEOUTPUTS

            cmdID = obj.DISABLEOUTPUTS_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
            catch e
                throwAsCaller(e);
            end
        end

        function enableOutputs(obj)
            %ENABLEOUTPUTS Enable motor pin outputs by setting the motor
            %pins to OUTPUT mode. Called automatically by the constructor.
            %If the enable Pin is defined, sets it to OUTPUT mode and sets
            %the pin to enabled.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.enableOutputs()
            %
            %   See also ARDUINO, ADDON, DISABLEOUTPUTS

            cmdID = obj.ENABLEOUTPUTS_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
            catch e
                throwAsCaller(e);
            end
        end

        function setMinPulseWidth(obj, minWidth)
            %SETMINPULSEWIDTH Sets the minimum pulse width allowed by the
            %stepper driver. The minimum practical pulse width is
            %approximately 20 microseconds. Times less than 20 microseconds
            %will usually result in 20 microseconds or so.
            %   minWidth: The minimum pulse width in microseconds.
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon','DRIVER',{'D7','D8'})
            %       s.setMinPulseWidth(50)
            %
            %   See also ARDUINO, ADDON

            cmdID = obj.SETMINPULSEWIDTH_STEPPER;

            try
                % Data is send in bytes. Split unsigned int up in two bytes.
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, typecast(uint16(minWidth), 'uint8')]);
            catch e
                throwAsCaller(e);
            end
        end

        function setEnablePin(obj, enablePin)
            %SETENABLEPIN Sets the enable pin number for stepper drivers.
            %'' indicates unused (default). Otherwise, if a pin is set, the
            %pin will be turned on when enableOutputs() is called and
            %switched off when disableOutputs() is called.
            %   enablePin: Arduino digital pin number for motor enable
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.setEnablePin('D10')
            %       s.setEnablePin('')
            %
            %   See also ARDUINO, ADDON, ENABLEOUTPUTS, DISABLEOUTPUTS

            % Check if a pin was already set and handle its cleanup
            if ~isempty(obj.EnablePin)
                % Release the previously configured pin resource
                configurePinResource(obj.Parent, obj.EnablePin, obj.ResourceOwner, 'Unset');
                configurePinResource(obj.Parent, obj.EnablePin, '', 'Unset');
            end

            try
                if ~isempty(enablePin)
                    % Validate Uniqueness of Pin Resource
                    terminal = getTerminalsFromPins(obj.Parent, enablePin);
                    owner = getResourceOwner(obj.Parent, terminal);
                    if ~isempty(owner)
                        error('AccelStepperAddon:AccelStepperAddon:DuplicatePin', 'Arduino pin %s is registered with %s object. Sharing of pin is not supported.', arduinoPin, owner);
                    end

                    % Initialize Property: Arduino Pin
                    if ischar(enablePin) || isstring(enablePin)
                        obj.EnablePin = char(enablePin);
                    else
                        error('AccelStepperAddon:AccelStepperAddon:InvalidPin', 'arduinoPin argument expects a char or string but received %s.', class(arduinoPin));
                    end

                    % Setup the Pin for use
                    configurePinResource(obj.Parent, obj.EnablePin, obj.ResourceOwner, 'DigitalOutput');
                end
                % Create Enable Pin
                createEnablePin(obj);
            catch e
                throwAsCaller(e);
            end
        end

        function setPinsInverted(obj, varargin)
            %SETPINSINVERTED Sets the inversion for stepper driver pins
            %   directionInvert: True for inverted direction pin, false for
            %   non-inverted
            %	stepInvert: True for inverted step pin, false for
            %   non-inverted
            %   enableInvert: True for inverted enable pin, false (default)
            %   for non-inverted
            %
            %SETPINSINVERTED Sets the inversion for 2, 3 and 4 wire stepper
            %pins
            %   pin1Invert: True for inverted pin1, false for non-inverted
            %   pin2Invert: True for inverted pin2, false for non-inverted
            %   pin3Invert: True for inverted pin3, false for non-inverted
            %   pin4Invert: True for inverted pin4, false for non-inverted
            %   enableInvert:True for inverted enable pin, false (default)
            %   for non-inverted
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.setPinsInverted(false, false, false, false, true)
            %
            %   See also ARDUINO, ADDON

            cmdID = obj.SETPINSINVERTED_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, [obj.StepperID, varargin{:}]);
            catch e
                throwAsCaller(e);
            end
        end

        function val = isRunning(obj)
            %ISRUNNING Checks to see if the motor is currently running to a
            %target
            %   val: true if the speed is not zero or not at the target
            %   position
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.isRunning()
            %
            %   See also ARDUINO, ADDON, DISTANCETOGO

            cmdID = obj.ISRUNNING_STEPPER;

            try
                val = logical(sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID));
            catch e
                throwAsCaller(e);
            end
        end

        function startrun(obj)
            %STARTRUN Starts the stepping in 'run()' mode
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.startrun()
            %
            %   See also ARDUINO, ADDON, STOP, STARTRUNSPEED, STOPRUN

            cmdID = obj.STARTRUN_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
            catch e
                throwAsCaller(e);
            end
        end

        function startrunSpeed(obj)
            %STARTRUNSPEED Starts the stepping in 'runSpeed()' mode
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.startrunSpeed()
            %
            %   See also ARDUINO, ADDON, STOP, STARTRUN, STOPRUN

            cmdID = obj.STARTRUNSPEED_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
            catch e
                throwAsCaller(e);
            end
        end

        function stoprun(obj)
            %STOPRUN Stops the 'run()' and 'runSpeed()' stepping modes
            %
            %   Example:
            %       a = arduino('COM5', 'ProMini328_5V','Libraries',{'AccelStepperAddon/AccelStepperAddon'},'Traceon',true,'ForceBuildOn',true)
            %       s = addon(a,'AccelStepperAddon/AccelStepperAddon',{'D2','D3','D4','D5'})
            %       s.stop()
            %
            %   See also ARDUINO, ADDON, STARTRUN, STARTRUNSPEED

            cmdID = obj.STOPRUN_STEPPER;

            try
                sendCommand(obj, obj.LibraryName, cmdID, obj.StepperID);
            catch e
                throwAsCaller(e);
            end
        end
    end

    methods (Access = protected)
        function displayScalarObject(obj)
            % Format for printing AccelStepperAddon Object.

            header = getHeader(obj);
            disp(header);

            % Display main options
            fprintf('          Pins: %s %s %s %s\n', obj.Pins{:});
            fprintf('\n');

            % Allow for the possibility of a footer.
            footer = getFooter(obj);
            if ~isempty(footer)
                disp(footer);
            end
        end
    end
end