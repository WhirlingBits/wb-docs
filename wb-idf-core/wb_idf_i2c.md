---
id: wb_idf_i2c
title: I2C Master Driver
sidebar_label: I2C Master Driver
---

# I2C Master Driver

Advanced I2C Master functionality for ESP-IDF.

## Overview

The **I2C Master Driver** provides a comprehensive, high-level interface for I2C communication on ESP32 platforms. It extends the standard ESP-IDF I2C driver with additional convenience functions, better error handling, and multi-bus support.

This driver is designed for production use with focus on:



- Ease of Use : Simple, intuitive API
- Reliability : Comprehensive error checking
- Performance : Optimized for low latency
- Thread Safety : Safe for concurrent access

## Key Features

- ✅ Multi-Bus Support : Control multiple I2C buses (I2C_NUM_0, I2C_NUM_1)
- ✅ Device Management : Easy device handle creation and lifecycle management
- ✅ Device Probing : Automatic detection and validation of I2C devices
- ✅ Byte Operations : Single and multi-byte register read/write
- ✅ Bit Manipulation : Read and write individual bits or bit ranges
- ✅ Word Operations : Native 16-bit register access with endianness handling
- ✅ Error Handling : Detailed error codes and logging
- ✅ Thread-Safe : Internal mutex protection for concurrent access

## Architecture

The driver follows a layered architecture:

```text
┌─────────────────────────────────────┐
│ApplicationLayer│
│(Yoursensor/devicedrivers)│
└──────────────┬──────────────────────┘
│
┌──────────────▼──────────────────────┐
│wb-idf-i2cHigh-LevelAPI│←ThisComponent
├─────────────────────────────────────┤
│•DeviceManagement│
│•Byte/Bit/WordOperations│
│•ErrorHandling&Validation│
└──────────────┬──────────────────────┘
│
┌──────────────▼──────────────────────┐
│ESP-IDFI2CMasterDriver│
│(driver/i2c_master.h)│
└──────────────┬──────────────────────┘
│
┌──────────────▼──────────────────────┐
│I2CHardwarePeripheral│
│(ESP32I2CController)│
└─────────────────────────────────────┘
```

## API Modules

The API is organized into functional modules for better clarity:

### @ref wb_idf_i2c_init "Initialization & Management"

Core functions for setting up I2C buses and managing device handles:



- Bus initialization with configurable GPIO pins
- Device handle creation and deletion
- Device probing and detection

Key functions:



- wb_i2c_master_bus_init() - Initialize an I2C bus
- wb_i2c_master_device_create() - Create a device handle
- wb_i2c_master_bus_probe_device() - Check if device responds

### @ref wb_idf_i2c_byte "Byte Operations"

Standard byte-level I/O operations for register access:



- Single byte read/write
- Multi-byte burst transfers

Key functions:



- wb_i2c_master_bus_read_byte() - Read a single byte
- wb_i2c_master_bus_write_byte() - Write a single byte
- wb_i2c_master_bus_read_multiple_bytes() - Burst read
- wb_i2c_master_bus_write_multiple_bytes() - Burst write

### @ref wb_idf_i2c_bit "Bit Operations"

Fine-grained control for bit-level register manipulation:



- Read/write individual bits
- Read/write bit ranges (bit fields)
- Atomic read-modify-write operations

Key functions:



- wb_i2c_master_bus_read_byte_bit() - Read single bit
- wb_i2c_master_bus_write_byte_bit() - Write single bit
- wb_i2c_master_bus_read_byte_bits() - Read bit range
- wb_i2c_master_bus_write_byte_bits() - Write bit range

### @ref wb_idf_i2c_word "Word Operations (16-bit)"

16-bit register access for devices with multi-byte values:



- Read/write 16-bit words
- Bit operations on word registers
- Automatic byte order handling

Key functions:



- wb_i2c_master_bus_read_word() - Read 16-bit word
- wb_i2c_master_bus_write_word() - Write 16-bit word
- wb_i2c_master_bus_read_word_bit() - Read bit from word
- wb_i2c_master_bus_write_word_bit() - Write bit to word

## Quick Start Guide

### Installation

**Option 1: Component Manager (Recommended)**

Add to your project's `idf_component.yml` :

```yaml
dependencies:
whirlingbits/wb-idf-i2c:
version:"^1.0.0"
```

**Option 2: Git Submodule**

```c
cdcomponents
gitsubmoduleaddhttps://github.com/WhirlingBits/wb-idf-core.git
```

**Option 3: Manual Copy**

Copy the `wb-idf-i2c` folder to your project's `components/` directory.

### Basic Usage Example

