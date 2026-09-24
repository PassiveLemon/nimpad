import std/tables

type
  KeyType* = enum
    KEY_ACTION, SHELL_ACTION, MACRO_ACTION

  NimpadKey* = object
    keyType*: KeyType
    keyAction*: string
    keyRepeat*: bool

  NimpadKeyTable* = OrderedTable[string, NimpadKey]

const
  RELEASE_VERSION*: string = "0.4.0"

