import tables

import libevdev


type
  EvdevKey* = int
  NimpadKeyActionType* = enum
    KEY_ACTION, SHELL_ACTION
  NimpadKeyAction* = string

  NimpadKey* = tuple[actionType: NimpadKeyActionType, action: NimpadKeyAction]
  NimpadKeySeq* = seq[NimpadKey]


const
  RELEASE_VERSION*: string = "0.3.2"

  # https://github.com/PassiveLemon/libevdev-nim/blob/4d9b3581df1b95ffc400ae965958039e0687f1d0/libevdev/linux/input.nim#L158
  EVDEV_LOOKUP*: Table[NimpadKeyAction, EvdevKey] = {
    "VOLUMEUP": KEY_VOLUMEUP,
    "VOLUMEDOWN": KEY_VOLUMEDOWN,
    "VOLUMEMUTE": KEY_MUTE,
    "SCROLLLOCK": KEY_SCROLLLOCK,
    "NEXTSONG": KEY_NEXTSONG,
    "PREVIOUSSONG": KEY_PREVIOUSSONG,
    "PLAYPAUSE": KEY_PLAYPAUSE
  }.toTable

