import
  std / [
    os,
    strformat,
    strutils,
    json
  ]

import
  cli,
  constants,
  logging


type
  Config* = object
    port*: string
  GlobalConfig* = object
    config*: Config
    nimpad*: NimpadKeySeq


const
  configJson: string = """
[
  [ "KEY_ACTION", "VOLUMEDOWN" ],
  [ "KEY_ACTION", "VOLUMEUP" ],
  [ "KEY_ACTION", "VOLUMEMUTE" ],
  [ "KEY_ACTION", "SCROLLLOCK" ],
  [ "KEY_ACTION", "PREVIOUSSONG" ],
  [ "KEY_ACTION", "NEXTSONG" ],
  [ "KEY_ACTION", "PLAYPAUSE" ],
  [ "KEY_ACTION", "" ],
  [ "KEY_ACTION", "" ],
  [ "KEY_ACTION", "" ]
]
"""

var globalConfig*: GlobalConfig


proc getRealUserConfigDir(): string =
  if (getEnv("USER") == "root") and (getEnv("SUDO_USER") != ""):
    # Ideally we fetch the config dir for a specific user instead of assuming the location, but I couldn't find anything that does so
    return "/home" / getEnv("SUDO_USER") / "/.config/nimpad/config.json"
  return getConfigDir() / "/nimpad/config.json"

proc createConfig(filePath: string): void =
  let parentPath = parentDir(filePath)

  if not existsOrCreateDir(parentPath):
    try:
      createDir(parentPath)
    except IOError, OSError:
      fatal(fmt"Could not create {parentPath}")

  if not fileExists(filePath):
    try:
      writeFile(filePath, configJson)
    except IOError, OSError:
      fatal(fmt"Could not write to {filePath}")
    finally:
      fatal(fmt"Config file was created at {filePath}. Please configure it accordingly before running again.")

proc parseConfig(filePath: string, cliArgs: CliArgs): Config =
  try:
    let nimpadConfig = parseFile(filePath)
    var
      node: JsonNode = %*{}
      json: Config

    for v in nimpadConfig.items:
      let
        actionType = parseEnum[NimpadKeyActionType](v[0].getStr())
        action = v[1].getStr()
      globalConfig.nimpad.add((actionType, action))

    if cliArgs.port == "":
      debug("Argument MODE not provided. Defaulting to /dev/ttyACM0...")
      node["port"] = %"/dev/ttyACM0"
    else:
      node["port"] = %cliArgs.port

    json = to(node, Config)
    return json
  except JsonParsingError:
    fatal("Config file is not valid json.")

proc initConfig*(): void =
  let cliArgs = processCliArgs()
  var configDir = getRealUserConfigDir()

  initLogger(cliArgs.loglevel, cliArgs.timestamps)

  if cliArgs.file != "":
    configDir = cliArgs.file

  createConfig(configDir)
  globalConfig.config = parseConfig(configDir, cliArgs)

