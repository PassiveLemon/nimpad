# nimpad

A Nim based client for a DIY macropad.

Nimpad listens to an Arduino macropad and runs commands or shell scripts based on key.

# Dependencies
- Linux, other platforms are not supported.
- A user in the "uinput" and "dialout" group. You can use sudo privileges but if you want to use this as a daemon to run shell commands, sudo is not recommended.
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
> If your pad ever disconnects, the device name may change. To prevent errors that happen with this, run with the port option set to your device in `/dev/serial/by-id/`. Ex: `nimpad -p=/dev/serial/by-id/usb-Arduino_LLC_Arduino_Micro_HIDLD-if00`

If you are using Nimpad for the first time, it will create a default config file and quit. Please configure this config file before running it again as it does send keyboard inputs and run commands. Details [below](https://github.com/PassiveLemon/nimpad?tab=readme-ov-file#configuration-configjson).

# Configuration (config.json)
The currently intended way to configure Nimpad is by the config.json.
By default, it will create the config file like so:
```json
{
  "0": { // Vol down
    "keyType": "KEY_ACTION",
    "keyAction": "114",
    "keyRepeat": true,
  },
  "1": { // Vol up
    "keyType": "KEY_ACTION",
    "keyAction": "115",
    "keyRepeat": true,
  },
  "2": { // Sys mute
    "keyType": "KEY_ACTION",
    "keyAction": "113",
    "keyRepeat": false,
  },
  "3": { // Scrolllock
    "keyType": "KEY_ACTION",
    "keyAction": "70",
    "keyRepeat": false,
  },
  "4": { // Prev song
    "keyType": "KEY_ACTION",
    "keyAction": "165",
    "keyRepeat": false,
  },
  "5": { // Next song
    "keyType": "KEY_ACTION",
    "keyAction": "163",
    "keyRepeat": false,
  },
  "6": { // Play/pause
    "keyType": "KEY_ACTION",
    "keyAction": "164",
    "keyRepeat": false,
  },
}
```

There are two key types, `KEY_ACTION`, `SHELL_ACTION`, and `MACRO_ACTION`:

`KEY_ACTION` is used to simulate a key input. Find the key code to use from [libevdev](https://github.com/PassiveLemon/libevdev-nim/blob/4d9b3581df1b95ffc400ae965958039e0687f1d0/libevdev/linux/input.nim#L158).

`SHELL_ACTION` is used to run a shell command. This is mostly for complex scripts or any action that isn't supported as a key type in libevdev. As always, audit your commands before they run. Ex:
```
"1": {
  "keyType": "SHELL_ACTION",
  "keyAction": "playerctl play-pause",
  "keyRepeat": false,
},
```

The key action is either the numberic key code, or a string to execute a shell command. Repeat on hold can also be toggled.

# Custom pads
If you are creating your own pad, there are a few requirements for it to work:
- It must communicate over serial
- It must communicate in 2 digit chunks (Ex: "71, 70") with the first digit being the numbered key (0-9) and the second the press state (0/1).
- It must have 10 or less unique keys

You also will likely need to modify the Arduino sketch for your board, pins, and keymap.

