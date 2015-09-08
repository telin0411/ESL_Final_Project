{{PropBOE-Bot Servo Drive.spin

See end of file for author, version, copyright and
terms of use.

Summary
  Methods that simplify and automate PropBOE-Bot
  navigation.

Features
  • Supports basic navigation with wheels method
  • Has methods for setting directions and executing
    maneuvers and sequences of maneuvers from lists
    in a DAT block.
  • Can execute sequences independently from another
    cog to free up your code for sensor measurements
    and processing.
  • Default servo signals are P14 to Left servo and
    P15 to right servo.
  • Servo signals configurable with ServoPins method.    
  • Background speed ramping configurable with
    RampStep Method.
  • Has DAT block that can be adjusted for straight
    ahead travel in three modes: 0 No Compensation
    2 Exact Match, or 3 Linear Interpolation

Cog Usage
  • Launches a cog to maintain servo signals.
  • Launches a second cog for calls to StartSequence,
    but only for the duration of the sequence.

}}
OBJ
                                                        
  servo  : "PropBOE Servos"                                ' Servo control object
  time   : "Timing"                                        ' Timekeeping and delay object
  fp     : "FloatMath"
  
DAT
  '' Default PropBOE-Bot servo connections.  You can adjust
  '' these values inside this object's DAT block if you are
  '' using different I/O pins for your PropBOE-Bot drive servos.
  ''
  ioLeft          long  14         ''ioLeft          long  14                                 
  ioRight         long  15         ''ioRight         long  15         

  '' When the servos get the "stay still" signal, this object
  '' stops sending control signals to the servos during that
  '' time by default.  If you want the object to continue sending
  '' the stay still signal, change the stopToSleep DAT entry from
  '' true to false.
  '' 
  stopToSleep     long  true       ''stopToSleep     long  true

  '' Adjust the following variables in this object's DAT block
  '' after you have figured out what left and right wheel speeds
  '' for straight forward and backward.
  ''
  '' Mode Values:
  ''    0 - No Compensation
  ''        This list is not used.
  ''    1 - Exact Match
  ''        If for any call that sets both wheel sppeds and they
  ''        are identical to each other and match a value in the
  ''        targetSpeeds list, this object will substitute
  ''        corresponding entries in the leftSpeeds and rightSpeeds
  ''        rows.
  ''    2 - Linear Interpolation
  ''        Any call to a method that sets the wheels to the same
  ''        speeds will use this table.  If it's not an exact match,
  ''        for an entry in the targetSpeeds list, this object will
  ''        will use linear interpolation to come up with the best
  ''        value.  For best results, you may need to double or triple
  ''        the number of entries in this list.
  ''
  mode            long    0
  speedCnt        long    9
  targetSpeeds    long -100, -75, -50, -25, -0,  25,  50,  75,  100
  leftSpeeds      long -100, -75, -50, -25, -0,  25,  50,  75,  100 
  rightSpeeds     long -100, -75, -50, -25, -0,  25,  50,  75,  100 

VAR

  long speedVal, turnVal, leftVal, rightVal, duration
  long cog, stack[64] 

