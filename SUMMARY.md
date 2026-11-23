# Kent Pager: Design Summary

*Conversation date: 2026-11-22*

## Goal

A small, battery-powered, portable device that can send, receive and display SMS messages over a cellular network.

- A small input device for entering a phone number and a message
- A small screen for displaying messages (scrolling through long messages with the input device is fine)
- Only about **three units** will be built

## Recommended approach

For three units, assemble off-the-shelf modules instead of designing a custom PCB. Use an ESP32 handheld that already has a keyboard, screen and battery, add an LTE modem, and write about 500–1000 lines of firmware.

### Parts list (per unit, roughly $70–100)

| Part | Suggestion | Approx. cost |
|---|---|---|
| Controller, keyboard, screen | **M5Stack Cardputer (ADV)**: ESP32-S3, full QWERTY keyboard, 1.14" color LCD, LiPo charging over USB-C, Grove UART port | ~$30–40 |
| Cellular modem | **SIMCom A7670 breakout (LTE Cat-1)**: A7670SA/A7672SA for the Americas, A7670E for Europe (Waveshare or LilyGO) | ~$20–35 |
| Antenna | LTE antenna with a u.FL connector (flexible adhesive type fits inside a case) | ~$5 |
| Modem power | Separate 1000–2000 mAh LiPo, or the main battery plus a 1000 µF+ low-ESR capacitor at the modem's power input | ~$10 |
| SIM | Prepaid plan with a real phone number (see below) | varies |
| Enclosure | 3D-printed case that clips the modem board to the back of the Cardputer | – |

**Sourcing constraint:** no AliExpress purchases. The prices above are rough estimates from memory, not checked against any store, and some (the A7670 breakout, coin motor, transistor, TP4056) reflect AliExpress-level pricing. Buy from the M5Stack official store, Digi-Key, Mouser, Adafruit, SparkFun, or the official Waveshare/LilyGO storefronts on Amazon, and expect higher prices there. Prices still need checking.

### Why LTE Cat-1

- 2G and 3G are shut down in the US and much of Europe.
- NB-IoT often doesn't support normal phone-to-phone SMS.
- LTE-M works on some carriers but is spotty on consumer SIMs.
- Networks treat Cat-1 most like an ordinary phone, so texting regular numbers is most likely to work.

### Vibration alert (added requirement)

The device should vibrate when a message arrives.

- **Motor:** a 10 mm coin vibration motor (3 V, ~60–90 mA, under $1). It sticks inside the case with adhesive.
- **Driver:** a GPIO pin can't supply that current directly. Switch the motor with a small N-channel MOSFET (AO3400, or 2N7000 in a pinch) powered from the battery, with a 1N4148 or 1N5819 diode across the motor and a 1 kΩ resistor on the gate.
  - Alternative: a DRV2605L haptic driver board (~$8, I2C) gives ready-made vibration patterns, but it needs I2C pins.
- **Pin:** G1 on the Grove port (see the pin map below).
- **Firmware:** on `+CMTI`, pulse the motor (for example two 300 ms buzzes with a 200 ms gap) and add an on/off setting for vibration.

## Cardputer ADV facts and pin map

Source: https://docs.m5stack.com/en/core/Cardputer-Adv (read 2026-11-22)

- **Size:** 84.0 × 54.0 × 19.6 mm = **3.31 × 2.13 × 0.77 in**, 81 g
- **ESP32-S3FN8**, 8 MB flash, microSD slot, **1500 mAh battery**
- **Keyboard** runs through a TCA8418 I2C chip (G8/G9, interrupt on G11), so it uses almost no GPIOs.
- **Pins already used:** LCD G33–G38; audio G41–G43, G46; IR G44; battery sense G10; I2C G8/G9; microSD G12, G14, G39, G40; boot button G0
- **Free pins:** Grove G1/G2; EXT header G3, G4, G5, G6, G13, G15
  - Avoid EXT G14/G39/G40, which are shared with microSD.
  - Avoid G3, a boot strapping pin.
- **Power:** Grove 5 V, EXT 5VOUT/5VIN. There is no 3.3 V or battery pin, and no current limit is documented.

### Planned wiring

| Cardputer pin | Connects to | Purpose |
|---|---|---|
Updated for the **Waveshare SIM7670G Cat-1/GNSS HAT**, based on Claude's reading of its schematic (`SIM7670G_LTE_Cat-1-GNSS_HAT.pdf` on the Waveshare wiki, 2026-11-23):

