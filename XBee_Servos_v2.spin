'' 1 Wheels Example Forward Backward.spin

'' PropBOE-Bot goes forward for two seconds, then
'' for two seconds, then stops.  

CON
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  ' Set pins and Baud rate for XBee comms  
  XB_Rx     = 0    ' XBee DOUT
  XB_Tx     = 1    ' XBee DIN
  XB_Baud   = 9600 ' XBee Baud Rate
  sound_port    = 26
  CR = 13         ' Carriage Return
  xIn = 5
  yIn = 6

OBJ
   XB     : "XBee_Object"
   system : "Propeller Board of Education"
   voice  : "talk"                                       ' Phil Pilgrim's Phonemic Voice Synth       
   drive  : "PropBOE-Bot Servo Drive"
   time   : "Timing"
   t      : "talk"
   freq   : "PropBOE Square Wave"                      ' Square wave signal generator
   ir     : "PropBOE IR Detect"                        ' IR object detection
   pst     : "FullDuplexSerial"
   MM2125  : "Memsic2125"
   pin  : "Input Output Pins" 
VAR

  byte distanceL, distanceR                           ' Variables to store results
  long speedL, speedR, average, i, aspeedL, aspeedR                                 ' Signed variables for speed calcs
  long stack[90]                    'Establish working space
