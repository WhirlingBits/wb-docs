---
id: wb_idf_i2c_init
title: Initialization & Management
sidebar_label: Initialization & Management
---

# Initialization & Management

Functions for I2C bus and device initialization.

## Functions

### wb_i2c_master_bus_delete

Deletes an I2C master bus handle.

```c
esp_err_t wb_i2c_master_bus_delete(i2c_master_bus_handle_t bus_handle)
```

**Parameters:**

- **bus_handle** (`i2c_master_bus_handle_t`): Handle to the I2C master bus to delete

**Returns:**

- ESP_OK on success
- ESP_ERR_INVALID_ARG if the handle is invalid

ESP_OK on success

ESP_ERR_INVALID_ARG if the handle is invalid

This function deletes an I2C master bus handle and releases any resources associated with it.

Handle to the I2C master bus to delete

- ESP_OK on success
- ESP_ERR_INVALID_ARG if the handle is invalid

ESP_OK on success

ESP_ERR_INVALID_ARG if the handle is invalid

---

### wb_i2c_master_bus_init

Initializes the I2C master bus.

```c
esp_err_t wb_i2c_master_bus_init(i2c_port_num_t i2c_port, gpio_num_t i2c_scl, gpio_num_t i2c_sda)
```

**Parameters:**

- **i2c_port** (`i2c_port_num_t`): The I2C port number to initialize
- **i2c_scl** (`gpio_num_t`): The GPIO number for the I2C SCL pin
- **i2c_sda** (`gpio_num_t`): The GPIO number for the I2C SDA pin

**Returns:**

esp_err_t Returns ESP_OK on success, or an error code if initialization fails

This function initializes an I2C master bus using the provided SCL and SDA GPIO pins. It configures the bus with default clock source, internal pull-ups enabled, glitch ignore count, and uses the configuration specified by CONFIG_I2C_NUM. If the bus is already initialized or if initialization fails, it returns ESP_FAIL.

The I2C port number to initialize

The GPIO number for the I2C SCL pin

The GPIO number for the I2C SDA pin

esp_err_t Returns ESP_OK on success, or an error code if initialization fails

```c
esp_err_tret=wb_i2c_master_bus_init(I2C_NUM_0,GPIO_NUM_22,GPIO_NUM_21);
if(ret!=ESP_OK){
ESP_LOGE(TAG,"I2Cbusinitializationfailed");
}
```

---

### wb_i2c_master_bus_probe_device

Probes the device at the specified address on the I2C bus.

```c
esp_err_t wb_i2c_master_bus_probe_device(i2c_master_bus_handle_t bus_handle, uint16_t dev_addr, uint32_t timeout)
```

**Parameters:**

- **bus_handle** (`i2c_master_bus_handle_t`): Handle to the I2C master bus
- **dev_addr** (`uint16_t`): Address of the device to probe (7-bit)
- **timeout** (`uint32_t`): Timeout in milliseconds for the probe operation

**Returns:**

ESP_OK if device responds, error code otherwise

This function probes the device at the specified address on the I2C bus to determine if it is present and responding.

Handle to the I2C master bus

Address of the device to probe (7-bit)

Timeout in milliseconds for the probe operation

ESP_OK if device responds, error code otherwise

---

### wb_i2c_master_device_create

Creates a new I2C master device handle.

```c
i2c_master_dev_handle_t wb_i2c_master_device_create(i2c_master_bus_handle_t bus_handle, uint8_t dev_addr, uint32_t clk_speed)
```

**Parameters:**

- **bus_handle** (`i2c_master_bus_handle_t`): The I2C bus handle
- **dev_addr** (`uint8_t`): The device address (7-bit)
- **clk_speed** (`uint32_t`): The clock speed in Hz (e.g., 100000 for 100kHz)

**Returns:**

i2c_master_dev_handle_t The new I2C master device handle

This function creates a new I2C master device handle for the specified bus and device address.

The I2C bus handle

The device address (7-bit)

The clock speed in Hz (e.g., 100000 for 100kHz)

i2c_master_dev_handle_t The new I2C master device handle

```c
i2c_master_dev_handle_tdev=wb_i2c_master_device_create(bus_handle,0x68,100000);
```

---

### wb_i2c_master_device_delete

Delete an I2C master device handle.

```c
esp_err_t wb_i2c_master_device_delete(i2c_master_dev_handle_t dev_handle)
```

**Parameters:**

- **dev_handle** (`i2c_master_dev_handle_t`): Handle to the I2C master device to delete

**Returns:**

ESP_OK if successful, otherwise an error code

This function deletes an I2C master device handle created by `wb_i2c_master_device_create()` .

Handle to the I2C master device to delete

ESP_OK if successful, otherwise an error code

---
