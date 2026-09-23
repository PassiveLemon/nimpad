const int R1 = 5;
const int R2 = 6;
const int R3 = 7;
const int R4 = 8;
const int R5 = 9;
const int C1 = 10;
const int C2 = 16;

const int ROWS = 5;
const int COLS = 2;

const byte rowPins[ROWS] = { R1, R2, R3, R4, R5 };
const byte colPins[COLS] = { C1, C2 };

bool keyState[ROWS][COLS] = { };

void setup() {
  Serial.begin(9600);
  for (int r = 0; r < ROWS; r++) {
    pinMode(rowPins[r], OUTPUT);
    digitalWrite(rowPins[r], HIGH);
  }
  for (int c = 0; c < COLS; c++) {
    pinMode(colPins[c], INPUT_PULLUP);
  }
  while(!Serial);
}

void loop() {
  for (int r = 0; r < ROWS; r++) {
    digitalWrite(rowPins[r], LOW);
    for (int c = 0; c < COLS; c++) {
      bool state = digitalRead(colPins[c]) == LOW;
      if (state != keyState[r][c]) {
        keyState[r][c] = state;
        int button = r * COLS + c;
        char buf[2];
        sprintf(buf, "%d%d", button, state);
        Serial.print(buf);
        Serial.flush();
      }
    }
    digitalWrite(rowPins[r], HIGH);
  }
}

