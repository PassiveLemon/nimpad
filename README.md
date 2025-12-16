# nimpad

A Nim based client for a DIY macropad.

By communicating with an Arduino in the macropad, nimpad can send keyboard inputs or run shell commands.

# Dependencies
- Linux, other platforms are not supported.
- A user in the "input" and "dialout" group. You can use sudo privileges but if you want to use this as a daemon to run shell commands, sudo is not recommended.
- Nimble packages: `serial` and [`libevdev`](https://github.com/PassiveLemon/libevdev-nim)

## 3D Model
https://www.printables.com/model/1400774-macropad

# Usage
### Nix:
- You can get the package in my [flake repository](https://github.com/PassiveLemon/lemonake).
### Source:
- Clone the repo, cd to src
- Run `nim c -r nimpad`
- Edit the generated config file in your `~/.config/nimpad/config.json`.
- You can also supply a config file with `-f="<path to config.json>"`, and a serial port with `-p="<port>"` .
  - Arguments can be found by tacking `-h` or `--help`

> [!IMPORTANT]
> Nimpad ONLY supports pads with 10 or less keys.

> [!IMPORTANT]
> If your pad ever disconnects, it's device name may change. To prevent errors that happen with this, run with the port option set to your device in `/dev/serial/by-id/`. Ex: `nimpad -p=/dev/serial/by-id/usb-Arduino_LLC_Arduino_Micro_HIDLD-if00`

If you are using Nimpad for the first time, it will create a default config file and quit. Please configure this config file before running it again as it does send keyboard inputs and run commands. Details [below](https://github.com/PassiveLemon/nimpad?tab=readme-ov-file#configuration-configjson).

# Configuration (config.json)
The intended way to currently configure Nimpad is by the config.json.
By default, it will create the config file like so:
```json
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
```
- 0: Volume down
- 1: Volume up
- 2: Mute system
- 3: Scrolllock, used for Discord press-to-mute and game push-to-talk
- 4: Media previous
- 5: Media next
- 6: Media play/pause
- 7: Unused
- 8: Unused
- 9: Unused

# Standalone
If you don't want to use the Nimpad host client, you can find a completely standalone Arduino sketch in `other`. This still sends keyboard inputs, but does not allow running commands on the host.