PUB Wheels(left, right)
{{Set speeds for both wheels independently.  Each
wheel can be controlled with a parameter values from
100 for full speed forward to -100 for full speed
backward.

Parameters
  left   - Left wheel speed from 100 (full speed
           forward to -100 (full speed backward) 
  right  - Right wheel speed from 100 (full speed
           forward to -100 (full speed backward)

''Wheels Example
OBJ
  system : "Propeller Board of Education"
  beep   : "PropBoE Square Wave"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)  ' System clock 80 MHz
  beep.Out(4, 1000, 3000)   ' P4, 1 s, 3 kHz tone
  drive.Wheels(100, 100)    ' Full speed forward
  time.Pause(2000)          ' ..for 2 seconds
  drive.Wheels(50, -50)     ' Rotate right half speed
  time.Pause(2000)          ' ..for 2 seconds
  drive.Wheels(0, 0)        ' Stop            
}}

  case mode
    1: Match(@left, @right)
    2: left := Interpolate(left, @leftSpeeds)
       right := Interpolate(right, @rightSpeeds)

  servo.Set(ioLeft, left)                                  ' Set left servo rotation
  servo.Set(ioRight, -right)                               ' Set right servo rotation*
  longmove(@leftVal, @left, 2)                             ' Update global variable values
'  WheelsToHeading
  if stopToSleep == true
    if left == 0 and right == 0                            ' If stopped, stop control signals
      Sleep
     
  '* Right servo rotation is multiplied by -1 to translate a call of two positive
  '  values for forward motion to two opposite directions of rotation, which is what
  '  actually results in positive motion.  

PUB Go(lrSpeedAddr)
{{Set wheel speeds according to two longs in either a
DAT block or variable array.  The first long contains
the left wheel speed and the second contains the right
wheel speed.  

Parameters
  lrSpeedAddr - Address of two longs, the first of
                which contains the left wheel speed
                and the second contains the right
                wheel speed.

''Go Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

DAT             'left  right
  forward  long   100,   100      ' Servo control values 
  backward long  -100,  -100

PUB Main
  system.Clock(80_000_000)   ' System clock 80 MHz
  drive.Go(@forward)         ' Full speed forward
  time.Pause(2000)           ' ...for 2 seconds
  drive.Go(@backward)        ' Full speed backward
  time.Pause(2000)           ' ...for 2 seconds
  drive.Sleep                ' Stop servo control 
}}

  longmove(@leftVal, lrSpeedAddr, 2)                       ' Update global values with new speeds
  Wheels(leftVal, rightVal)                                ' Update wheel speeds

PUB Maneuver(maneuverAddr) | i
{{Execute a maneuver with long values stored in either
a DAT block or variable array.   

Parameters
  maneuverAddr  - Starting address of longs in either
                  a DAT block or variable array that
                  contain vales for: left speed, right
                  speed, and duration.
                  
''Maneuver Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"

DAT
  '                left   right    time
  forward   long    100,    100,   2000
  backward  long   -100,   -100,   2000
  pivot_R   long      0,    100,   3000

PUB Main
  system.Clock(80_000_000)   ' System clock 80 MHz
  drive.Maneuver(@forward)
  drive.Maneuver(@pivot_R)
  drive.Maneuver(@backward)
  drive.Sleep
}}

  longmove(@leftVal, maneuverAddr, 2)                      ' Update global values with new speeds
  Wheels(long[maneuverAddr][0], long[maneuverAddr][1])     ' Update wheel speeds
  time.Pause(long[maneuverAddr][2])                        ' Pause for duration of maneuver

PUB Sequence(listAddr) | base, i, left, right, ms, temp

{{Execute a sequence of maneuvers with long values
stored in either a DAT block or variable array.   

Parameters
  addr  - Starting address of longs in either a DAT
          block or variable array that contain a
          list of addresses of maneuvers.  Each
          maneuver is three longs containing left
          and right servo speeds and the number of
          milliseconds to execute the maneuver.
          The list of maneuver addresses must start
          with its own address and end with -1. The
          values in between are addresses to maneuvers.
                  
''Sequence Example
  OBJ
    system : "Propeller Board of Education"
    drive  : "PropBOE-Bot Servo Drive"

  DAT
    '                left   right    time
    forward   long    100,    100,   2000
    backward  long   -100,   -100,   2000
    left90    long   -100,    100,   600
    right90   long    100,   -100,   600

    flrb      long   @flrb, @forward, @left90
              long   @right90, @backward, -1

  PUB Main
    system.Clock(80_000_000)
    drive.Sequence(@flrb)
    drive.Sleep
}}
   
  base := listAddr - long[listAddr]                        ' base = object starting address
  i := 1                                                   ' Initialize local variable
  repeat                                                   ' Loop
    longmove(@left, base + long[listAddr][i], 3)           ' Copy Maneuver elements to local vars*
    if (temp := long[listAddr][i]) < 0                     ' If element at listAddr is -1
      quit                                                 ' ..it means no more maneuvers so quit
    i++                                                    ' Increment index
    Wheels(left, right)                                    ' Call wheels method
    time.Pause(ms)                                         ' Pause till maneuver is done

'' * Must add base to the address of the maneuver within the object because those addresses are
''   generated at compile time and only indicate their offset from the start of the object.

PUB StartSequence(listAddr) : success
{{Use another cog to execute a sequence of maneuvers
with long values stored in either a DAT block or
variable array.  Frees your program to perform other
tasks while the PropBOE-Bot executes the sequence
of maneuvers.

This method uses another cog for the duration of the
sequence of maneuvers.
   
The sequence can be interrupted (and its cog stopped)
at any time by calling the StopSequence method.


Parameters
  addr  - Starting address of longs in either a DAT
          block or variable array that contain a
          list of addresses of maneuvers.  Each
          maneuver is three longs containing left
          and right servo speeds and the number of
          milliseconds to execute the maneuver.
          The list of maneuver addresses must start
          with its own address and end with -1. The
          values in between are addresses to maneuvers.
                  
Returns
  success       - Nonzero if cog was available,
                  zero if no cog available.                     
                  
''StartSequence Example
''Plays music while executing the navigation sequence
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  beep   : "PropBOE Square Wave"
  time   : "Timing"

DAT
  '                left   right    time
  forward   long    100,    100,   2000
  backward  long   -100,   -100,   2000
  left90    long   -100,    100,   600
  right90   long    100,   -100,   600
  stop      long      0,      0,     0

  flrb      long   @flrb, @forward, @left90
            long   @right90, @backward, @stop, -1

PUB Main | index, tone
  system.Clock(80_000_000)
  beep.Out(4, 1000, 3000)  
  drive.StartSequence(@flrb)
  repeat index from 1 to 8
    tone := lookup(index : 1047, 1175, 1319, 1396,{
                  }1568, 1760, 1976, 2093)
    beep.Out(4, 250, tone)
    time.Pause(250)
  time.pause(2000)  
  drive.sleep  
}}

  ' Pass SetForget method call to new cog and return nonzero if cog was available
  ' zero if no cog available.
  success := cog := cognew(SetForget(listAddr), @stack) + 1
  
PRI SetForget(listAddr)

  Sequence(listAddr)                                       ' Call sequence method
  cogstop(cog - 1)                                         ' Stop cog when done

  
PUB StopSequence
{{Allows you to stop the maneuver being executed by
the cog that the StartSequence method lunched.
}}

  cogstop(cog - 1)                                         ' Remember to subtract one
                                                           ' since Start added one.

PUB Sleep
{{Disable servo signals.  A call to Wake will restore
the control signals to the servos, effectively waking
them back up.  A call to any of the servo control
methods (Wheels, Go, Maneuver, Sequence, etc.) will
also wake the servos back up.

Since servos sometimes drift out of adjustment for
their "stay still" control signal, this method ensures
that the PropBOE-Bot will not roll somewhere slowly
over time when it's supposed to stay still.

''Sleep Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)  ' System clock 80 MHz
  drive.Wheels(100, 100)    ' Full speed forward
  time.Pause(2000)          ' ..for 2 seconds
  drive.Sleep               ' Stop motion
  time.Pause(1000)          ' ..for 1 second
  drive.Wake                ' Resume motion
  time.Pause(2000)          ' ..for 2 seconds
  drive.Sleep               ' Stop again
}}

  servo.Disable(ioLeft)                                    ' Halt servo signals
  servo.Disable(ioRight)

