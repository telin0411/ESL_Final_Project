OBJ

  pin  : "Input Output Pins"
  time : "Timing"

PUB Blink

  repeat
    pin.High(9)
    time.Pause(100)
    pin.Low(9)
    time.Pause(100)
    