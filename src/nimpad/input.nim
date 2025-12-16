import
  std / [
    os,
    osproc,
    streams,
    strformat,
    strutils,
    tables
  ]

import
  config,
  constants,
  logging

import
  libevdev,
  serial


var
  nimpadEvDevice: ptr libevdev_uinput
  nimpadStream: SerialStream


proc createDevice(): ptr libevdev_uinput =
  var
    evdev = libevdev_new()
    uinput: ptr libevdev_uinput

  libevdev_set_name(evdev, "Nimpad Input");
  discard libevdev_enable_event_type(evdev, EV_KEY);
  # Allow all capabilities from EVDEV_LOOKUP
  for k, v in EVDEV_LOOKUP.pairs:
    discard libevdev_enable_event_code(evdev, EV_KEY, v.cuint, nil);

  let libevdevUinputRet = libevdev_uinput_create_from_device(evdev, LIBEVDEV_UINPUT_OPEN_MANAGED, addr uinput)
  if libevdevUinputRet < 0:
    fatal(fmt"Could not create libevdev uinput device: code {libevdevUinputRet}")

  return uinput

proc initDevice*(): void =
  nimpadEvDevice = createDevice()

proc cleanupDevice*(): void =
  libevdev_uinput_destroy(nimpadEvDevice)

proc openDevice*(globalConfig: GlobalConfig): SerialStream =
  while true:
    try:
      nimpadStream = newSerialStream(globalConfig.config.port, 9600, Parity.None, 8, StopBits.One, Handshake.None, readTimeout = 20000, writeTimeout = 20000)
      return nimpadStream
    except InvalidSerialPortError:
      error(fmt"Port {globalConfig.config.port} is not a valid serial port. Retrying...")
      sleep(2000)

proc cleanup() {.noconv.} =
  cleanupDevice()
  nimpadStream.close()
  quit(0)

setControlCHook(cleanup)

proc manageKey(key: int, state: int): void =
  libevdev_uinput_write_event(nimpadEvDevice, EV_KEY, key, state)
  sleep(10) # Buffer time so listeners can see events more consistently
  libevdev_uinput_write_event(nimpadEvDevice, EV_SYN, SYN_REPORT, 0)
  sleep(10)

proc runShellCmd(action: string): void =
  discard startProcess(action, options = { poDaemon, poUsePath })

var lastShellActionState: seq[int] = newSeq[int](10)

proc actionHandler*(input: string, nimpadKeys: NimpadKeySeq): void =
  try:
    let
      pressedKey: int = (input[0].ord - '0'.ord)
      pressedKeyState: int = (input[1].ord - '0'.ord)
      (keyActionType, keyAction) = nimpadKeys[pressedKey]

    case keyActionType:
      of KEY_ACTION:
        if EVDEV_LOOKUP.hasKey(keyAction):
          info(fmt"{keyAction} {pressedKeyState}")
          manageKey(EVDEV_LOOKUP[keyAction], pressedKeyState)
          return
        else:
          warn(fmt"Unknown keyAction '{keyAction}'. Ignoring...")
      # We make sure that shell actions won't be repeated
      of SHELL_ACTION:
        # Only spawn on key press and ensure it can't be spawned multiple times on one key press
        if pressedKeyState == 1:
          if lastShellActionState[pressedKey] == 0:
            lastShellActionState[pressedKey] = 1
            info(fmt"Executing '{keyAction}'")
            runShellCmd(keyAction)
            return
        else:
          lastShellActionState[pressedKey] = 0
  except:
    warn(fmt"Unknown actionHandler input '{input}'. Ignoring...")

proc nimpadHandshake*(input: string): void =
  let
    aa: string = "AA"
    af: string = "AF"

  case input:
    of "AR": # Acknowledge connection
      debug("Received AR, acknowledging connection, sending AA")
      nimpadStream.writeData(aa.cstring, aa.len)
      nimpadStream.flush()
    of "AE": # Finish connection
      debug("Received AE, completing connection, sending AF")
      nimpadStream.writeData(af.cstring, af.len)
      nimpadStream.flush()
    of "AV": # Validate connection
      debug("Received AV, validating connection, sending AF")
      nimpadStream.writeData(af.cstring, af.len)
      nimpadStream.flush()

proc keyHandler*(input: string, nimpadKeys: NimpadKeySeq): void =
  debug(fmt"Received input: '{input}'")
  try:
    case input:
      of "AR", "AA", "AE", "AF", "AV":
        nimpadHandshake(input)
      else:
        discard parseInt(input)
        actionHandler(input, nimpadKeys)
  except:
    warn(fmt"Unknown KeyHandler input '{input}'. Ignoring...")

