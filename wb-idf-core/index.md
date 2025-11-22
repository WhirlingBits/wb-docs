---
id: index
slug: /
title: WhirlingBits Core Components Documentation
sidebar_label: Overview
---

# WhirlingBits Core Components Documentation

The **wb-idf-core** package provides a collection of high-quality, production-ready components for ESP-IDF projects. All components follow ESP-IDF coding standards and best practices.

- ✅ Production-Ready: Thoroughly tested and documented
- ✅ ESP-IDF Native: Seamless integration with ESP-IDF
- ✅ Well-Documented: Comprehensive API documentation
- ✅ Example-Rich: Real-world usage examples included
- ✅ Thread-Safe: Designed for multi-threaded environments

- I2C Master Driver - Advanced I2C functionality
- Multiple bus support
- Device probing and detection
- Bit-level register manipulation
- 16-bit word operations
- SPI Master Driver (Coming soon)
- UART Driver (Coming soon)

- GPIO Extensions (Coming soon)
- ADC Utilities (Coming soon)

Add to your ESP-IDF project using the component manager:

```c
idf.py add-dependency "whirlingbits/wb-idf-core^1.0.0"
```

Or add to `idf_component.yml` :

```c
dependencies:
  whirlingbits/wb-idf-core: "^1.0.0"
```

```c
#include "wb_idf_i2c.h"

// Initialize I2C bus
i2c_master_bus_handle_t bus_handle;
wb_i2c_master_bus_init(I2C_NUM_0, GPIO_NUM_21, GPIO_NUM_22, 100000, &bus_handle);

// Add device
i2c_master_dev_handle_t dev_handle;
wb_i2c_master_bus_add_device(bus_handle, 0x3C, &dev_handle);

// Write data
uint8_t data[] = {0x00, 0x01, 0x02};
wb_i2c_master_byte_write(dev_handle, 0x00, data, sizeof(data));
```

Browse the complete API documentation by module:

- I2C Master Driver

- ESP-IDF Version: 5.0 or higher
- Supported SoCs: ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- License: Apache License 2.0

- GitHub Repository
- Issue Tracker
- Documentation
- Examples

For questions, bug reports, or feature requests:



- Open an issue on GitHub
- Contact: support@whirlingbits.com

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See LICENSE file in the project root for details.

## Components
