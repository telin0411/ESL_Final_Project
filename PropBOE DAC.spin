{{
NOTICE:
This object is a draft and has pending revisions.  Check
http://learn.parallax.com/node/103 for updates.  If you have
questions, please email me: alindsay@parallax.com.

See end of file for author, version, copyright and terms of use.
}}
CON
  scale = 16_777_216 ' 2³²÷ 256

VAR

  long configured[2]

PUB Config(channel)                                 

  if(channel==0)
    ctra[30..26] := %00110
    ctra[5..0]   := 26
    dira[26]:=1
    configured[0] := true
  elseif(channel==1)
    ctrb[30..26] := %00110
    ctrb[5..0]   := 27
    dira[27]:=1
    configured[1] := true
     
PUB Out(channel, dacval)

  ifnot configured[channel]
    Config(channel)
    
  spr[10+channel] := dacval * scale
{
PUB PinSetup(channel, pin)

  ifnot configured[channel]
    Config(channel)

  if(channel==0)
    pins[0] := pin
    ctra[5..0]   := pin
    dira[pin]:=1
  elseif(channel==1)
    pins[1] := pin
    ctrb[5..0]   := pin
    dira[pin]:=1
}
{{
Author: Andy Lindsay
Version: 0.2
Date:   2011.05.17
Copyright (c) 2011 Parallax Inc.

┌──────────────────────────────────────────────────────────────────────────────────────┐
│TERMS OF USE: MIT License                                                             │                                                            
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │ 
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}        