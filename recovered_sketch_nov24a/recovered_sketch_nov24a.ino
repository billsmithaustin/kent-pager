#include <Arduino.h>
#include <M5Cardputer.h>
#include <FastLED.h>
#include "owl_wav.h"   // screech owl clip (owl_pcm, owl_len, owl_rate)

// Cardputer-Adv Pin Definitions
#define LED_PIN     21   // RGB LED data pin
#define PWR_EN_PIN  38   // Power enable switch for the LED and backlight
#define ULTRASONIC_PIN 1 

#define NUM_LEDS    1    // The Cardputer has 1 onboard SK6812 RGB LED

CRGB leds[NUM_LEDS];

// Helper to return the screen back to its default clean developer state
void resetDisplay() {
  M5.Display.fillScreen(BLACK);
  M5.Display.setTextColor(GREEN);
  M5.Display.setTextSize(2);
  M5.Display.setCursor(10, 10);
  M5.Display.print("System Armed...");
}

// Shows BACK OFF and plays the screech owl clip (durationMs is no longer used:
// the clip always plays to the end, about 1.7 s)
void triggerAlert(int durationMs) {
  // 1. Paint the background solid RED
  M5.Display.fillScreen(RED);
  M5.Display.setTextColor(WHITE);
  
  // 2. Center and print "BACK OFF" in a large font size
  M5.Display.setTextSize(4); // Large, blocky text
  
  // Quick calculation to center text horizontally/vertically on Cardputer screen
  int textWidth = M5.Display.textWidth("BACK OFF");
  int startX = (M5.Display.width() - textWidth) / 2;
  int startY = (M5.Display.height() - 32) / 2; // ~32 pixels tall for size 4 font
  
  M5.Display.setCursor(startX, startY);
  M5.Display.print("BACK OFF");

  
  // 3. Play the owl clip and wait for it to finish
  M5.Speaker.playRaw(owl_pcm, owl_len, owl_rate);
  while (M5.Speaker.isPlaying()) delay(10);

  // 4. Return screen to normal terminal mode after alert finishes
  resetDisplay();
}



void setup() {
    auto cfg = M5.config();
    M5.begin(cfg);

    // Serial.begin(115200); 
    // // Optional: Wait for the serial monitor window to open before printing
    // while (!Serial) { delay(10); } 

    // 1. CRITICAL: Enable power to the LED peripheral circuit
    pinMode(PWR_EN_PIN, OUTPUT);
    digitalWrite(PWR_EN_PIN, HIGH); 

    // 2. Initialize FastLED (Cardputer uses GRB color order)
    FastLED.addLeds<WS2812B, LED_PIN, GRB>(leds, NUM_LEDS);
    FastLED.setBrightness(50); // Set brightness (0-255) to protect your eyes

    M5.Speaker.begin();
    M5.Speaker.setVolume(160); // Set volume (0 to 255)

    // Initial clean screen layout
    resetDisplay();

    // Serial.println("M5Cardputer Initialized Successfully!");
}


void loop() {
  unsigned long duration;
  float cm;

  // 1. Send the standard 10ms Trigger Pulse
  pinMode(ULTRASONIC_PIN, OUTPUT);
  digitalWrite(ULTRASONIC_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(ULTRASONIC_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(ULTRASONIC_PIN, LOW);

  // 2. FLIP TO INPUT
  pinMode(ULTRASONIC_PIN, INPUT_PULLUP);

  // 4. Read the true returning echo pulse
  duration = pulseIn(ULTRASONIC_PIN, HIGH, 25000); // 30ms timeout max
  yield(); // Free up FreeRTOS tasks to completely prevent canary crashes

  // 5. Convert and alert
  if (duration > 0) {
    float cm = (duration * 0.0343) / 2.0;
    // Serial.printf("Distance: %f cm\n", cm);

    if (cm < (12 * 2.54)) {
      leds[0] = CRGB::Red;

      triggerAlert(300);
    } else if (cm < (15 * 2.54)) {
      leds[0] = CRGB::Blue;
    } else {
      leds[0] = CRGB::Green;
    }
    FastLED.show();
  } else {
    // Serial.println("[INFO] Reading timed out (Object too far away)");
  }

  delay(250); // Steady polling rate
}
