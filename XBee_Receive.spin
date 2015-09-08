OBJ

  system : "Propeller Board of Education"              ' PropBOE configuration tools
  pst    : "Parallax Serial Terminal Plus"             ' Terminal communication tools
  time   : "Timing"                                    ' Timing convenience methods
  xb     : "XBee_Object"                             ' XBee communication methods

PUB Go | c, ack

  system.Clock(80_000_000)                             ' System clock -> 80 MHz

  pst.Start(115_200)                                   ' Start Parallax Serial Terminal

  xb.start(0,1,0,9600)                                 ' Propeller Comms - RX,TX, Mode, Baud
  xb.AT_Init                                           ' Initialize for fast AT command use - 5 second delay to perform
  xb.AT_ConfigVal(string("ATMY"), 0)                   ' Set MY address 
  xb.AT_ConfigVal(String("ATDL"), 0)                   ' Set Destination Low address
                                                         
  repeat                                               ' Main loop
    c := xb.rxCheck                                    ' Check buffer
    if c <> -1                                         ' If it's not empty (-1)
      pst.Char(c)                                      ' Then display the character
                                           ' Wait half a second
        xb.str(string("XBee2: got '"))                        ' Send a string
        xb.tx(c)
        xb.str(string("'", 13))


      


      