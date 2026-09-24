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
    nimpad*: NimpadKeyTable


const
  configJson: string = """
{
  "0": {
    "keyType": "KEY_ACTION",
    "keyAction": "114",
    "keyRepeat": true,
  },
  "1": {
    "keyType": "KEY_ACTION",
    "keyAction": "115",
    "keyRepeat": true,
  },
  "2": {
    "keyType": "KEY_ACTION",
    "keyAction": "113",
    "keyRepeat": false,
  },
  "3": {
    "keyType": "KEY_ACTION",
    "keyAction": "70",
    "keyRepeat": false,
  },
  "4": {
    "keyType": "KEY_ACTION",
    "keyAction": "165",
    "keyRepeat": false,
  },
  "5": {
    "keyType": "KEY_ACTION",
    "keyAction": "163",
    "keyRepeat": false,
  },
  "6": {
    "keyType": "KEY_ACTION",
    "keyAction": "164",
    "keyRepeat": false,
  },
}
"""

var globalConfig*: Config


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
    var
      node: JsonNode = parseFile(filePath)
      json: Config

    json.nimpad = to(node, NimpadKeyTable)
      
    if cliArgs.port == "":
      debug("Argument MODE not provided. Defaulting to /dev/ttyACM0...")
      json.port = "/dev/ttyACM0"
    else:
      json.port = cliArgs.port
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
  globalConfig = parseConfig(configDir, cliArgs)