Pub  Start | DataIn,x,y  

  system.Clock(80_000_000)
  freq.Out(4, 1000, 3000)                             ' P4 sends 1 s, 3 kHz tone to speaker
  
  XB.Delay(2000)
  XB.start(XB_Rx, XB_Tx, 0, XB_Baud) ' Initialize comms for XBee
  XB.Delay(1000)                     ' One second delay
  
  speedL:=20
  speedR:=20
  aspeedL:= -1 * speedL
  aspeedR:= -1 * speedR
  pst.start(31, 30, 0, 115200) 
  MM2125.start(xIn, yIn)        ' Initialize Memsic 2125

  repeat 
    DataIn := XB.RxCheck                   ' Accept action
    x := MM2125.Mx                ' Read X axis
    y := MM2125.My                ' Read Y axis
    pst.dec(x / 100)              ' Display X axis, divided by 100
    pst.tx(9)                   ' Tab
    pst.dec(y / 100)            ' Display Y axis, divided by 100
    pst.tx(13)                  ' New line
    WaitCnt(ClkFreq / 2 + Cnt)
    if DataIn <> -1    
      case DataIn  
        "F","f": XB.str(string(CR,"Forward "))
           'drive.Wheels(speedL,speedR) ' Full speed forwar
           repeat i from 0 to 20                                       ' Main loop repeats indefinitely
             distanceL := ir.Distance(13, 12)                  ' Check for left object
             distanceR := ir.Distance(3, 2)                    ' Check for right object
             average := (distanceL + distanceR) / 2
             DataIn := XB.RxCheck                   ' Accept action
             x := MM2125.Mx                ' Read X axis
             y := MM2125.My                ' Read Y axis
             pst.dec(x / 100)              ' Display X axis, divided by 100
             pst.tx(9)                   ' Tab
             pst.dec(y / 100)            ' Display Y axis, divided by 100
             pst.tx(13)                  ' New line
             
             if average < 7
              system.Clock(80_000_000)                             ' Propeller system clock -> 80 MHz
              voice.start(26)                                      ' Start speech syntehsis cog
              drive.Wheels(50, -50)   ' Rotate right
              voice.say(string("+4<<Wahtch out"))                           ' Say "hello"  
              time.Pause(50)           ' ..for 0.7 seconds
              'drive.Wheels(0, 0)
             elseif x / 100 < 3900 and x / 100 > 3800 and speedL < 60 
              voice.start(26)                                      ' Start speech syntehsis cog
              voice.say(string("+1<<Go,ing +4<<up"))                           ' Say "hello"  
              time.Pause(10) 
              drive.Wheels(60,60)
              time.Pause(50)
             elseif x / 100 < 3800 and speedL < 80
              voice.start(26)                                      ' Start speech syntehsis cog
              voice.say(string("+1<<Go,ing +4<<up"))
              drive.Wheels(80,80)
              time.Pause(50)
             elseif x / 100 > 4200 and x / 100 < 4500 and speedL > 30
              voice.start(26)                                      ' Start speech syntehsis cog
              voice.say(string("+1<<Go,ing <<dow,n")) 
              drive.Wheels(30,30)
              time.Pause(50)
             elseif x / 100 > 4500 and speedL > 10 
              voice.start(26)                                      ' Start speech syntehsis cog
              voice.say(string("+1<<Go,ing <<dow,n")) 
              drive.Wheels(10,10)
              time.Pause(50)  
             else
               drive.Wheels(speedL, speedR)
               time.Pause(50)           ' ..for 2 seconds
           drive.Wheels(0, 0)
 
        "U","u": XB.str(string(CR,"Speed up!"))
          if speedL < 100 and speedR < 100
           voice.start(26)
           voice.say(string("+6<<S,peed <<+5up"))
           speedL := speedL + 20
           speedR := speedR + 20
           aspeedL:= -1 * speedL
           aspeedR:= -1 * speedR
           drive.Wheels(speedL, speedR)
           time.Pause(500)
           drive.Wheels(0, 0)
          elseif speedL == 100 and speedR == 100
           voice.start(26)
           voice.say(string("+4<<Tahp <<speed"))
            speedL := speedL
            speedR := speedR
            aspeedL:= -1 * speedL
            aspeedR:= -1 * speedR
            drive.Wheels(speedL, speedR)
            time.Pause(500)
            drive.Wheels(0, 0)

        "D","d": XB.str(string(CR,"Speed down!"))
           if speedL == 20 and speedR == 20
            voice.start(26)
            voice.say(string("26<<Tt,oo,, <<+1S,low"))
            speedL := speedL
            speedR := speedR
            aspeedL:= -1 * speedL
            aspeedR:= -1 * speedR
            time.Pause(500)
            drive.Wheels(0, 0)'
           elseif speedL > 0 and speedR > 0
            voice.start(26)
            voice.say(string("+6<<S,peed <<+2down"))
             speedL := speedL - 20
             speedR := speedR - 20      
             aspeedL:= -1 * speedL
             aspeedR:= -1 * speedR
             drive.Wheels(speedL, speedR)
             time.Pause(500)
             drive.Wheels(0, 0)
         
          
       
        "B","b": XB.str(string(CR,"Backward "))
         cognew(Back, @stack[0]) 
         pin.High(7)
         pin.High(9)
         drive.Wheels(aspeedL, aspeedR)
         time.Pause(4000)          
         pin.Low(7)
         pin.Low(9)
         drive.Wheels(0, 0)

                                  
        "R","r": XB.str(string(CR,"Right "))
          repeat 2
           pin.High(9)
           time.Pause(100)
           pin.Low(9)
           time.Pause(100)
         repeat i from 0 to 3
           drive.Wheels(60, -60)
           pin.High(9)
           time.Pause(100)
           pin.Low(9)
           time.Pause(100)
          'time.Pause(700)           ' ..for 0.7 seconds
          drive.Wheels(0, 0)
 
        "L","l": XB.str(string(CR,"Left "))
          repeat 2
           pin.High(7)
           time.Pause(100)
           pin.Low(7)
           time.Pause(100)
         repeat i from 0 to 3
           pin.High(7)
           time.Pause(100)
           drive.Wheels(-60, 60)   ' Rotate right
           pin.Low(7)
           time.Pause(100)
          'time.Pause(700)           ' ..for 0.7 seconds
         drive.Wheels(0, 0)
                  'drive.Wheels(-50, 50)   ' Rotate right 
                  'time.Pause(700)           ' ..for 0.7 seconds
                  'drive.Wheels(0, 0)

        "S","s": XB.str(string(CR,"Sing "))
                  'ABC Song:
                  t.start(sound_port)
                  t.set_speaker(0, 90)
                  t.set_speaker(1, 110)
                  t.set_speaker(2, 100)
                  t.say(string("#1aybee+7seedee++ee ef--jee, --aychae-jaykay--elemenoa--pee, +7kewar--esand-teeew--vee, +5dubul--yewand-ekswae--z%150ee%;"))
                  t.say(string("_nowyoov+7herdmae++aybee--sees, --telmee-wutyoo--thinkuv--m%200ee%..."))
                  
        OTHER:
          XB.str(string("Invalid Command!",CR))
                  
   

{{
┌──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                   TERMS OF USE: MIT License                                                  │                                                            
├──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    │ 
│files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    │
│modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software│
│is furnished to do so, subject to the following conditions:                                                                   │
│                                                                                                                              │
│The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.│
│                                                                                                                              │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE          │
│WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         │
│COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   │
│ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         │
└──────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────┘
}}

Pub Back
repeat 4
 freq.Out(4, 500, 3000)
 time.Pause(500)        