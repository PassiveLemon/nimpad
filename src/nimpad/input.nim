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


proc createDevice(): ptr libevdev_uinput =
  try:
    var
      evdev: ptr libevdev
      uinput: ptr libevdev_uinput

    evdev = libevdev_new()
    libevdev_set_name(evdev, "Nimpad Input");
    discard libevdev_enable_event_type(evdev, EV_KEY);

    # Allow all keyboard capabilities https://github.com/PassiveLemon/libevdev-nim/blob/4d9b3581df1b95ffc400ae965958039e0687f1d0/libevdev/linux/input.nim#L158
    for keyCode in 0..248:
      discard libevdev_enable_event_code(evdev, EV_KEY, keyCode.cuint, nil)

    let libevdevUinputRet = libevdev_uinput_create_from_device(evdev, LIBEVDEV_UINPUT_OPEN_MANAGED, addr uinput)
    if libevdevUinputRet < 0:
      fatal(fmt"Could not create libevdev uinput device: code {libevdevUinputRet}")

    return uinput
  except: # Figure out errors
    fatal("Could not create evdev device")

proc initDevice*(): void =
  try:
    nimpadEvDevice = createDevice()
  except: # Figure out errors
    fatal("Could not initialize evdev device")

proc openDevice*(): SerialStream =
  while true:
    try:
      nimpadStream = newSerialStream(globalConfig.port, 9600, Parity.None, 8, StopBits.One, Handshake.None, readTimeout = 300000, writeTimeout = 300000)
      debug(fmt"Opened serial port '{globalConfig.port}'.")
      return nimpadStream
    except InvalidSerialPortError:
      error(fmt"Port {globalConfig.port} is not a valid serial port. Retrying...")
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
  finally:
    quit(0)

proc sendKey(key: int, state: int): void =
  try:
    libevdev_uinput_write_event(nimpadEvDevice, EV_KEY, key, state)
    libevdev_uinput_write_event(nimpadEvDevice, EV_SYN, SYN_REPORT, 0)
    sleep(5) # Buffer time so listeners can see events more consistently
  except: # Figure out errors
    error(fmt"Could not write key event: {key}. state: {state}")

proc manageKey(action: string, state: int, repeat: bool): void =
  let key = parseInt(action)
  if repeat:
    sendKey(key, state)
  elif state == 1:
    sendKey(key, 1)
    sendKey(key, 0)

proc runShellCmd(action: string, state: int): void =
  try:
    if state == 1:
      discard startProcess(action, options = { poDaemon, poUsePath })
  except: # Figure out errors
    error(fmt"Could not start process '{action}' ")

proc runKeySequence(action: string, state: int): void =
  if state == 1:
    let keySeq = action.split(" ")
    for key in keySeq:
      let keyCode = parseInt(key)
      sendKey(keyCode, 1)
      sendKey(keyCode, 0)

proc actionHandler(input: string): void =
  try:
    let
      nimpadKeys = globalConfig.nimpad
      pressedKey = $input[0]
      pressedKeyState = parseInt($input[1])
      keyActionType = nimpadKeys[pressedKey].keyType
      keyAction = nimpadKeys[pressedKey].keyAction
      keyRepeat = nimpadKeys[pressedKey].keyRepeat

    case keyActionType:
      of KEY_ACTION:
        info(fmt"Inputting key '{keyAction}' '{pressedKeyState}'")
        manageKey(keyAction, pressedKeyState, keyRepeat)
      of SHELL_ACTION:
        info(fmt"Executing '{keyAction}'")
        runShellCmd(keyAction, pressedKeyState)
      of MACRO_ACTION:
        info(fmt"Inputting key sequence '{keyAction}'")
        runKeySequence(keyAction, pressedKeyState)
  except:
    warn(fmt"Unknown actionHandler input '{input}'. Ignoring...")

proc keyHandler*(input: string): void =
  debug(fmt"Received input: '{input}'")
  try:
    discard parseInt(input)
    actionHandler(input)
  except:
    warn(fmt"Unknown KeyHandler input '{input}'. Ignoring...")

