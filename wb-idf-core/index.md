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

## Available Components

### I2C Master Driver

Advanced I2C functionality with:

- Multiple bus support
- Device probing and detection
- Bit-level register manipulation
- 16-bit word operations

[View I2C API Documentation](./wb_idf_i2c)

### Additional Components

- **SPI Driver** (Coming soon)
- **UART Driver** (Coming soon)
- **GPIO Utilities** (Coming soon)

## Installation

Add to your ESP-IDF project using the component manager:

```bash
idf.py add-dependency "whirlingbits/wb-idf-core^1.0.0"
```

Or add to `idf_component.yml`:

```yaml
dependencies:
  whirlingbits/wb-idf-core: "^1.0.0"
```

## Quick Start Example

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

## API Documentation

Browse the complete API documentation by module:

- [I2C Master Driver](./wb_idf_i2c)

## Requirements
- **ESP-IDF Version:** 5.0 or higher
- **Supported Chips:** ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- **License:** Apache License 2.0

## Support

For questions, bug reports, or feature requests:

- Open an issue on [GitHub](https://github.com/WhirlingBits/wb-idf-core/issues)
- Contact: [contact@whirlingbits.de](mailto:contact@whirlingbits.de)

## License

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See LICENSE file in the project root for details.
- **ESP-IDF Version:** 5.0 or higher
- **Supported Chips:** ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- **License:** Apache License 2.0

## Support

For questions, bug reports, or feature requests:

- Open an issue on [GitHub](https://github.com/WhirlingBits/wb-idf-core/issues)
- Contact: [contact@whirlingbits.de](mailto:contact@whirlingbits.de)

## License

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See LICENSE file in the project root for details.