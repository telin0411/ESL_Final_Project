{{Transmits square waves from 1 Hz to 128 MHz
See end of file for authors and terms of use.

Example - transmit square wave with P4 that lasts 1 second and has a
          frequency of 3 kHz.
          
OBJ
  system : "Propeller Board of Education"
  sqwave : "PropBOE Square Wave"

PUB Go
  system.Clock(80_000_000)
  sqwave.Out(4, 1000, 3000)

}}

OBJ

  time : "Timing"

VAR

  long cog, stack[64]                           ' Global variable for differential signals

PUB Out(pin, duration, frequency) : module
{{Transmit signal ended square wave on selected pin for a certain duration
at a certain frequency.

Parameters
  pin       - I/O pin that transmits frequency
  duration  - Time to transmit square wave.  Units of 1 ms by default.
              Use Increment method to adjust.
  frequency - the frequency of the square wave

Returns
  module    - Number of counter module used: 0, 1, or -1 both of the cog's
              counter modules are in use.

NOTE: If -1 is returned, your code can use OutCog instead.  
}}

  module := OutDiff(pin, -1, duration, frequency)
  
PUB OutCog(pin, duration, frequency) : success 
{{Transmit square wave on selected pin for a certain duration using
another cog.

This is the "set it and forget it" version of the Out, and it launches
a cog for the duration of the signal.  Your code that calls this method can
move on to other tasks.

Parameters
  pin       - I/O pin that transmits frequency
  duration  - Time to transmit square wave.  Units of 1 ms by default.
              Use Increment method to adjust.
  frequency - Frequency of the square wave

Returns
  success   - Nonzero if another cog is available and the signal is delivered
              successfully, or zero if not.  
}}

  ifnot cog
    success := cog := cognew(CogSet(pin, duration, frequency), @stack) + 1
  
PRI CogSet(pin, duration, frequency)

  Out(pin, duration, frequency)
  cogstop(cog~-1)

PUB OutDiff(pinA, pinB, duration, frequency) : module   

{{Transmit differential square wave with selected pins for a certain
duration at a certain frequency.

Parameters
  pinA      - I/O pin that transmits frequency
  pinB      - I/O pin that transmits the frequency but always keeps
              its output states opposite from pinA.  This parameter
              can be set to -1 for a single ended signal.
  duration  - Time to transmit square wave.  Units of 1 ms by default.
              Use Increment method to adjust.
  frequency - the frequency of the square wave

Returns
  module    - Number of counter module used: 0, 1, or -1 both of the cog's
              counter modules are in use.

NOTE: If -1 is retured, your code can use OutCog instead.  
}}

  ifnot ctra
    module := 0
  elseifnot ctrb 
    module := 1
  else
    return module := -1

  if pinB == -1
    set(pinA, module, frequency)
  else
    setDiff(pinA, pinB, module, frequency)

  time.Pause(duration)
  Clear(module)

PUB OutDiffCog(pinA, pinB, duration, frequency) : success 
{{Transmit differential square wave on selected pins for a certain duration
using another cog.

This is the "set it and forget it" version of the Out, and it launches
a cog for the duration of the signal so that your code that calls this
method can move on to other tasks.

Parameters
  pin       - I/O pin that transmits frequency
  duration  - Time to transmit square wave.  Units of 1 ms by default.
              Use Increment method to adjust.
  frequency - Frequency of the square wave

Returns
  success   - Nonzero if another cog is available and the signal is delivered
              successfully, or zero if not.  
}}

  ifnot cog
    success := cog := cognew(CogDiffSet(pinA, pinB, duration, frequency), @stack) + 1
  
PRI CogDiffSet(pinA, pinB, duration, frequency)

  OutDiff(pinA, pinB, duration, frequency)
  cogstop(cog~-1)

PUB Set(pin, module, frequency)
{{Transmit square wave on selected pin.

Parameters
  pinA      - I/O pin that transmits frequency.  -1 if only updating existing signal with
              new freuqency
  pinB      - Optional I/O pin to transmit differential of Pin A's signal.  -1 for unused.
  module    - the counter module (0 or 1) to transmit the frequency.  0 selects
              CTRA or 1 selects CTRB.
  frequency - the frequency of the square wave

NOTE: Call Clear method to stop transmitting as well as to reclaim the counter module that
generates the square wave for other uses.

}}
  SetDiff(pin, -1, module, frequency)

PUB SetDiff(pinA, PinB, module, frequency) | s, d, ctr, temp

