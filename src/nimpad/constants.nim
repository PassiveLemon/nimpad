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
  RELEASE_VERSION*: string = "0.3.1"

  EVDEV_LOOKUP*: Table[NimpadKeyAction, EvdevKey] = {
    "VOLUMEUP": KEY_VOLUMEUP,
    "VOLUMEDOWN": KEY_VOLUMEDOWN,
    "VOLUMEMUTE": KEY_MUTE,
    "SCROLLLOCK": KEY_SCROLLLOCK,
    "NEXTSONG": KEY_NEXTSONG,
    "PREVIOUSSONG": KEY_PREVIOUSSONG,
    "PLAYPAUSE": KEY_PLAYPAUSE
  }.toTable

