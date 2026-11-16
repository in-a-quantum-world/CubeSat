# ESP32 ↔ STM32 Protocol Spec

Version 0.1 (draft) · Owner: Kai · Status: not yet agreed

## 1. Purpose and scope



## 2. Physical layer (pins, SPI mode, clock, data ready)
Pins: CS IO10→PA4, SCK IO12→PA5, MOSI IO11→PA7, MISO IO13←PA6, data ready PD10→IO4
SPI settings: mode 0, MSB first, start at 1 MHz, up to about 10 MHz
Roles: the ESP32 is master
Data ready: one line on what it means, when it goes high, and when it goes low (that part is yours to define)

## 3. Frame format

| Byte(s) | Field | Size (bytes) | Notes |
|---|---|---|---|
| 0 | Start | 1 | Always 0xA5. The parser skips bytes until it sees this. |
| 1 | Command | 1 | Which kind of message it is |
| 2 | Length | 1 | (PROPOSED) Value N, where N: number of payload bytes |
| 3 to N+2 | Payload | N (0-255) | Layout depends on the command. Maximum payload is 255 bytes. See §4 for byte order and units, §5 for layouts. |
| N+3 to N+4 | CRC | 2 | (PROPOSED) CRC-16/CCITT-FALSE over Command + Length + Payload, high byte first |

## 4. Numbers, byte order and units
## 5. Commands and reply layouts
## 6. ACK, NACK and errors
## 7. Timing
## 8. Worked examples (hex)
## 9. Open questions and version history