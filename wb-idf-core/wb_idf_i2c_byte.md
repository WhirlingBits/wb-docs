---
id: wb_idf_i2c_byte
title: Byte Operations
sidebar_label: Byte Operations
---

# Byte Operations

Single and multi-byte read/write operations.

## Functions

### wb_i2c_master_bus_read_byte

Reads a byte from the I2C device.

```c
esp_err_t wb_i2c_master_bus_read_byte(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t *data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to read from
- **data** (`uint8_t *`): Pointer to store the read byte

**Returns:**

ESP_OK if successful, error code otherwise

This function reads a single byte from the I2C device at the specified memory address.

Handle to the I2C master device

Memory address to read from

Pointer to store the read byte

ESP_OK if successful, error code otherwise

---

### wb_i2c_master_bus_read_multiple_bytes

Read multiple bytes from an I2C device.

```c
esp_err_t wb_i2c_master_bus_read_multiple_bytes(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t data[], uint8_t length)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C device
- **mem_address** (`uint8_t`): Starting memory address
- **data** (`uint8_t`): Buffer to store read data
- **length** (`uint8_t`): Number of bytes to read

**Returns:**

ESP_OK if successful, error code otherwise

This function reads multiple consecutive bytes starting from the specified memory address.

Handle to the I2C device

Starting memory address

Buffer to store read data

Number of bytes to read

ESP_OK if successful, error code otherwise

---

### wb_i2c_master_bus_write_byte

Write a byte to the I2C device.

```c
esp_err_t wb_i2c_master_bus_write_byte(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to write to
- **data** (`uint8_t`): Byte to write

**Returns:**

ESP_OK if successful, error code otherwise

This function writes a single byte to the specified memory address on the I2C device.

Handle to the I2C master device

Memory address to write to

Byte to write

ESP_OK if successful, error code otherwise

---

### wb_i2c_master_bus_write_multiple_bytes

Write multiple bytes to an I2C device.

```c
esp_err_t wb_i2c_master_bus_write_multiple_bytes(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t *data, uint8_t length)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle of the I2C device
- **mem_address** (`uint8_t`): Starting memory address
- **data** (`uint8_t *`): Pointer to the data buffer to write
- **length** (`uint8_t`): Number of bytes to write

**Returns:**

ESP_OK if successful, error code otherwise

This function writes multiple consecutive bytes starting from the specified memory address.

Handle of the I2C device

Starting memory address

Pointer to the data buffer to write

Number of bytes to write

ESP_OK if successful, error code otherwise

---
