# Used to keep Arduino stuff contained in this repository
CONFIG = --config-file ./arduino-cli.yaml

SKETCH = nimpad
LIBRARIES = Keypad HID-Project

FQBN = --fqbn arduino:avr:micro
PORT = --port /dev/serial/by-id/usb-Arduino_LLC_Arduino_Micro_HIDLD-if00

setup:
	arduino-cli lib install $(LIBRARIES) $(CONFIG)

compile:
	arduino-cli compile $(SKETCH) $(CONFIG) $(FQBN)

upload: compile
	arduino-cli upload $(SKETCH) $(CONFIG) $(FQBN) $(PORT)