PUB Wake
{{Enables servo control signal after it has been
disabled with a call to Sleep.

Example - See Sleep Example in Sleep method
          documentation.

}}

  servo.Enable(ioLeft)                                     ' Resume servo signals.
  servo.Enable(ioRight)
  
PUB ServoPins(left, right)
{{Tells this object which I/O pins the PropBOE-Bot's
two drive wheels are connected to.  You only need to
call this method if you are not using the default
left servo P14 and right servo P15 connections.

Parameters:
  left  - I/O pin connected to the left servo
  right - I/O pin connected to the right servo

Default Values:
If you do not call this method, this object defaults
to P14 for the left servo and P15 for the right.

'' ServoPins Example
'' Try changing the servos to different
'' ports and updating with this method.  Then,
'' run this test code again and verify that it
'' still works correctly.  Make sure to reconnect
'' the left servo to P14 and the right servo to )15
'' before trying the other code examples in this  
'' object.

OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)
  ' Left servo to P14, right servo to P15.
  drive.ServoPins(14, 15)
  drive.Wheels(100, 100)    ' Full speed forward
  time.Pause(2000)          ' ..for 2 seconds
  drive.Wheels(0, 0)        ' Stop
}}
  ioLeft := left                                           ' Update pin values in DAT variables
  ioRight := right