{{Transmit square wave on selected pin.  Call Clear method to stop transmitting.

Parameters
  pinA      - I/O pin that transmits frequency.  -1 if only updating existing signal with
              new frequency
  pinB      - Optional I/O pin to transmit differential of Pin A's signal.  -1 for unused.
  module    - the counter module (0 or 1) to transmit the frequency.  0 selects
              CTRA or 1 selects CTRB.
  frequency - the frequency of the square wave

}}
  
  frequency := frequency #> 0 <# 128_000_000     ' limit frequency range

  if pinA==-1                                    ' If only updating frequency
    temp := spr[8+module]                        ' Copy existing CTR register
    temp &= %00000100_00000000_01111110_00111111 ' Mask what needs to be saved
  
  if frequency < 500_000                         ' if 0 to 499_999 Hz,
    ctr := constant(%00100 << 26)                ' ..set NCO mode
    s := 1                                       ' ..shift = 1
  else                                           ' if 500_000 to 128_000_000 Hz,
    ctr := constant(%00010 << 26)                ' ..set PLL mode
    d := >| ((frequency - 1) / 1_000_000)        ' determine PLLDIV
    s := 4 - d                                   ' determine shift
    ctr |= d << 23                               ' set PLLDIV

  if pinB <> -1 and pinA <> -1                   ' if differential & not frequency update
    ctr |= (pinB << 9)                           ' Add to BPIN field
    ctr |= 1 << 26                               ' Set differential bit

  spr[10 + module] := fraction(frequency, CLKFREQ, s)    'Compute frqa/frqb value

  if pinA == -1                                  ' If just a frequency update
    spr[8+module] := (temp | (ctr & %00011011_10000000_00000000_00000000))
  else                                           ' If not just a frequency update
    ctr |= PinA                                  ' Set PINA to complete CTRA/CTRB value
    spr[8 + module] := ctr                       ' Copy ctr variable to counter control register
    dira[spr[8+module]&$1F]~~                    ' Set pin directions based on ctr reg contents
    if spr[8+module]&|<26
      dira[spr[8+module]>>9&$1F]~~

PUB Update(module, newFrequency)

  ''Update the frequency transmitted by a module
  ''  module - 0 or 1
  ''  newFrequency - the new frequency (0 to 128 MHz) for the module to transmit
  ''NOTE: If you update to 0 Hz, the I/O pins will remain output and retain the
  ''output state(s) at the moment the newFrequency updates.  If you want the I/O
  ''pins changed to input, use the Remove method instead. 

  Set(-1, module, newFrequency)                 ' pin = -1 => update frequency

PUB Clear(module)
  
  ''Stop a module from transmitting a frequency and set its I/O pin(s) to input
  ''  module - the module (0 or 1) that gets stopped
  ''If you do not want to set the I/O pins to input, use Update, but set the
  ''frequency to zero.

  if module                                      ' Decide which counter
    if ctrb[26]                                  ' If differential mode
      dira[ctrb[14..9]]~                         ' Inverted signal pin -> input
    dira[ctrb[5..0]]~                            ' Signal pin -> input
    ctrb~                                        ' Clear counter control register
    frqb~                                        ' Clear frequency register
  else                                           ' Else if CTRA
    if ctra[26]                                  ' If differential mode
      dira[ctra[17..9]]~                         ' Inverted signal pin -> input
    dira[ctra[5..0]]~                            ' Signal pin to 
    ctra~                                        ' Clear counter control register 
    frqa~                                        ' Clear frequency register

PUB NcoFrqReg(frequency) : frqReg
{{
Returns frqReg = frequency × (2³² ÷ clkfreq) calculated with binary long
division.  This is faster than the floating point library, and takes less
code space.  This method is an adaptation of the CTR object's fraction
method.
}}
  frqReg := fraction(frequency, clkfreq, 1)

PUB Increment(clockticks)
{{Sets the time increment based on a number of clock ticks.
 
Parameters:

  clockticks = number of system clock tics a
               time increment should last.

Example:

  'Change duration increment from 1 ms
  'to 0.5 ms.  
  time.Increment(clkfreq/2000)  '0.5 ms

}}
  time.Increment(clockticks)

PRI Fraction(a, b, shift) : f

  if shift > 0                                   'if shift, pre-shift a or b left
    a <<= shift                                  'to maintain significant bits while 
  if shift < 0                                   'insuring proper result
    b <<= -shift
 
  repeat 32                                      'perform long division of a/b
    f <<= 1
    if a => b
      a -= b
      f++           
    a <<= 1

{{

Author:  Andy Lindsay
Sources: Extends frequency synthesis portion of CTR.spin by Chip Gracey.
Date:    2012.05.24
Version: 0.82

Updates:
  0.80 -> 0.82
      Single ended signals had unintentional differential copy on P0 (fixed).
      End method changed to clear.
      OutCogDiff method added.
      Increment method added.

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │                                                            
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
    