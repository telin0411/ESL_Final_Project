'' 4 Test IR Distance Detectors with PST.spin

'' Use IR LED and IR receiver to detect object distance.
'' Display results in Parallax Serial Terminal

OBJ

  system : "Propeller Board of Education"             ' System configuration
  freq   : "PropBOE Square Wave"                      ' Square wave signal generator
  ir     : "PropBOE IR Detect"                        ' IR object detection 
  pst    : "Parallax Serial Terminal Plus"            ' Serial communication object
  time   : "Timing"                                   ' Delay and wait convenience methods
  
VAR

  byte distanceL, distanceR                           ' Variables to store results

PUB Go                                                ' Startup method

  system.Clock(80_000_000)                            ' System clock -> 80 MHz
  freq.Out(4, 1000, 3000)                             ' P4 sends 1 s, 3 kHz tone to speaker
  
  repeat                                              ' Main loop repeats indefinitely
    distanceL := ir.Distance(13, 12)                  ' Check for left object
    distanceR := ir.Distance(0, 1)                    ' Check for right object
    
    Display                                           ' Call display method (below)
    time.Pause(20)                                    ' Wait 20 ms before repeating  

PUB Display                                           ' Display method for IR detectors

  pst.Home                                            ' Send cursor home (top-left)         
  pst.Str(string("distanceL = "))                     ' Display "objectL = "
  pst.Dec(distanceL)                                  ' Display objectL value
  pst.ClearEnd                                        ' Remove any phantom digits
  pst.Str(string("  distanceR = "))                   ' Display "objectL = "
  pst.Dec(distanceR)                                  ' Display objectL value
  