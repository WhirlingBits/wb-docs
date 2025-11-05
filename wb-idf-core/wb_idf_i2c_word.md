---
id: wb_idf_i2c_word
title: Word Operations (16-bit)
sidebar_label: Word Operations (16-bit)
---

# Word Operations (16-bit)

16-bit word read/write operations

These functions handle 16-bit registers, useful for devices with multi-byte data values like sensors with high-resolution readings.

## Functions

### wb_i2c_master_bus_read_word

Reads a 16-bit word from the I2C device.

```c
esp_err_t wb_i2c_master_bus_read_word(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint16_t *data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Starting memory address
- **data** (`uint16_t *`): Pointer to store the read word

**Returns:**

ESP_OK if successful, error code otherwise

This function reads two consecutive bytes and combines them into a 16-bit word.

Handle to the I2C master device

Starting memory address

Pointer to store the read word

ESP_OK if successful, error code otherwise

---

### wb_i2c_master_bus_read_word_bit

Reads a single bit from a 16-bit word register.

```c
esp_err_t wb_i2c_master_bus_read_word_bit(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_num, uint8_t *data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to read from
- **bit_num** (`uint8_t`): Bit number to read (0-15, where 0 is LSB)
- **data** (`uint8_t *`): Pointer to store the bit value (0 or 1)

**Returns:**

ESP_OK if successful, error code otherwise

This function reads a word and returns the value of the specified bit.

Handle to the I2C master device

Memory address to read from

Bit number to read (0-15, where 0 is LSB)

Pointer to store the bit value (0 or 1)

ESP_OK if successful, error code otherwise

---

### wb_i2c_master_bus_read_word_bits

Reads multiple bits from a 16-bit word register.

```c
esp_err_t wb_i2c_master_bus_read_word_bits(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_start, uint8_t length, uint16_t *data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C device
- **mem_address** (`uint8_t`): Memory address to read from
- **bit_start** (`uint8_t`): Starting bit position (MSB of the range, 0-15)
- **length** (`uint8_t`): Number of bits to read (1-16)
- **data** (`uint16_t *`): Pointer to store the extracted bits

**Returns:**

ESP_OK if successful, otherwise an error code

This function reads a word and extracts a range of bits.

Handle to the I2C device

Memory address to read from

Starting bit position (MSB of the range, 0-15)

Number of bits to read (1-16)

Pointer to store the extracted bits

ESP_OK if successful, otherwise an error code

---

### wb_i2c_master_bus_write_word

Write a 16-bit word to the I2C device.

```c
esp_err_t wb_i2c_master_bus_write_word(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint16_t data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Starting memory address
- **data** (`uint16_t`): Word to write

**Returns:**

ESP_OK if successful, otherwise an error code

This function writes a 16-bit word as two consecutive bytes.

Handle to the I2C master device

Starting memory address

Word to write

ESP_OK if successful, otherwise an error code

---

### wb_i2c_master_bus_write_word_bit

Write a single bit to a 16-bit word register.

```c
esp_err_t wb_i2c_master_bus_write_word_bit(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_num, uint8_t data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to write to
- **bit_num** (`uint8_t`): Bit position to write (0-15, where 0 is LSB)
- **data** (`uint8_t`): Bit value to write (0 or 1)

**Returns:**

ESP_OK if successful, otherwise an error code

This function reads the current word, modifies the specified bit, and writes it back to the device.

Handle to the I2C master device

Memory address to write to

Bit position to write (0-15, where 0 is LSB)

Bit value to write (0 or 1)

ESP_OK if successful, otherwise an error code

---

### wb_i2c_master_bus_write_word_bits

Write multiple bits to a 16-bit word register.

```c
esp_err_t wb_i2c_master_bus_write_word_bits(i2c_master_dev_handle_t dev_handle, uint8_t mem_address, uint8_t bit_start, uint8_t length, uint16_t data)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device
- **mem_address** (`uint8_t`): Memory address to write to
- **bit_start** (`uint8_t`): Starting bit position (MSB of the range, 0-15)
- **length** (`uint8_t`): Number of bits to write (1-16)
- **data** (`uint16_t`): Bit values to write

**Returns:**

ESP_OK if successful, error code otherwise

This function reads the current word, modifies the specified bit range, and writes it back to the device.

Handle to the I2C master device

Memory address to write to

Starting bit position (MSB of the range, 0-15)

Number of bits to write (1-16)

Bit values to write

ESP_OK if successful, error code otherwise

---
