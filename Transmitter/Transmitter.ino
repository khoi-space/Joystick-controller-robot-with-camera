// Thanks to https://www.whizzbizz.com/en/joystick.nrf24
#include "nRF24L01.h"
#include "RF24.h"
#include "SPI.h"

#define DEBUG
#undef LISTEN_FROM_RECEIVER

#define CE_PIN  9
#define CSN_PIN 10

#define btn_a   2
#define btn_b   3
#define btn_c   4
#define btn_d   5
#define btn_e   7
#define btn_f   6
#define btn_joy 8
#define joy_x   A0
#define joy_y   A1

int btns[] = { btn_a, btn_b, btn_c, btn_d, btn_e, btn_f, btn_joy };

byte addr[][6] = {"pipe1", "pipe2"}; // Set addr for read and write
RF24 radio(CE_PIN, CSN_PIN);
int joystick[9];
int received_val;

void setup() {
  for (int i = 0; i < 7; ++i) {
    pinMode(btns[i], INPUT_PULLUP);
    digitalWrite(btns[i], HIGH);
  }
#ifdef DEBUG
  Serial.begin(115200);
#endif

  // Setup NRF24L01
  radio.begin();
  radio.openWritingPipe(addr[0]);
  radio.openReadingPipe(1, addr[1]);
  radio.setDataRate(RF24_250KBPS);
  radio.setPALevel(RF24_PA_MIN);
  radio.setRetries(3, 5);
  radio.setChannel(110);
}

void loop() {
  for (int i = 0; i < 7; ++i) {
    joystick[i] = digitalRead(btns[i]);
  }

  // Read joystick values
  joystick[7] = analogRead(joy_x);
  joystick[8] = analogRead(joy_y);

  // Write out values
  radio.write(joystick, sizeof(joystick));
  delay(20);

#ifdef DEBUG
  // Log data
  for (int i = 0; i < 9; ++i) {
    if (i) Serial.print(" | ");
    Serial.print(joystick[i]);
  }
  Serial.println();
#endif


#ifdef LISTEN_FROM_RECEIVER
  // Read data from FPGA
  radio.startListening();
  if (radio.available()) {
    radio.read(&received_val, sizeof(received_val));
#ifdef DEBUG
    Serial.print("receive=");
    Serial.println(received_val);
#endif
  }
  delay(20);
  radio.stopListening();
#endif
}
