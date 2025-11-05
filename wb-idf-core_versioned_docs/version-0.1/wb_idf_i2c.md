---
id: wb_idf_i2c
title: I2C Master Driver
sidebar_label: I2C Master Driver
---

# I2C Master Driver

High-level I2C master functions for ESP-IDF.

Comprehensive I2C master functionality for ESP-IDF.

This module provides a comprehensive I2C master driver with support for: 

- Bus initialization and device management
- Byte-level read/write operations
- Bit-level manipulation
- Word (16-bit) operations

Bus initialization and device management

Byte-level read/write operations

Bit-level manipulation

Word (16-bit) operations

The component provides a high-level, easy-to-use interface for I2C master operations on ESP32 platforms. It builds on top of the ESP-IDF I2C driver with additional convenience functions and safety features.

- ✅ - Support for I2C_NUM_0 and I2C_NUM_1
- ✅ - Easy device handle creation and management
- ✅ - Automatic device detection and validation
- ✅ - Single and multi-byte read/write
- ✅ - Read/write individual bits or bit ranges
- ✅ - 16-bit register access with endianness support
- ✅ - Comprehensive error checking and reporting
- ✅ - Mutex-protected bus access

✅ - Support for I2C_NUM_0 and I2C_NUM_1

✅ - Easy device handle creation and management

✅ - Automatic device detection and validation

✅ - Single and multi-byte read/write

✅ - Read/write individual bits or bit ranges

✅ - 16-bit register access with endianness support

✅ - Comprehensive error checking and reporting

✅ - Mutex-protected bus access

The component follows a layered architecture:

The I2C API is organized into the following functional modules. Click on each module to see the detailed API documentation:

Functions for setting up I2C buses and managing device handles. Covers bus initialization, device creation, and device detection.

Standard byte-level I/O operations for reading and writing registers. Includes single-byte and multi-byte transfers.

Bit-level register manipulation for fine-grained control. Enables reading and writing individual bits or bit ranges.

16-bit register access with automatic byte order handling. Supports both big-endian and little-endian devices.

- Set up I2C bus → See `Initialization & Management`

- Create handle for your I2C device → See `Initialization & Management`

- Use `Byte Operations` , `Bit Operations` , or `Word Operations (16-bit)` operations

- Delete device handle and bus handle → See `Initialization & Management`

For detailed API documentation and code examples, see the individual module pages.

- External pull-ups required on SCL and SDA (typically 4.7kΩ)
- 3.3V (ESP32 standard) or device-specific voltage
- Keep I2C traces short (<30cm for 400kHz operation)
- **Bus Capacitance:** Total capacitance should be <400pF for standard mode

External pull-ups required on SCL and SDA (typically 4.7kΩ)

3.3V (ESP32 standard) or device-specific voltage

Keep I2C traces short (<30cm for 400kHz operation)

**Bus Capacitance:** Total capacitance should be <400pF for standard mode

Mode

Speed

Maximum Cable Length

Standard

100 kHz

~1 meter

Fast

400 kHz

~30 cm

Fast Plus

1 MHz

~10 cm

Complete working examples are available in the repository:

- - Simple read/write operations demonstration
- - Scan I2C bus for connected devices
- - Complete MPU6050 accelerometer/gyro integration
- - Bit-level register operations examples
- - Multiple devices on same bus

- Simple read/write operations demonstration

- Scan I2C bus for connected devices

- Complete MPU6050 accelerometer/gyro integration

- Bit-level register operations examples

- Multiple devices on same bus

If device probing fails: 

- Check physical wiring connections
- Verify pull-up resistors are present (4.7kΩ typical)
- Confirm device address is correct (7-bit format)
- Check device power supply
- Try scanning the bus (see examples)

Check physical wiring connections

Verify pull-up resistors are present (4.7kΩ typical)

Confirm device address is correct (7-bit format)

Check device power supply

Try scanning the bus (see examples)

If transactions timeout or fail: 

- Reduce clock speed (try 100kHz instead of 400kHz)
- Shorten cable length
- Check for electrical noise
- Verify device supports selected clock speed
- Add capacitors near device power pins

Reduce clock speed (try 100kHz instead of 400kHz)

Shorten cable length

Check for electrical noise

Verify device supports selected clock speed

Add capacitors near device power pins

If data readings are inconsistent: 

- Add delays between operations
- Check for ground loops
- Verify device timing requirements
- Reduce clock speed for longer cables
- Use shielded cables in noisy environments

Add delays between operations

Check for ground loops

Verify device timing requirements

Reduce clock speed for longer cables

Use shielded cables in noisy environments

If bus stops responding: 

- Reinitialize bus (delete and recreate)
- Power cycle the device
- Check for devices holding SDA low
- Implement bus recovery procedure

Reinitialize bus (delete and recreate)

Power cycle the device

Check for devices holding SDA low

Implement bus recovery procedure

- Typical transaction overhead: 200-500 µs at 100kHz
- Multi-byte transfers are more efficient than single-byte
- Bus operations are mutex-protected (small thread-safety overhead)
- DMA support planned for future release

Typical transaction overhead: 200-500 µs at 100kHz

Multi-byte transfers are more efficient than single-byte

Bus operations are mutex-protected (small thread-safety overhead)

DMA support planned for future release

- 5.0 or higher required
- ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- I2C_NUM_0 and I2C_NUM_1 (if available on SoC)

5.0 or higher required

ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6

I2C_NUM_0 and I2C_NUM_1 (if available on SoC)

- All device addresses use 7-bit format (not including R/W bit)
- Bus operations are automatically thread-safe
- Device handles must be deleted before deleting bus handle
- Maximum clock speed depends on bus capacitance and device
- Pull-up resistors are required (not optional)

All device addresses use 7-bit format (not including R/W bit)

Bus operations are automatically thread-safe

Device handles must be deleted before deleting bus handle

Maximum clock speed depends on bus capacitance and device

Pull-up resistors are required (not optional)

- - Official I2C bus specification
- - Low-level driver docs
- - Source code and examples
- - Bug reports and features

- Official I2C bus specification

- Low-level driver docs

- Source code and examples

- Bug reports and features

For questions, bug reports, or feature requests: 

- Open an issue on
- Check existing issues and discussions
- Email:

Open an issue on

Check existing issues and discussions

Email:

Contributions are welcome! Please see for guidelines.

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See for details.

## Sub-Modules

- [Initialization & Management](./Initialization & Management)
- [Byte Operations](./Byte Operations)
- [Bit Operations](./Bit Operations)
- [Word Operations (16-bit)](./Word Operations (16-bit))