PUB RampStep(left, right)
{{Configures the PropBOE-Bot's maximum speed change
per 50th of a second.  After a call to this method
the object overrides any abrupt speed changes with
gradual ones that step toward the target speed you
have set.

This is useful for applications that cannot afford
abrupt changes, such as if the PropBOE-Bot is towing
a payload that might tip over with a sudden speed
change.  

Parameters:
  left  - Maximum speed change per 50th of a second
          for left servo.
  right - Maximum speed change per 50th of a second
          for right servo.

Default Values:
The default is 2000, which is ten times want you
need to go from full speed counterclockwise (100)
to full speed clockwise (-100).  If you were to
specify a RampStep of 20, it would step through
the same speed change over 10/50ths of a second,
which would smooth the direction change slightly.

''RampStep Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)  ' System clock -> 80 MHz
  ' Configure for sssslllloooowwww responses.
  drive.RampStep(2, 2)      
  drive.Wheels(100, 100)    ' Full speed forward
  time.Pause(3000)          ' 1 s to speed up 2 s run
  drive.Wheels(-100, -100)  ' 3 s run, 1 s to speed up 
  time.Pause(3000)          ' 2 s to speed up 1 s run 
  drive.Wheels(0, 0)        ' Stop
                            ' Takes 1 s to slow down
                            ' and stop
}}

  ifnot servo.Status                                       ' Launch servo process if not already
    wheels(0, 0)                                           ' Stop wheels
  servo.StepSize(ioLeft, left)                             ' Set step sizes for each servo.
  servo.StepSize(ioRight, right)

PRI Match(leftAddr, rightAddr) | i

  repeat i from speedCnt - 1 to 0 
    if long[leftAddr] == targetSpeeds[i] and long[rightAddr] == targetSpeeds[i]  
      long[leftAddr] := leftSpeeds[i]
      long[rightAddr] := rightSpeeds[i]
      quit

PRI Interpolate(val, addr) : newVal | i, num, den, frac, den2

  i     := FindTarget(val)

  if i == speedCnt - 1
    newVal := long[addr][i]
    return
  num   := fp.FFloat(val - targetSpeeds[i])
  den   := fp.FFloat(targetSpeeds[i+1] - targetSpeeds[i])
  frac  := fp.FDiv(num, den)
  den2  := fp.FFloat(long[addr][i+1] - long[addr][i])
  newVal := fp.FMul(frac, den2)
  newVal := fp.FRound(newVal)
  newVal := fp.FRound(newVal) + long[addr][i]

PRI FindTarget(val) : i

  repeat i from 0 to speedCnt - 2
    if val => targetSpeeds[i] and val < targetSpeeds[i + 1]
      quit
{

''Debugging methods

OBJ
                                                        
  fss    : "FloatString"
  pst    : "Parallax Serial Terminal Plus"

PRI DisplayDec(strAddr, value, formatChar)

  pst.Str(strAddr)
  pst.Dec(value)
  pst.Char(formatChar)

PRI DisplayFloat(strAddr, valueStrAddr, formatChar)

  pst.Str(strAddr)
  pst.Str(valueStrAddr)
  pst.Char(formatChar)
}

{

''Heading maethods that worked okay, but not great.

 
PUB Heading(speed, turn) | speedLeft, speedRight
{{Sets the speeds for both wheels to achieve a heading
defined by forward/backward speed and right/left turn.

Parameters
  speed - Forward/backward speed from 100 (full speed
          forward) to -100 (full speed backward). 
  turn  - Right/left turn value from 100 (rotate in
          place to the right) to -100 (rotate in place
          to he left.

''Heading Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)
  ' All full speed forward, zero turn
  drive.Heading(100, 0)
  time.Pause(2000)            ' ..for 2 seconds
  drive.Heading(0, 0)         ' Stop
}}

  turn #>= - || speed                                      ' Keep turn below absolute value of speed
  turn <#=   || speed 

  speedLeft  :=   speed                                    ' Account for drive wheels turning opposite directions
  speedRight := - speed

  if speed > 0                                             ' Convert speed & turn to left & right wheel speeds
    if turn > 0
      speedRight := speedRight + (2 * turn)
    elseif turn < 0
      speedLeft := speedLeft + (2 * turn)
  elseif speed < 0
    if turn > 0
      speedRight := speedRight - (2 * turn)
    elseif turn < 0
      speedLeft := speedLeft - (2 * turn)
     
  wheels(speedLeft, -speedright)                           ' Set left/right wheel speeds

  longmove(@speedVal, @speed, 4)                           ' Update global speed variables.

PUB SetSpeed(speed)
{{Set the heading speed independently of the turn
value.

Parameters
  speed - Speed heading from 100 (full speed forward)
          to -100 (full speed backward).

''SetSpeed Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)
  ' All full speed forward, zero turn
  drive.Heading(100, 0)
  time.Pause(2000)            ' ..for 2 seconds
  drive.SetSpeed(50)          ' Reduce to half speed
  time.Pause(2000)            ' ..for 2 seconds
  drive.SetSpeed(0)           ' Stop         
}}

  speedVal := speed                                        ' Update global speed variable
  Heading(speedVal, turnVal)                               ' Call heading to update speed/turn 

