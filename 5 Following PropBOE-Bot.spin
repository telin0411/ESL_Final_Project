''5 Following PropBOE-Bot.spin
''Use IR LED and IR receiver to detect object presence/distance.                                                   

OBJ

  system : "Propeller Board of Education"             ' System configuration
  freq   : "PropBOE Square Wave"                      ' Square wave signal generator
  ir     : "PropBOE IR Detect"                        ' IR object detection 
  drive  : "PropBOE-Bot Servo Drive"                  ' Propeller Boe-Bot servo control
  time   : "Timing"                                   ' Delay and wait convenience methods
  
VAR

  byte distanceL, distanceR                           ' Variables to store results
  long speedL, speedR                                 ' Signed variables for speed calcs

PUB Go                                                ' Startup method

  system.Clock(80_000_000)                            ' System clock -> 80 MHz
  freq.Out(4, 1000, 3000)                             ' P4 sends 1 s, 3 kHz tone to speaker
  
  repeat                                              ' Main loop repeats indefinitely
    distanceL := ir.Distance(13, 12)                  ' Check for left object
    distanceR := ir.Distance(0, 1)                    ' Check for right object

    speedL := distanceL * 20 - 100                    ' Calculate left wheel speed
    speedR := distanceR * 20 - 100                    ' Calculate right wheel speed

    drive.Wheels(speedL, speedR)                      ' Set wheel speeds

    time.Pause(20)                                    ' Wait 20 ms & before repeating loop
    