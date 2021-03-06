'' 3 Roaming PropBOE-Bot.spin
'' Use IR LED and IR receiver to detect object presence/distance.

OBJ

  system : "Propeller Board of Education"             ' System configuration
  freq   : "PropBOE Square Wave"                      ' Square wave signal generator
  ir     : "PropBOE IR Detect"                        ' IR object detection 
  drive  : "PropBOE-Bot Servo Drive"                  ' Propeller Boe-Bot servo control
  time   : "Timing"                                   ' Delay and wait convenience methods
  
VAR

  byte objectL, objectR                               ' Variables to store results

PUB Go                                                ' Startup method

  system.Clock(80_000_000)                            ' System clock -> 80 MHz
  freq.Out(4, 1000, 3000)                             ' P4 sends 1 s, 3 kHz tone to speaker
  
  repeat                                              ' Main loop repeats indefinitely
    objectL := ir.Detect(13, 12)                      ' Check for left object
    objectR := ir.Detect(0, 1)                        ' Check for right object

    if objectL == 0 and objectR == 0                  ' If no objects detected
      drive.Wheels(100, 100)                          ' ...go forward
    elseif objectL == 1 and objectR == 1              ' If both sensors detect objects
      drive.Wheels(-100, -100)                        ' ...back up
    elseif objectR == 1                               ' If only right detects
      drive.Wheels(-100, 100)                         ' ...turn left
    elseif objectL == 1                               ' If only left detects
      drive.Wheels(100, -100)                         ' ...turn right

    time.Pause(20)                                    ' Wait 20 ms & before repeating loop      

