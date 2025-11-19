---
id: wb_idf_i2c_bit
title: Bit Operations
sidebar_label: Bit Operations
---

# Bit Operations

Bit-level read/write operations.

These functions allow manipulation of individual bits within device registers without affecting other bits in the same register.

## Functions

### wb_i2c_master_bus_read_byte_bit

Reads a single bit from a byte register.

```c
esp_err_t wb_i2c_master_bus_read_byte_bit(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_num, uint8_t *data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to read from
- **bit_num** (`uint8_t`): Bit number to read (0-7, where 0 is LSB)
- **data** (`uint8_t *`): Pointer to store the bit value (0 or 1)

**Returns:**

ESP_OK if successful, error code otherwise

This function reads a byte and returns the value of the specified bit.

---

### wb_i2c_master_bus_read_byte_bits

Reads multiple bits from a byte register.

```c
esp_err_t wb_i2c_master_bus_read_byte_bits(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_start, uint8_t length, uint8_t *data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C device
- **mem_address** (`uint8_t`): Memory address to read from
- **bit_start** (`uint8_t`): Starting bit position (MSB of the range, 0-7)
- **length** (`uint8_t`): Number of bits to read (1-8)
- **data** (`uint8_t *`): Pointer to store the extracted bits

**Returns:**

ESP_OK if successful, error code otherwise

This function reads a byte and extracts a range of bits.

---

### wb_i2c_master_bus_write_byte_bit

Write a single bit to a byte register.

```c
esp_err_t wb_i2c_master_bus_write_byte_bit(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_num, uint8_t data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to write to
- **bit_num** (`uint8_t`): Bit position to write (0-7, where 0 is LSB)
- **data** (`uint8_t`): Bit value to write (0 or 1)

**Returns:**

ESP_OK if successful, otherwise an error code

This function reads the current byte value, modifies the specified bit, and writes it back to the device.

---

### wb_i2c_master_bus_write_byte_bits

Write multiple bits to a byte register.

```c
esp_err_t wb_i2c_master_bus_write_byte_bits(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_start, uint8_t length, uint8_t data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to write to
- **bit_start** (`uint8_t`): Starting bit position (MSB of the range, 0-7)
- **length** (`uint8_t`): Number of bits to write (1-8)
- **data** (`uint8_t`): Bit values to write

**Returns:**

ESP_OK if successful, otherwise an error code

This function reads the current byte, modifies the specified bit range, and writes it back to the device.

---
