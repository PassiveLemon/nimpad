import
  std / [
    logging,
    strformat
  ]


var consoleLog = newConsoleLogger(fmtStr="[$levelname]: ")


proc initLogger*(lvl: string, ts: bool): void =
  if ts:
    consoleLog = newConsoleLogger(fmtStr="[$datetime][$levelname]: ")

  case lvl:
    of "d", "debug", "6":
      setLogFilter(lvlDebug)
    # Default
    of "", "i", "info", "5":
      setLogFilter(lvlInfo)
    of "n", "notice", "4":
      setLogFilter(lvlNotice)
    of "w", "warn", "3":
      setLogFilter(lvlWarn)
    of "e", "error", "2":
      setLogFilter(lvlError)
    of "f", "fatal", "1":
      setLogFilter(lvlFatal)
    of "none", "0":
      setLogFilter(lvlNone)
    else:
      consoleLog.log(lvlFatal, fmt"{lvl} is not a valid value for log-level.")
      quit(1)

proc debug*(str: string): void =
  consoleLog.log(lvlDebug, str)

proc info*(str: string): void =
  consoleLog.log(lvlInfo, str)

proc notice*(str: string): void =
  consoleLog.log(lvlNotice, str)

proc warn*(str: string): void =
  consoleLog.log(lvlWarn, str)

proc error*(str: string): void =
  consoleLog.log(lvlError, str)

proc fatal*(str: string): void =
  consoleLog.log(lvlFatal, str)
  quit(1)

