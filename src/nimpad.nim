import
  std / [
    streams,
    os
  ]

import
  nimpad / [
    config,
    input,
    logging
  ]

import serial

# globalConfig from config.nim

block nimpad:
  initConfig()
  initDevice()

  setControlCHook(inputCleanup)

  while true:
    var
      nimpadStream: SerialStream
      buf = newString(2)

    try:
      nimpadStream = openDevice(globalConfig)

      while true:
        try:
          let n = nimpadStream.readData(addr buf[0], buf.len)
          if n == 2:
            let chunk = buf[0..<n]
            keyHandler(chunk, globalConfig.nimpad)
          else:
            # We shouldn't see this because the Arduino communicates in 2 digit chunks
            warn("n != 0, this should not happen")
            break
        except IOError:
          debug("Port timeout, reconnecting...")
          break
        except OSError:
          warn("Port error, reconnecting...")
          break
    finally:
      try:
        close(nimpadStream)
      except:
        discard
    sleep(2000)