| Cardputer pin | HAT connection | Purpose |
|---|---|---|
| G15 (EXT 14, UART_RX) | **TXD** on 3-pin header H1 (or Pi header pin 10 via DIP switch) | serial from modem |
| G13 (EXT 12, UART_TX) | **RXD** on H1 (or Pi header pin 8 via DIP switch) | serial to modem |
| G5 (EXT 13) | **PWR** = Pi header pin 7 (BCM4), DIP switch "PWR" ON | **pulse HIGH** (~1 s) to toggle modem on/off |
| G4 (EXT 3) | **RI** (3.3 V side of level shifter; *not* on the Pi header, so a wire must be soldered to a pad) | new-message wake |
| G6 (EXT 5) | **DTR** (same as RI: solder to pad) | modem sleep control |
| G1 (Grove) | MOSFET gate (via 1 kΩ) | vibration motor |
| G2 (Grove) | spare | |
| GND | HAT GND (Pi header pin 6, or H1 GND) | common ground (required) |
| — | HAT **5 V** in (Pi header pin 2/4, or USB-C) | modem power |

What the schematic shows:
- **Level shifting is built in.** A TXB0104 shifts TXD, RXD, RI and DTR between the module's 1.8 V and 3.3 V. With the TXB0104 (auto-direction, weak drive), don't add strong pull-ups on these lines.
- **Power control:** PWR → diode → NPN transistor that pulls the module's PWRKEY low, so a HIGH pulse from the ESP32 equals pressing the power key. There's also an onboard PWR_KEY button and what looks like an automatic power-on pulse circuit (this matches the wiki's description of auto-start).
- **The HAT needs 5 V.** It makes the module's ~3.8 V supply from 5 V with a 3 A LDO (SPX29302). A bare 3.7 V LiPo can't power it directly: the modem battery needs a 5 V boost board (e.g. Adafruit PowerBoost 1000C, which also charges). The LDO and the board's USB hub/LEDs waste some battery.
- Its **3-pin header H1 (TXD/GND/RXD)** is the easiest serial connection.
- RI/DTR pads and the exact DIP routing should be checked on the physical board.
- **Size 85 × 56.7 mm**, slightly larger than the Cardputer (84 × 54 mm).
- The HAT is a good fit for the **prototype**. For the final three, a smaller SIM7670G board without the USB hub would give better battery life and size.
- I2C (G8/G9) is exposed on EXT, so a DRV2605L haptic driver could share that bus if wanted.

## Pitfalls

1. **Current spikes.** LTE modems draw up to about 2 A in short bursts when transmitting. The Cardputer's Grove 5 V line can't supply that, so the modem browns out and resets, usually while sending. Give the modem its own LiPo or a solid regulator with a large capacitor.
2. **Carrier and SIM.**
   - Many IoT SIMs (Hologram, 1NCE, Soracom) only send SMS through their web API or have no regular phone number. Avoid them.
   - Prepaid consumer plans with SMS work better. In the US, T-Mobile-based prepaid plans tend to accept uncertified modules. Verizon often blocks devices whose IMEI isn't on its approved list. AT&T is somewhere in between.
   - Test one SIM in one prototype before buying three.
3. **Antenna.** Keep it away from the battery and the ESP32, and never power the modem on without an antenna connected.

## Firmware outline

Use Arduino or PlatformIO on the ESP32-S3 with the `M5Cardputer` library, and talk to the modem directly with AT commands.

- **Setup:** `AT+CMGF=1` (text mode), `AT+CNMI=2,1,0,0,0` (new-message alerts), `AT+CPMS` (message storage)
- **Receive:** the modem sends `+CMTI: "SM",<n>`. Read it with `AT+CMGR=<n>`, save it to flash, and beep or flash the LED.
- **Send:** `AT+CMGS="+15551234567"`, wait for the `>` prompt, send the text, then Ctrl-Z (0x1A).
- **User interface:** an inbox list, a message view scrolled with the keyboard's arrow keys, a compose screen with number and message fields, and a few stored contacts.
- **Power:** put the modem to sleep (`AT+CSCLK=1` plus the DTR pin), let it wake the ESP32 through its RI pin, and turn the screen off after a timeout. Expect one to three days per charge, depending on signal strength.
- TinyGSM can handle sending, but receiving through raw AT commands is simpler and more reliable.

## Alternatives considered

- **LilyGO T-Deck** (2.8" screen, BlackBerry-style keyboard, trackball) with the same A7670 breakout. It's bigger, but the larger screen makes reading easier.
- **A basic 4G feature phone** (~$30), if building the device isn't the point.

## Decision: US only, low-cost carrier

**Network:** T-Mobile, through a low-cost prepaid reseller (MVNO). T-Mobile is the most tolerant US network for devices that aren't phones, and most cheap resellers run on it. Verizon resellers are the most likely to reject the modem's IMEI.

**Modem bands:** the modem must support LTE bands **2, 4, 12 and 66**, and ideally **71** (T-Mobile's rural low band). Check the band list on the exact module's datasheet before buying.
- Some A7670 variants (A7670SA) leave out band 12, which hurts coverage in fringe areas. A7670G is listed with band 12, but confirm this on its datasheet.
- A more expensive, US-certified option: Quectel EC21-A / EG21-G or SIMCom SIM7600A-H.

**Modem board choice (web search, 2026-11-23):**
- **A7670 is out for the US.** Makerfabs states the A7670 isn't registered in the USA and recommends SIM7600 instead. The A7670E variants also lack band 12.
- **Recommended: Waveshare SIM7670G LTE Cat-1 HAT**, ~$44 at waveshare.com (one guide reported ~$60 and low stock, so check the live price). Global bands include B2/B4/B12/B13/B66 (listed for Waveshare's ESP32-S3-SIM7670G board; confirm on the HAT page). It's a Raspberry Pi HAT, but it works with any 3.3 V UART and has USB for desk testing. At about 65 × 56 mm, it's roughly the Cardputer's footprint. SIM7670G's US carrier approval is still unverified.
- **Fallback: SIM7600A-H** (US-specific, B2/B4/B12, Cat-4). The Waveshare HAT ($69.99) is discontinued; eBay copies run ~$40–60. It draws more power.
- The pin map's A7670 references now apply to the SIM7670G. Its pin names are similar, but check its own docs.

**US certification of the modems considered (web search, 2026-11-23; sources partly old or conflicting):**

| Module | FCC | PTCRB | US carriers |
|---|---|---|---|
| **SIM7670G** (Waveshare HAT) | Yes, FCC ID 2AJYU-8XS0002 (2023) | Yes | AT&T, T-Mobile (Verizon was pending, per a ~2-year-old SIMCom post) |
| SIM7600A-H | Yes | Yes | AT&T only confirmed; T-Mobile/Verizon unclear |
| SIM7600NA-H (a different variant) | Yes | Yes | AT&T, T-Mobile, Verizon, US Cellular |
| Quectel EC21-A | Yes | Yes | AT&T, T-Mobile |
| Quectel EG21-G | Yes | Yes | AT&T, T-Mobile, Verizon (sources mixed) |
| A7670 family (E/G/SA) | Claimed for SA variants, conflicting | None found | None found; Makerfabs says not registered for US |

- FCC = legal to transmit in the US. PTCRB = industry certification the carriers expect. Carrier approval = tested on that network.
- **SIM7670G is certified for T-Mobile**, which supports the Tello plan.
- Certification covers the module; a hobby breakout or HAT isn't separately certified, which is normal for prototypes.
- **PTCRB confirmed (2026-11-23):** the user checked ptcrb.com/certified-devices. SIM7670G is listed, with a most recent certification date of **06/26/2026**. (Claude couldn't reach the database directly: it renders with JavaScript and blocks automated requests.)

**Plan:** a talk-and-text plan, or the cheapest plan available, since the device needs no data. Candidates (prices change, so check current offers):
- **Tello**: cheap custom plans, pay monthly
- **SpeedTalk Mobile**: very cheap SMS-only and pay-as-you-go plans, used to IoT devices
- **US Mobile**: lets you pick the network (choose its T-Mobile network)
- **Mint Mobile**: cheapest when you prepay 12 months
- Confirm the plan doesn't expire after a period of inactivity.

**Leading choice: Tello, $5/month** (found by the user, not checked by Claude). At https://tello.com/buy/custom_plans, choose "No data" and "300 minutes". Tello runs on T-Mobile.
- Order a **physical SIM**. An eSIM can't be moved into the modem.
- Confirm texts are unlimited (or enough) on that plan, check taxes and fees, and set up auto-renew so the number isn't lost.
- Three devices means 3 × $5 = $15/month plus taxes.

**How tolerant T-Mobile is (Claude's general knowledge, unverified):**
- T-Mobile generally doesn't keep an approved-device list the way Verizon does. Any module with a valid IMEI and FCC certification usually connects.
- The main risk is **SMS on an LTE-only network**. Texts go either over the older fallback path or over IMS (the system behind VoLTE), and that depends on the module's firmware and the carrier's settings. Most hobby reports say A7670/SIM7600-class modules text fine on T-Mobile, but it isn't guaranteed. Voice calls are more likely to fail, but the device doesn't need them.
- Tello's terms of service may say the plan is for phones. Check them.

**Activation:** if the carrier's online IMEI check rejects the modem, activate the SIM in an ordinary unlocked phone first, then move it to the device. Do not change the modem's IMEI.

**Test (cheapest first step):** a USB adapter board for the modem plus a serial terminal on a computer is enough to prove SMS works before building anything else. With one SIM in one prototype, check `AT+CREG?` / `AT+CEREG?` (registration), `AT+CSQ` (signal), then send and receive a text before buying the other two SIMs.

## Open items / next steps

1. ~~Decide country and carrier.~~ US only; low-cost T-Mobile reseller (see above). Still to do: pick the specific reseller and confirm the modem variant's band list.
2. Build and test **one** complete unit, sending and receiving, before ordering parts for the other two.
3. Firmware: Claude offered to write a PlatformIO project in this folder (inbox, compose and scrolling screens, modem driver) once the hardware is chosen.
