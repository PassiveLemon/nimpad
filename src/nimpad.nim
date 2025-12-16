import
  std / [
    strformat,
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

  while true:
    var nimpadStream: SerialStream

    nimpadStream = openDevice(globalConfig)

    notice(fmt"Opened serial port '{globalConfig.config.port}'.")

    var buf = newString(2)
    while true:
      try:
        let n = nimpadStream.readData(buf.cstring, buf.len)
        if n > 0:
          let chunk = buf[0..<n]
          keyHandler(chunk, globalConfig.nimpad)
        if n == 0:
          # Not technically an error condition, but we normally shouldnt ever see n == 0 due to the validation handshake
          break
      except IOError, OSError:
        break

    error("Port error, Reconnecting...")
    sleep(2000)