```c
#include"wb-idf-i2c.h"

//1.InitializetheI2Cbus
i2c_master_bus_handle_tbus_handle;
esp_err_tret=wb_i2c_master_bus_init(
I2C_NUM_0,//I2Cport
GPIO_NUM_22,//SCLpin
GPIO_NUM_21//SDApin
);

if(ret!=ESP_OK){
ESP_LOGE(TAG,"I2Cbusinitfailed:%s",esp_err_to_name(ret));
return;
}

//2.Createadevicehandle(e.g.,forEEPROMataddress0x50)
i2c_master_dev_handle_teeprom_dev=wb_i2c_master_device_create(
bus_handle,
0x50,//Deviceaddress(7-bit)
100000//Clockspeed(100kHz)
);

//3.Checkifdeviceispresent
ret=wb_i2c_master_bus_probe_device(bus_handle,0x50,1000);
if(ret==ESP_OK){
ESP_LOGI(TAG,"Devicefoundat0x50");
}

//4.Writeabyte
uint8_tdata=0xAB;
ret=wb_i2c_master_bus_write_byte(eeprom_dev,0x00,data);

//5.Readabyte
uint8_tread_data;
ret=wb_i2c_master_bus_read_byte(eeprom_dev,0x00,&read_data);
ESP_LOGI(TAG,"Read:0x%02X",read_data);

//6.Cleanup
wb_i2c_master_device_delete(eeprom_dev);
wb_i2c_master_bus_delete(bus_handle);
```

## Hardware Configuration

### Typical Wiring

```text
ESP32PinI2CDevicePinPull-up
──────────────────────────────
GPIO21(SDA)──────┬───────SDA
│4.7kΩto3.3V

GPIO22(SCL)──────┬───────SCL
│4.7kΩto3.3V

3.3V──────────────┴───────VCC
GND────────────────────────GND
```

**Pull-up Resistor Guidelines:**

| Bus Speed | Cable Length | Recommended Pull-up |
|---|---|---|
| 100 kHz | < 3 meters | 4.7 kΩ |
| 400 kHz | < 1 meter | 2.2 kΩ |
| 1 MHz | < 30 cm | 1.0 kΩ |

### GPIO Selection

**ESP32 I2C-capable GPIO pins:**

- Any GPIO can be used for I2C (software flexibility)
- Commonly used: GPIO21 (SDA), GPIO22 (SCL)
- Avoid strapping pins (GPIO0, GPIO2, GPIO12, GPIO15)
- Use input-only pins with external pull-ups

### Timing Specifications

| Mode | Clock Freq | Max Distance | Rise Time |
|---|---|---|---|
| Standard | 100 kHz | ~3 meters | < 1000 ns |
| Fast Mode | 400 kHz | ~1 meter | < 300 ns |
| Fast Mode Plus | 1 MHz | < 30 cm | < 120 ns |

## Usage Examples

Complete, runnable examples are available in the `examples/` directory:

### I2C Bus Scanner

Scans all I2C addresses (0x00-0x7F) to detect connected devices:

```c
//examples/i2c_scanner/main.c

for(uint8_taddr=0x00;addr<0x80;addr++){
esp_err_tret=wb_i2c_master_bus_probe_device(bus_handle,addr,100);
if(ret==ESP_OK){
printf("Devicefoundataddress0x%02X\n",addr);
}
}
```

### EEPROM Read/Write

Reading and writing to an AT24C32 EEPROM:

```c
//examples/eeprom_readwrite/main.c

//Writedata
uint8_twrite_data[]="HelloI2C!";
wb_i2c_master_bus_write_multiple_bytes(dev,0x00,write_data,sizeof(write_data));

//Readback
uint8_tread_data[32];
wb_i2c_master_bus_read_multiple_bytes(dev,0x00,read_data,sizeof(write_data));
printf("Read:%s\n",read_data);
```

### Sensor Polling (MPU6050)

Continuously reading accelerometer data:

```c
//examples/mpu6050_read/main.c

while(1){
uint8_taccel_data[6];
wb_i2c_master_bus_read_multiple_bytes(dev,0x3B,accel_data,6);

int16_taccel_x=(accel_data[0]<<8)|accel_data[1];
int16_taccel_y=(accel_data[2]<<8)|accel_data[3];
int16_taccel_z=(accel_data[4]<<8)|accel_data[5];

printf("Accel:X=%dY=%dZ=%d\n",accel_x,accel_y,accel_z);
vTaskDelay(pdMS_TO_TICKS(100));
}
```

## Performance Considerations

### Latency Measurements

Typical operation latencies on ESP32 @ 240MHz:

| Operation | @ 100kHz | @ 400kHz | @ 1MHz |
|---|---|---|---|
| Single byte read | ~250 µs | ~70 µs | ~35 µs |
| Single byte write | ~250 µs | ~70 µs | ~35 µs |
| 16-byte burst read | ~1.5 ms | ~400 µs | ~200 µs |
| Bit read (RMW) | ~500 µs | ~140 µs | ~70 µs |

### Optimization Tips

- Use burst operations (read/write_multiple_bytes)
- Increase clock speed to 400 kHz or 1 MHz
- Minimize number of transactions

