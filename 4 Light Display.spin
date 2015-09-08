OBJ

  pin  : "Input Output Pins"
  time : "Timing"

PUB Blink

  repeat
    pin.Outs(15,8,%10101010)
    time.Pause(400)
    pin.Outs(15,8,%01010101)
    time.Pause(400)

    