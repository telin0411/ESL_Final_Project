{{2 Test IR Object Detectors with LEDs.spin

R1 LED lights if left IR object detector sees object.
G0 LED lights if right IR object detector sees object.
}}                                                

OBJ

  system : "Propeller Board of Education"             ' System configuration
  freq   : "PropBOE Square Wave"                      ' Square wave signal generator
  ir     : "PropBOE IR Detect"                        ' IR object detection 
  pin    : "Input Output Pins"                        ' I/O pin convenience methods
  time   : "Timing"                                   ' Delay and wait convenience methods
  
VAR

  byte objectL, objectR                               ' Variables to store results

PUB Go                                                ' Startup method

  system.Clock(80_000_000)                            ' System clock -> 80 MHz
  freq.Out(4, 1000, 3000)                             ' P4 sends 1 s, 3 kHz tone to speaker
  
  repeat                                              ' Main loop repeats indefinitely
    objectL := ir.Detect(13, 12)                      ' Check for left object
    objectR := ir.Detect(0, 1)                        ' Check for right object

    pin.Out(10, objectL)                              ' Left object -> left LED
    pin.Out(8, objectR)                               ' right object -> right LED
    
    time.Pause(20)                                    ' Wait 20 ms & try again
    