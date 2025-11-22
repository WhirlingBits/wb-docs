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

## Overview

The **wb-idf-i2c** component provides a high-level, easy-to-use interface for I2C master operations on ESP32 platforms. It builds on top of the ESP-IDF I2C driver with additional convenience functions and safety features.

## Features

- ✅ Multiple I2C Buses - Support for I2C_NUM_0 and I2C_NUM_1
- ✅ Device Management - Easy device handle creation and management
- ✅ Device Probing - Automatic device detection and validation
- ✅ Byte Operations - Single and multi-byte read/write
- ✅ Bit Manipulation - Read/write individual bits or bit ranges
- ✅ Word Operations - 16-bit register access with endianness support
- ✅ Error Handling - Comprehensive error checking and reporting
- ✅ Thread-Safe - Mutex-protected bus access

## Architecture

The component follows a layered architecture:

```
* ┌─────────────────────────────────────┐
* │      Your Application               │
* └──────────────┬──────────────────────┘
*                │
* ┌──────────────▼──────────────────────┐
* │  wb-idf-i2c High-Level API          │ ← This Component
* ├─────────────────────────────────────┤
* │  - Device Management                │
* │  - Byte/Bit/Word Operations         │
* │  - Error Handling                   │
* └──────────────┬──────────────────────┘
*                │
* ┌──────────────▼──────────────────────┐
* │  ESP-IDF I2C Master Driver          │
* └──────────────┬──────────────────────┘
*                │
* ┌──────────────▼──────────────────────┐
* │  I2C Hardware (ESP32 Peripheral)    │
* └─────────────────────────────────────┘
* 
```

## API Modules

The I2C API is organized into the following functional modules. Click on each module to see the detailed API documentation:

### @ref wb_idf_i2c_init "Initialization & Management"

Functions for setting up I2C buses and managing device handles. Covers bus initialization, device creation, and device detection.

### @ref wb_idf_i2c_byte "Byte Operations"

Standard byte-level I/O operations for reading and writing registers. Includes single-byte and multi-byte transfers.

### @ref wb_idf_i2c_bit "Bit Operations"

Bit-level register manipulation for fine-grained control. Enables reading and writing individual bits or bit ranges.

### @ref wb_idf_i2c_word "Word Operations (16-bit)"

16-bit register access with automatic byte order handling. Supports both big-endian and little-endian devices.

## Typical Usage Workflow

For detailed API documentation and code examples, see the individual module pages.

## Hardware Setup

### Typical Wiring

```
* ESP32                     I2C Device
* ┌────────┐               ┌────────┐
* │  SCL   │───────────────│  SCL   │
* │  (22)  │    ┌─[4.7kΩ]─│        │
* │        │    │          │        │
* │  SDA   │────┼──────────│  SDA   │
* │  (21)  │    │ ┌─[4.7kΩ]│        │
* │        │    │ │        │        │
* │  GND   │────┼─┼────────│  GND   │
* │        │    │ │        │        │
* │  3.3V  │────┴─┴────────│  VCC   │
* └────────┘               └────────┘
* 
* Pull-up Resistors: 4.7kΩ typical (range: 2.2kΩ - 10kΩ)
* 
```

### Requirements

- Pull-up Resistors: External pull-ups required on SCL and SDA (typically 4.7kΩ)
- Operating Voltage: 3.3V (ESP32 standard) or device-specific voltage
- Cable Length: Keep I2C traces short (<30cm for 400kHz operation)
- **Bus Capacitance:** Total capacitance should be <400pF for standard mode

### Supported Speeds

| Mode | Speed | Maximum Cable Length |
|---|---|---|
| Standard | 100 kHz | ~1 meter |
| Fast | 400 kHz | ~30 cm |
| Fast Plus | 1 MHz | ~10 cm |

## Examples

Complete working examples are available in the repository:

- basic_read_write - Simple read/write operations demonstration
- device_scanning - Scan I2C bus for connected devices
- mpu6050 - Complete MPU6050 accelerometer/gyro integration
- bit_manipulation - Bit-level register operations examples
- multi_device - Multiple devices on same bus

## Troubleshooting

### Device Not Found

If device probing fails:



- Check physical wiring connections
- Verify pull-up resistors are present (4.7kΩ typical)
- Confirm device address is correct (7-bit format)
- Check device power supply
- Try scanning the bus (see examples)

### Communication Errors

If transactions timeout or fail:



- Reduce clock speed (try 100kHz instead of 400kHz)
- Shorten cable length
- Check for electrical noise
- Verify device supports selected clock speed
- Add capacitors near device power pins

### Data Corruption

If data readings are inconsistent:



- Add delays between operations
- Check for ground loops
- Verify device timing requirements
- Reduce clock speed for longer cables
- Use shielded cables in noisy environments

### Bus Lock-up

If bus stops responding:



- Reinitialize bus (delete and recreate)
- Power cycle the device
- Check for devices holding SDA low
- Implement bus recovery procedure

## Performance Notes

- Typical transaction overhead: 200-500 µs at 100kHz
- Multi-byte transfers are more efficient than single-byte
- Bus operations are mutex-protected (small thread-safety overhead)
- DMA support planned for future release

## Compatibility

- ESP-IDF Version: 5.0 or higher required
- Supported SoCs: ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- I2C Ports: I2C_NUM_0 and I2C_NUM_1 (if available on SoC)

## Important Notes

- All device addresses use 7-bit format (not including R/W bit)
- Bus operations are automatically thread-safe
- Device handles must be deleted before deleting bus handle
- Maximum clock speed depends on bus capacitance and device
- Pull-up resistors are required (not optional)

## Additional Resources

- I2C Specification (PDF) - Official I2C bus specification
- ESP-IDF I2C Driver - Low-level driver docs
- GitHub Repository - Source code and examples
- Issue Tracker - Bug reports and features

## Support

For questions, bug reports, or feature requests:



- Open an issue on GitHub
- Check existing issues and discussions
- Email: support@whirlingbits.com

## Contributing

Contributions are welcome! Please see for guidelines.

## License

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See for details.

## Sub-Modules

- [Initialization & Management](./wb_idf_i2c_init)
- [Byte Operations](./wb_idf_i2c_byte)
- [Bit Operations](./wb_idf_i2c_bit)
- [Word Operations (16-Bit)](./wb_idf_i2c_word)
