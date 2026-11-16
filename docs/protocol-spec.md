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
## 6. ACK, NACK and errors
## 7. Timing
## 8. Worked examples (hex)
## 9. Open questions and version history
**(OPEN) Axis Order and Sign Convention.** TBC by Anisha/Naoki?