PUB SetTurn(turn)
{{Set the heading turn independently of the speed
value.

Parameters
  turn - Turn heading from 100 (rotate in place to
         the right) to -100 (rotate in place to the
         left).

''SetTurn Example
OBJ
  system : "Propeller Board of Education"
  drive  : "PropBOE-Bot Servo Drive"
  time   : "Timing"

PUB Main
  system.Clock(80_000_000)
  ' All full speed forward, zero turn
  drive.Heading(100, 0)   ' Full speed forward
  time.Pause(2000)        ' ..for 2 seconds
  drive.SetTurn(-100)     ' Turn left in place 
  time.Pause(1000)        ' ..for 1 second
  drive.Heading(0, 0)     ' Full speed forward
}}

  turnVal := turn                                          ' Update global turn variable  
  Heading(speedVal, turnVal)                               ' Call heading to update speed/turn
   
CON
                                                           ' Constants for WheelsToHeading
  FORWARD  =  1
  ROTATE   =  0
  BACKWARD = -1

VAR

  long direction                                           ' Variable for WheelsToHeading

PRI WheelsToHeading                                        ' Converts wheel speed to heading and    
                                                           ' updates global variable.
  if leftVal > rightVal                                    
    direction := FORWARD
  elseif leftVal < rightVal
    direction := BACKWARD
  else
    direction := ROTATE

  if     || leftVal > || rightVal
    speedVal := leftVal
  elseif || leftVAl < || rightVal
    speedVal := rightVal
  else
    speedVal := leftVal  

  turnVal := (leftVal + rightVal) / 2
  if direction == BACKWARD
    turnVal -= turnVal
}
{
  left  := FitToScale(left, fsFLeft, fsBLeft, stopLeft)
  right := FitToScale(right, fsFRight, fsBRight, stopRight)

PRI FitToScale(val, fsF, fsB, stop) : scaleVal | y, m, x, b, fs, denominator

  ' Use full speed and stop DAT values to correct each wheel speed 

  if val => stop                                           ' If val is positive
    fs := fp.FFloat(fsF)                                   ' then pick fsF
    denominator := 100.0                                   ' and 100.0 will divide into it for m
  else                                                     ' else if negative
    fs := fp.FFloat(fsB)                                   ' then pick fsB
    denominator := -100.0                                  ' and -100.0 will divide into it for m

  b := fp.FFloat(stop)                                     ' b is always stop
  m := fp.FDiv(fp.FSub(fs, b), denominator)                ' calculate m
  x := fp.FFloat(val)                                      ' set x eqaul to val
  y := fp.FAdd(fp.FMul(x, m), b)                           ' calculate y = mx + b
  
  scaleVal := fp.FRound(y)                                 ' scaleVal is the y result

}

DAT
{{
File: PropBOE-Bot Servo Drive.Spin
Date: 2011.11.02
Version: 0.89
Author: Andy Lindsay

Copyright (c) 2011 Parallax, Inc.

┌────────────────────────────────────────────┐
│TERMS OF USE: MIT License                   │
├────────────────────────────────────────────┤
│Permission is hereby granted, free of       │
│charge, to any person obtaining a copy      │
│of this software and associated             │
│documentation files (the "Software"),       │
│to deal in the Software without             │
│restriction, including without limitation   │
│the rights to use, copy, modify,merge,      │
│publish, distribute, sublicense, and/or     │
│sell copies of the Software, and to permit  │
│persons to whom the Software is furnished   │
│to do so, subject to the following          │
│conditions:                                 │
│                                            │
│The above copyright notice and this         │
│permission notice shall be included in all  │
│copies or substantial portions of the       │
│Software.                                   │
│                                            │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT   │
│WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES │
│OF MERCHANTABILITY, FITNESS FOR A           │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN  │
│NO EVENT SHALL THE AUTHORS OR COPYRIGHT     │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR │
│OTHER LIABILITY, WHETHER IN AN ACTION OF    │
│CONTRACT, TORT OR OTHERWISE, ARISING FROM,  │
│OUT OF OR IN CONNECTION WITH THE SOFTWARE   │
│OR THE USE OR OTHER DEALINGS IN THE         │
│SOFTWARE.                                   │
└────────────────────────────────────────────┘
}}