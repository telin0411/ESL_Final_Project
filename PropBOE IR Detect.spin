{{Test IR Object Detection.spin
Detect 38 kHz IR signal if it reflects off an object.

Parts List                Schematic                                                  
─────────────────────     ──────────────────────────────────────────────────────────
                                                   Left Side
                                  IR Transmitter                IR Receiver
                                  
(1) Resistor 1 kΩ                                                      +5V             
(1) Resistor 10 kΩ                                                                    
(1) IR LED            irLedPin ───────────── DA0                  │  ┌┐          
(1) IR detector                   1 kΩ    IRLED                         └──┤│          
(1) LED shield                                                    10 kΩ ┌──┤│‣         
(1) LED standoff                                   irDetectPin ──────┼──┤│          
(misc) Jumper wires                                                     │  └┘          
                                                                           PNA4602                                                         
                                                                       GND   or          
                                                                            equivalent  

─────────────────────     ──────────────────────────────────────────────────────────
}}                                                

OBJ

  pin    : "Input Output Pins"
  time   : "Timing"
  sqw    : "PropBOE Square Wave"                 ' Square wave object
  dac    : "PropBOE Dac"

PUB Detect(irLedPin, irDetectPin) : objectDetected

  pin.Low(irLedPin)
  time.Pause(2)
  dac.Out(1, 0)
  sqw.Set(irLedPin, 0, 38000)                        ' IR LED flicker at 38 kHz
  time.Pause(1)                                      ' Wait 1 ms
  objectDetected := (!pin.In(irDetectPin))&1             ' Check IR receiver
  sqw.Set(irLedPin, 0, 0)                            ' Turn off IR LED
  
PUB Distance(irLedPin, irDetectPin) : objectDistance | v

  objectDistance := 0
  pin.Low(irLedPin)
  time.Pause(2)
  repeat v from 0 to 148 step 16
    dac.out(1, v)
    sqw.Set(irLedPin, 0, 38000)                      ' IR LED flicker at 38 kHz
    time.Pause(1)                                    ' Wait 1 ms
    objectDistance += pin.In(12)                     ' Check IR receiver
    sqw.Set(irLedPin, 0, 0)                          ' Turn off IR LED
   