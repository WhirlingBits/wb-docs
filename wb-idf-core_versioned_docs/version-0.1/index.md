---
id: index
slug: /
title: WhirlingBits Core Components Documentation
sidebar_label: Overview
---

# WhirlingBits Core Components Documentation

The package provides a collection of high-quality, production-ready components for ESP-IDF projects. All components follow ESP-IDF coding standards and best practices.

- ✅ Thoroughly tested and documented
- ✅ Seamless integration with ESP-IDF
- ✅ Comprehensive API documentation
- ✅ Real-world usage examples included
- ✅ Designed for multi-threaded environments

✅ Thoroughly tested and documented

✅ Seamless integration with ESP-IDF

✅ Comprehensive API documentation

✅ Real-world usage examples included

✅ Designed for multi-threaded environments

- `I2C Master Driver` - Advanced I2C functionality 

- Multiple bus support
- Device probing and detection
- Bit-level register manipulation
- 16-bit word operations
- Multiple bus support
- Device probing and detection
- Bit-level register manipulation
- 16-bit word operations
- (Coming soon)
- (Coming soon)

`I2C Master Driver` - Advanced I2C functionality 

- Multiple bus support
- Device probing and detection
- Bit-level register manipulation
- 16-bit word operations

Multiple bus support

Device probing and detection

Bit-level register manipulation

16-bit word operations

(Coming soon)

(Coming soon)

- (Coming soon)
- (Coming soon)

(Coming soon)

(Coming soon)

Add to your ESP-IDF project using the component manager:

```c
idf.pyadd-dependency"whirlingbits/wb-idf-core^1.0.0"
```

Or add to `idf_component.yml` :

```c
dependencies:
whirlingbits/wb-idf-core:"^1.0.0"
```

```c
#include"wb_idf_i2c.h"

//InitializeI2Cbus
i2c_master_bus_handle_tbus_handle;
wb_i2c_master_bus_init(I2C_NUM_0,GPIO_NUM_21,GPIO_NUM_22,100000,&bus_handle);

//Adddevice
i2c_master_dev_handle_tdev_handle;
wb_i2c_master_bus_add_device(bus_handle,0x3C,&dev_handle);

//Writedata
uint8_tdata[]={0x00,0x01,0x02};
wb_i2c_master_byte_write(dev_handle,0x00,data,sizeof(data));
```

Browse the complete API documentation by module:

- `I2C Master Driver`

`I2C Master Driver`

- 5.0 or higher
- ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- Apache License 2.0

5.0 or higher

ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6

Apache License 2.0

- 
- 
- 
-

For questions, bug reports, or feature requests: 

- Open an issue on
- Contact:

Open an issue on

Contact:

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See LICENSE file in the project root for details.

## Components

### [I2C Master Driver](./wb_idf_i2c)

High-level I2C master functions for ESP-IDF.
