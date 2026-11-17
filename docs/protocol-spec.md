# ESP32 ↔ STM32 Protocol Spec

Version 0.1 (draft) · Owner: Kai · Status: not yet agreed

## 1. Purpose and scope



## 2. Physical layer (pins, SPI mode, clock, data ready)
| Signal | ESP32-S3 pin | STM32 pin | Direction | Purpose |
|---|---|---|---|---|
| CS | IO10 | PA4 | ESP32-S3 to STM32 | Indicates when ESP32-S3 starts/finishes speaking to STM32. low: speaking. high: idle |
| SCK | IO12 | PA5 | ESP32-S3 to STM32 | Clock |
| MOSI | IO11 | PA7 | ESP32-S3 to STM32 | Sends bits from ESP32-S3 to STM32 |
| MISO | IO13 | PA6 | STM32 to ESP32-S3 | Sends bits from STM32 to ESP32-S3 |
| Data Ready | IO4 | PD10 | STM32 to ESP32-S3 | Indicator for when STM32 reply is loaded and waiting to be read |

### SPI settings
- Mode: 0
- Bit order: MSB first
- Clock: Start at 1 MHz, up to about 10 MHz

### Roles
- Master: ESP32-S3
- Slave: STM32

### (PROPOSED) Data ready
- High: Reply loaded and waiting to be clocked out.
- Low: After the last reply byte has been clocked out.
  - The ESP32-S3 starts reading and gives up halfway, the line stays high, so the ESP32-S3 can see the reply is still waiting and read again.
- No new requests while high.
  - The ESP32-S3 must read the reply before sending a new request. 
- Timeout if it never goes high.
  - The ESP32-S3 waits up to a timeout (value in §7) then retries.


## 3. Frame format

| Byte(s) | Field | Size (bytes) | Notes |
|---|---|---|---|
| 0 | Start | 1 | Always 0xA5. The parser skips bytes until it sees this. |
| 1 | Command | 1 | Which kind of message it is |
| 2 | Length | 1 | (PROPOSED) Value N, where N: number of payload bytes |
| 3 to N+2 | Payload | N (0-255) | Layout depends on the command. Maximum payload is 255 bytes. See §4 for byte order and units, §5 for layouts. |
| N+3 to N+4 | CRC | 2 | (PROPOSED) CRC-16/CCITT-FALSE over Command + Length + Payload, high byte first |


## 4. Numbers, byte order and units

**(PROPOSED) Angles use float32.** Reason: Proposed in team docs, float32 sends decimals directly

**(PROPOSED) Multi-byte numbers are little endian.** Reason: Both chips store numbers little-endian natively

**(PROPOSED) Angles in degrees.** Reason: Easy for people to read in logs, the GUI and the PDR slides

**(OPEN) Axis Order and Sign Convention.** TBC by Anisha/Naoki?


## 5. Commands and reply layouts

| Command | Name | Request payload | Reply |
|---|---|---|---|
| 0x01 | SET_ATTITUDE | 2 × float32 target angles (8 bytes) | ACK/NACK (see §6) |
| 0x02 | READ_SENSORS | None (N = 0) | Acceleration, gyro, wheel speeds, bus voltage and current |
| 0x03 | GET_ATTITUDE | None (N = 0) | Roll, pitch, yaw and timestamp |
| 0x04 | STATUS | None (N = 0) | State and fault flags |

### 0x01 SET_ATTITUDE: request payload (N = 8)

| Offset | Field | Type | Units |
|---|---|---|---|
| 0–3 | Target angle, axis 1 | float32 (little-endian) | degrees |
| 4–7 | Target angle, axis 2 | float32 (little-endian) | degrees |

### 0x02 READ_SENSORS: reply payload (N = 40)

(PROPOSED) Units for all fields.

| Offset | Field | Type | Units |
|---|---|---|---|
| 0–3 | Accel X | float32 (little-endian) | m/s² |
| 4–7 | Accel Y | float32 (little-endian) | m/s² |
| 8–11 | Accel Z | float32 (little-endian) | m/s² |
| 12–15 | Gyro X | float32 (little-endian) | deg/s |
| 16–19 | Gyro Y | float32 (little-endian) | deg/s |
| 20–23 | Gyro Z | float32 (little-endian) | deg/s |
| 24–27 | Wheel speed, axis 1 | float32 (little-endian) | rpm |
| 28–31 | Wheel speed, axis 2 | float32 (little-endian) | rpm |
| 32–35 | Bus voltage | float32 (little-endian) | V |
| 36–39 | Bus current | float32 (little-endian) | A |

