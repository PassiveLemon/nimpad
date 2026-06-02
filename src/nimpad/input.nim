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

# globalConfig from config.nim

var
  nimpadEvDevice: ptr libevdev_uinput
  nimpadStream: SerialStream
  lastShellActionState: seq[int] = newSeq[int](10)


proc createDevice(): ptr libevdev_uinput =
  var
    evdev: ptr libevdev
    uinput: ptr libevdev_uinput

  try:
    evdev = libevdev_new()
    libevdev_set_name(evdev, "Nimpad Input");
    discard libevdev_enable_event_type(evdev, EV_KEY);
    # Allow all capabilities from EVDEV_LOOKUP
    for _, v in EVDEV_LOOKUP.pairs:
      discard libevdev_enable_event_code(evdev, EV_KEY, v.cuint, nil);

    let libevdevUinputRet = libevdev_uinput_create_from_device(evdev, LIBEVDEV_UINPUT_OPEN_MANAGED, addr uinput)
    if libevdevUinputRet < 0:
      fatal(fmt"Could not create libevdev uinput device: code {libevdevUinputRet}")

    return uinput
  except: # Figure out errors
    fatal("Could not create evdev device")

proc initDevice*(): void =
  try:
    nimpadEvDevice = createDevice()
    return
  except: # Figure out errors
    fatal("Could not initialize evdev device")

proc openDevice*(globalConfig: GlobalConfig): SerialStream =
  while true:
    try:
      nimpadStream = newSerialStream(globalConfig.config.port, 9600, Parity.None, 8, StopBits.One, Handshake.None, readTimeout = 300000, writeTimeout = 300000)
      debug(fmt"Opened serial port '{globalConfig.config.port}'.")
      return nimpadStream
    except InvalidSerialPortError:
      error(fmt"Port {globalConfig.config.port} is not a valid serial port. Retrying...")
      sleep(2000)
    except IOError:
      debug("Port timeout, reconnecting...")
      break
    except OSError:
      error("Port error, reconnecting...")
      break

proc inputCleanup*() {.noconv.} =
  info("Cleaning up...")
  try:
    libevdev_uinput_destroy(nimpadEvDevice)
    close(nimpadStream)
    return
  finally:
    quit(0)

proc manageKey(key: int, state: int): void =
  try:
    libevdev_uinput_write_event(nimpadEvDevice, EV_KEY, key, state)
    sleep(10) # Buffer time so listeners can see events more consistently
    libevdev_uinput_write_event(nimpadEvDevice, EV_SYN, SYN_REPORT, 0)
    sleep(10)
    return
  except: # Figure out errors
    error(fmt"Could not write key event: {key}. state: {state}")

proc runShellCmd(action: string): void =
  try:
    discard startProcess(action, options = { poDaemon, poUsePath })
    return
  except: # Figure out errors
    error(fmt"Could not start process '{action}' ")

proc actionHandler(input: string, nimpadKeys: NimpadKeySeq): void =
  let
    pressedKey = parseInt($input[0])
    pressedKeyState = parseInt($input[1])
    (keyActionType, keyAction) = nimpadKeys[pressedKey]

  var lastShellActionState = lastShellActionState[pressedKey]

  try:
    case keyActionType:
      of KEY_ACTION:
        if EVDEV_LOOKUP.hasKey(keyAction):
          info(fmt"{keyAction} {pressedKeyState}")
          manageKey(EVDEV_LOOKUP[keyAction], pressedKeyState)
          return
        else:
          warn(fmt"Unknown keyAction '{keyAction}'. Ignoring...")
      of SHELL_ACTION:
        # Make sure that shell actions won't be repeated
        # Only spawn on key press and ensure it can't be spawned multiple times on one key press
        if pressedKeyState == 1:
          if lastShellActionState == 0:
            lastShellActionState = 1
            info(fmt"Executing '{keyAction}'")
            runShellCmd(keyAction)
            return
        else:
          lastShellActionState = 0
  except:
    warn(fmt"Unknown actionHandler input '{input}'. Ignoring...")

proc keyHandler*(input: string, nimpadKeys: NimpadKeySeq): void =
  debug(fmt"Received input: '{input}'")
  try:
    discard parseInt(input)
    actionHandler(input, nimpadKeys)
    return
  except:
    warn(fmt"Unknown KeyHandler input '{input}'. Ignoring...")

