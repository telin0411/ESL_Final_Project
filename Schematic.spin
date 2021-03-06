{{
Parts List                Schematic                                                  
─────────────────────     ──────────────────────────────────────────────────────────
                                                   Left Side
                                  IR Transmitter                IR Receiver
                                  
(1) Resistor 1 kΩ                                                      +5V             
(1) Resistor 10 kΩ                                                                    
(1) IR LED                                                              │  ┌┐          
(1) IR detector                                                         └──┤│          
(1) LED shield             P13 ───────────── DA1            10 kΩ ┌──┤│‣         
(1) LED standoff                  1 kΩ    IRLED            P12 ──────┼──┤│          
(misc) Jumper wires                                                     │  └┘          
                                                                           PNA4602                                                         
                                                                       GND   or          
                                                                            equivalent  

                                                   Right Side

                                  IR Transmitter                IR Receiver
                                  
                                                                       +5V             
                                                                                      
                                                                        │  ┌┐          
                                                                        └──┤│          
                            P0 ───────────── DA1            10 kΩ ┌──┤│‣         
                                  1 kΩ    IRLED             P1 ──────┼──┤│          
                                                                        │  └┘          
                                                                           PNA4602                                                         
                                                                       GND   or          
                                                                            equivalent  
─────────────────────     ──────────────────────────────────────────────────────────
}}
PUB Schematic
