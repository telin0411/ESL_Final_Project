OBJ

  pin  : "Input Output Pins"
  time : "Timing"

PUB Blink

  repeat
    pin.High(10)
    time.Pause(100)
    pin.Low(10)
    time.Pause(100)
    