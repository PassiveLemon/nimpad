#include <Keypad.h>
#include <HID-Project.h>

const int R1 = 5;
const int R2 = 6;
const int R3 = 7;
const int R4 = 8;
const int R5 = 9;
const int C1 = 10;
const int C2 = 16;

const int ROWS = 5;
const int COLS = 2;
const char keys[COLS][ROWS] = {
  // For some reason this has to be flipped to work
  { 1, 3, 5, 7, 9 },
  { 2, 4, 6, 8, 0 }
};
const byte rowPins[ROWS] = { R1, R2, R3, R4, R5 };
const byte colPins[COLS] = { C1, C2 };
const Keypad kpd = Keypad(makeKeymap(keys), colPins, rowPins, COLS, ROWS);

void setup() {
  Serial.begin(9600);
  Keyboard.begin();
}

// { 1, 2 } 1: Volume down | 2: Volume up
// { 3, 4 } 3: Mute system | 4: Press to mute for Discord/push to talk for games
// { 5, 6 } 5: Media previous | 6: Media next
// { 7, 8 } 7: Media play/pause | 8: Unused
// { 9, 0 } 9: Unused | 0: Unused

void layout1(char button, KeyState state) {
  switch (button) {
    case 1:
      if (state == PRESSED) Consumer.press(MEDIA_VOLUME_DOWN);
      if (state == RELEASED) Consumer.release(MEDIA_VOLUME_DOWN);
      break;
    case 2:
      if (state == PRESSED) Consumer.press(MEDIA_VOLUME_UP);
      if (state == RELEASED) Consumer.release(MEDIA_VOLUME_UP);
      break;
    case 3:
      if (state == PRESSED) Consumer.press(MEDIA_VOLUME_MUTE);
      if (state == RELEASED) Consumer.release(MEDIA_VOLUME_MUTE);
      break;
    case 4:
      if (state == PRESSED) Keyboard.press(KEY_SCROLL_LOCK);
      if (state == RELEASED) Keyboard.release(KEY_SCROLL_LOCK);
      break;
    case 5:
      if (state == PRESSED) Consumer.press(MEDIA_PREVIOUS);
      if (state == RELEASED) Consumer.release(MEDIA_PREVIOUS);
      break;
    case 6:
      if (state == PRESSED) Consumer.press(MEDIA_NEXT);
      if (state == RELEASED) Consumer.release(MEDIA_NEXT);
      break;
    case 7:
      if (state == PRESSED) Consumer.press(MEDIA_PLAY_PAUSE);
      if (state == RELEASED) Consumer.release(MEDIA_PLAY_PAUSE);
      break;
    case 8:
      // if (state == PRESSED) Keyboard.press("8");
      // if (state == RELEASED) Keyboard.release("8");
      break;
    case 9:
      // if (state == PRESSED) Keyboard.press("9");
      // if (state == RELEASED) Keyboard.release("9");
      break;
    case 0:
      // if (state == PRESSED) Keyboard.press("0");
      // if (state == RELEASED) Keyboard.release("0");
      break;
  }
}

void loop() {
  if (kpd.getKeys()) {
    for (int i = 0; i < LIST_MAX; i++) {
      if (kpd.key[i].stateChanged) {
        layout1(kpd.key[i].kchar, kpd.key[i].kstate);
      }
    }
  }
}

