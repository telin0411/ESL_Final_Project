OBJ 

  pst     : "FullDuplexSerial"
  MM2125  : "Memsic2125"

CON 

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  xIn = 0
  yIn = 1

PUB Go | x,y

  pst.start(31, 30, 0, 115200) 
  MM2125.start(xIn, yIn)        ' Initialize Memsic 2125
   
  repeat
    x := MM2125.Mx		  ' Read X axis
    y := MM2125.My		  ' Read Y axis
     
    pst.dec(x / 100)		  ' Display X axis, divided by 100
    pst.tx(9)                   ' Tab
    pst.dec(y / 100)            ' Display Y axis, divided by 100
    pst.tx(13)                  ' New line
    WaitCnt(ClkFreq / 2 + Cnt)