### 0x03 GET_ATTITUDE: reply payload (N = 16)

| Offset | Field | Type | Units |
|---|---|---|---|
| 0–3 | Roll | float32 (little-endian) | degrees |
| 4–7 | Pitch | float32 (little-endian) | degrees |
| 8–11 | Yaw | float32 (little-endian) | degrees |
| 12–15 | Timestamp | (PROPOSED) uint32 (little-endian) | (PROPOSED) ms since STM32 power-on |

### 0x04 STATUS: reply payload (N = 2)

| Offset | Field | Type | Units |
|---|---|---|---|
| 0 | State | uint8 | — (see state values below) |
| 1 | Fault flags | uint8 | — (bit layout: OPEN, see errors and safety) |

**(PROPOSED) State values**

| Value | State | Meaning |
|---|---|---|
| 0 | BOOT | System is switched on, starting up (checking IMU, motors not running yet) |
| 1 | RUNNING | Balancing and following target from SET_ATTITUDE |
| 2 | SAFE | Link lost, cube is in agreed safe behaviour |
| 3 | FAULT | Hardware problem (IMU, motor etc.) |

(OPEN) Does SAFE return to RUNNING automatically when commands resume? See errors and safety.


## 6. ACK, NACK and errors

**(PROPOSED)**

### Rule
Replies repeat the request's command code so the ESP32-S3 can check the reply matches, and knows how to read the reply payload.

### Reply types

| Situation | Reply command byte | Payload |
|---|---|---|
| Request OK (SET_ATTITUDE) | 0x01 (echo) | 1 byte: 0x00 (ACK) |
| Request OK (GET/READ/STATUS) | 0x02/0x03/0x04 (echo) | See §5 |
| Request bad | 0xFF (NACK) | 1 byte: status code (refer below) |

### Status codes

| Code | Meaning |
|---|---|
| 0x00 | ACK |
| 0x01 | Bad CRC |
| 0x02 | Unknown command |
| 0x03 | Wrong length |

### Retries

- (PROPOSED) Upon NACK, the ESP32-S3 resends up to 3 tries (final value in §7), then reports a comms fault to the laptop.
- (PROPOSED) If reply itself arrives at the ESP32-S3 with bad CRC/no arrival within the data-ready timeout (§7): Treat it as failed attempt, try resend (counted as one of 3 tries). 


## 7. Timing

**(PROPOSED)** All values assume SPI at 1 MHz.

### Transfer times

Formula: Time on the wire (µs) = bytes × 8 ÷ clock (MHz)

| Frame | Bytes | Time at 1 MHz |
|---|---|---|
| GET_ATTITUDE request | 5 | 40 µs |
| GET_ATTITUDE reply | 21 | 168 µs |

### Timeouts and limits

| Item | Value | Reason |
|---|---|---|
| Data-ready timeout | 5 ms | 1 ms worst case, 5× safety margin |
| Retry limit | 3 tries | 3 × 5 ms = 15 ms, enough tries to ride out brief glitch and quickly report a real fault |
| Poll rate | 100 Hz (every 10 ms) | Upper limit of team's suggested 50-100 Hz plan |
| Minimum gap between frames | 100 µs after CS goes high (TBC by Role 3) | Gives STM32 ample time to re-arm DMA for incoming bytes |

### Missed polls

- If retries run past the next poll time: Skip missed polls
  - Old readings become obsolete once there are newer readings
  - Sending old polls wastes bus time and delays the fresh reading


## 8. Worked examples (hex)

### SET_ATTITUDE: axis 1 = 10°, axis 2 = 0°

Full frame: `A5 01 08 00 00 20 41 00 00 00 00 29 B2`  (13 bytes)

| Byte(s) | Value | Meaning |
|---|---|---|
| 0 | A5 | Start |
| 1 | 01 | Command: SET_ATTITUDE |
| 2 | 08 | Length N |
| 3–6 | 00 00 20 41 | Axis 1 = 10.0 (float32, little-endian) |
| 7–10 | 00 00 00 00 | Axis 2 = 0.0 (float32, little-endian) |
| 11–12 | 29 B2 | CRC-16/CCITT-FALSE, high byte first |

Checked with Python struct.pack('<ff', 10.0, 0.0) and binascii.crc_hqx(data, 0xFFFF) (CRC computed over bytes 1–10)

## 9. Open questions and version history
**(OPEN) Axis Order and Sign Convention.** TBC by Anisha/Naoki?