- Use 100 kHz standard mode
- Batch operations to reduce bus activity
- Put I2C devices in sleep mode when idle

- Add external pull-up resistors (4.7 kΩ typical)
- Keep cables short (< 30 cm for high speeds)
- Shield cables in noisy environments
- Add series resistors (100Ω) for ESD protection

## Troubleshooting

### Common Error Codes

**ESP_ERR_TIMEOUT**

Device not responding on the bus.

- Wrong device address (check datasheet for 7-bit vs 8-bit address)
- Missing or insufficient pull-up resistors
- Device not powered
- Wiring error (SDA/SCL swapped)
- Bus speed too high for cable length

- Verify device address with I2C scanner
- Check voltage on SDA/SCL (should be 3.3V when idle)
- Add 4.7kΩ pull-ups if not present
- Reduce bus speed to 100 kHz for testing

**ESP_FAIL (NACK received)**

Device acknowledged address but NACK'd the data.

- Invalid register address
- Write to read-only register
- Device not initialized
- Device in wrong mode

- Check register address in device datasheet
- Verify device initialization sequence
- Read device status register

**ESP_ERR_INVALID_STATE**

I2C bus or device not properly initialized.

- Call wb_i2c_master_bus_init() before using bus
- Ensure device handle is created before use
- Check return values of initialization functions

### Debug Techniques

**Enable Debug Logging:**

```c
esp_log_level_set("i2c",ESP_LOG_DEBUG);
esp_log_level_set("wb_i2c",ESP_LOG_DEBUG);
```

**Use I2C Scanner:**

Run the included `i2c_scanner` example to detect all devices:

```c
cdexamples/i2c_scanner
idf.pybuildflashmonitor
```

- START condition present
- Correct address sent (7-bit + R/W bit)
- ACK/NACK signals correct
- STOP condition present
- Clock stretching (if device supports it)
- Data setup and hold times

### Bus Recovery

If the bus is stuck (SDA or SCL held low):

```c
//1.PowercycletheI2Cdevice(ifpossible)

//2.SendclockpulsestoreleaseSDA
gpio_set_direction(GPIO_NUM_22,GPIO_MODE_OUTPUT);
gpio_set_level(GPIO_NUM_21,1);//SDAhigh

for(inti=0;i<9;i++){
gpio_set_level(GPIO_NUM_22,0);
vTaskDelay(1);
gpio_set_level(GPIO_NUM_22,1);
vTaskDelay(1);
}

//3.Re-initializeI2Cbus
wb_i2c_master_bus_delete(bus_handle);
wb_i2c_master_bus_init(I2C_NUM_0,GPIO_NUM_22,GPIO_NUM_21);
```

## Best Practices

### Error Handling

Always check return values:

```c
esp_err_tret=wb_i2c_master_bus_write_byte(dev,0x10,0xFF);
if(ret!=ESP_OK){
ESP_LOGE(TAG,"Writefailed:%s",esp_err_to_name(ret));
//Handleerror(retry,resetdevice,notifyuser,etc.)
}
```

### Thread Safety

The driver uses internal mutexes for thread safety. Multiple tasks can safely access the same I2C bus concurrently:

```c
//Task1
voidsensor1_task(void*arg){
while(1){
wb_i2c_master_bus_read_byte(dev1,0x00,&data);
vTaskDelay(100);
}
}

//Task2-safetorunconcurrently
voidsensor2_task(void*arg){
while(1){
wb_i2c_master_bus_read_byte(dev2,0x00,&data);
vTaskDelay(100);
}
}
```

### Resource Management

Always clean up resources:

```c
//Createresources
wb_i2c_master_bus_init(...);
dev_handle=wb_i2c_master_device_create(...);

//Useresources...

//Cleanupbeforeexit
wb_i2c_master_device_delete(dev_handle);
wb_i2c_master_bus_delete(bus_handle);
```

## Testing

The component includes comprehensive unit tests and integration tests.

**Run Unit Tests:**

```c
cdtest/wb_idf_i2c_test
idf.pybuildflashmonitor
```

- Bus initialization with various configurations
- Device creation and deletion
- All byte, bit, and word operations
- Error conditions and recovery
- Multi-threaded access

## Complete API Reference

For detailed function documentation, see:



- Initialization & Management
- Byte Operations
- Bit Operations
- Word Operations (16-bit)

## Changelog

- Initial release
- Full I2C master functionality
- Byte, bit, and word operations
- Comprehensive documentation and examples

## License

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

## Support & Contributing

- GitHub Issues
- Discussions
- Email: support@whirlingbits.com

- Pull requests are welcome!
- See CONTRIBUTING.md for guidelines
- Follow ESP-IDF coding standards
- Add tests for new features

- WhirlingBits Team
- https://whirlingbits.com

## Sub-Modules

- [Initialization & Management](./wb_idf_i2c_init)
