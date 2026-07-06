---
id: wb_lwm2m_object
title: Object / Resource Model
sidebar_label: Object / Resource Model
---

# Object / Resource Model

LWM2M data model with typed resources and callback-driven access.

This module defines the core LWM2M data model used throughout the wb-idf-lwm2m component:

- Object definitions ( ) — Top-level container with an Object ID, human-readable name, instance list, and resource list.
- Resource definitions ( ) — Per-resource metadata including data type, allowed operations (R/W/E), and user callbacks.
- Value type ( ) — Tagged union supporting all 10 LWM2M data types (String, Integer, UInteger, Float, Boolean, Opaque, Time, Objlink, CoreLnk, None).
- Callback types — wb_lwm2m_read_cb_t , wb_lwm2m_write_cb_t , wb_lwm2m_execute_cb_t for server-initiated operations.
- Helper macros — , , etc. for convenient value construction.
- Accessor functions — , , for type-safe access.

## Type Definitions

### `wb_lwm2m_read_cb_t`

```c
typedef esp_err_t(* wb_lwm2m_read_cb_t) (uint16_t obj_id, uint16_t inst_id, uint16_t res_id, wb_lwm2m_value_t *value, void *user_ctx)
```

Read callback — invoked when a resource value is needed.

### `wb_lwm2m_write_cb_t`

```c
typedef esp_err_t(* wb_lwm2m_write_cb_t) (uint16_t obj_id, uint16_t inst_id, uint16_t res_id, const wb_lwm2m_value_t *value, void *user_ctx)
```

Write callback — invoked when the server writes a resource.

### `wb_lwm2m_execute_cb_t`

```c
typedef esp_err_t(* wb_lwm2m_execute_cb_t) (uint16_t obj_id, uint16_t inst_id, uint16_t res_id, const uint8_t *args, size_t args_len, void *user_ctx)
```

Execute callback — invoked when the server executes a resource.

## Enumerations

### `wb_lwm2m_fw_state_t`

Firmware Update States (/5/0/3)

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_FW_STATE_IDLE` | = 0 |  |
| `WB_LWM2M_FW_STATE_DOWNLOADING` | = 1 |  |
| `WB_LWM2M_FW_STATE_DOWNLOADED` | = 2 |  |
| `WB_LWM2M_FW_STATE_UPDATING` | = 3 |  |

### `wb_lwm2m_fw_update_result_t`

Firmware Update Result Codes (/5/0/5)

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_FW_RESULT_DEFAULT` | = 0 |  |
| `WB_LWM2M_FW_RESULT_SUCCESS` | = 1 |  |
| `WB_LWM2M_FW_RESULT_NOT_ENOUGH_FLASH` | = 2 |  |
| `WB_LWM2M_FW_RESULT_OUT_OF_RAM` | = 3 |  |
| `WB_LWM2M_FW_RESULT_CONN_LOST` | = 4 |  |
| `WB_LWM2M_FW_RESULT_INTEGRITY_FAILED` | = 5 |  |
| `WB_LWM2M_FW_RESULT_UNSUPPORTED_PKG` | = 6 |  |
| `WB_LWM2M_FW_RESULT_INVALID_URI` | = 7 |  |
| `WB_LWM2M_FW_RESULT_UPDATE_FAILED` | = 8 |  |
| `WB_LWM2M_FW_RESULT_UNSUPPORTED_PROTOCOL` | = 9 |  |

### `wb_lwm2m_res_type_t`

LWM2M Resource Data Type enumeration.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_RES_TYPE_NONE` | = 0 | Execute-only resource (no data) |
| `WB_LWM2M_RES_TYPE_STRING` | = 1 | UTF-8 string, 0..65535 bytes. |
| `WB_LWM2M_RES_TYPE_INTEGER` | = 2 | Signed integer: 8/16/32/64-bit. |
| `WB_LWM2M_RES_TYPE_UINTEGER` | = 3 | Unsigned integer: 8/16/32/64-bit (LWM2M 1.1+) |
| `WB_LWM2M_RES_TYPE_FLOAT` | = 4 | IEEE 754 float: 32-bit or 64-bit. |
| `WB_LWM2M_RES_TYPE_BOOLEAN` | = 5 | Boolean: 0 or 1. |
| `WB_LWM2M_RES_TYPE_OPAQUE` | = 6 | Opaque binary data, 0..65535 bytes. |
| `WB_LWM2M_RES_TYPE_TIME` | = 7 | Unix timestamp (signed 32/64-bit integer) |
| `WB_LWM2M_RES_TYPE_OBJLINK` | = 8 | Object Link: ObjectID:InstanceID. |
| `WB_LWM2M_RES_TYPE_CORELNK` | = 9 | CoRE Link-Format string (RFC 6690) |

### `wb_lwm2m_security_mode_t`

LWM2M Security Modes (Security Object /0, Resource /0/0/2)

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_SEC_MODE_PSK` | = 0 | Pre-Shared Key. |
| `WB_LWM2M_SEC_MODE_RAW_PUB_KEY` | = 1 | Raw Public Key. |
| `WB_LWM2M_SEC_MODE_CERTIFICATE` | = 2 | Certificate. |
| `WB_LWM2M_SEC_MODE_NOSEC` | = 3 | NoSec (plain CoAP) |
| `WB_LWM2M_SEC_MODE_CERT_EST` | = 4 | Certificate with EST. |

## Macros

### `WB_LWM2M_OBJ_SECURITY 0`

### `WB_LWM2M_OBJ_SERVER 1`

### `WB_LWM2M_OBJ_ACCESS_CONTROL 2`

### `WB_LWM2M_OBJ_DEVICE 3`

### `WB_LWM2M_OBJ_CONN_MONITORING 4`

### `WB_LWM2M_OBJ_FIRMWARE_UPDATE 5`

### `WB_LWM2M_OBJ_LOCATION 6`

### `WB_LWM2M_OBJ_CONN_STATISTICS 7`

### `WB_LWM2M_RES_SEC_SERVER_URI 0`

String — LWM2M Server URI.

### `WB_LWM2M_RES_SEC_BOOTSTRAP 1`

Boolean — Bootstrap-Server.

### `WB_LWM2M_RES_SEC_MODE 2`

Integer — Security Mode (0-4)

### `WB_LWM2M_RES_SEC_PUB_KEY_IDENTITY 3`

Opaque — Public Key or Identity.

### `WB_LWM2M_RES_SEC_SERVER_PUB_KEY 4`

Opaque — Server Public Key.

### `WB_LWM2M_RES_SEC_SECRET_KEY 5`

Opaque — Secret Key.

### `WB_LWM2M_RES_SEC_SHORT_SERVER_ID 10`

Integer — Short Server ID.

### `WB_LWM2M_RES_SRV_SHORT_ID 0`

Integer — Short Server ID.

### `WB_LWM2M_RES_SRV_LIFETIME 1`

Integer — Lifetime (seconds)

### `WB_LWM2M_RES_SRV_MIN_PERIOD 2`

Integer — Default Min Period.

### `WB_LWM2M_RES_SRV_MAX_PERIOD 3`

Integer — Default Max Period.

### `WB_LWM2M_RES_SRV_DISABLE 4`

Execute — Disable.

### `WB_LWM2M_RES_SRV_DISABLE_TIMEOUT 5`

Integer — Disable Timeout.

### `WB_LWM2M_RES_SRV_NOTIFICATION_STORING 6`

Boolean — Notification Storing.

### `WB_LWM2M_RES_SRV_BINDING 7`

String — Binding.

### `WB_LWM2M_RES_SRV_REG_UPDATE_TRIGGER 8`

Execute — Registration Update Trigger.

### `WB_LWM2M_RES_DEVICE_MANUFACTURER 0`

String — Manufacturer.

### `WB_LWM2M_RES_DEVICE_MODEL_NUMBER 1`

String — Model Number.

### `WB_LWM2M_RES_DEVICE_SERIAL_NUMBER 2`

String — Serial Number.

### `WB_LWM2M_RES_DEVICE_FW_VERSION 3`

String — Firmware Version.

### `WB_LWM2M_RES_DEVICE_REBOOT 4`

Execute — Reboot.

### `WB_LWM2M_RES_DEVICE_FACTORY_RESET 5`

Execute — Factory Reset.

### `WB_LWM2M_RES_DEVICE_POWER_SOURCES 6`

Integer[] — Available Power Sources.

### `WB_LWM2M_RES_DEVICE_POWER_VOLTAGE 7`

Integer[] — Power Source Voltage (mV)

### `WB_LWM2M_RES_DEVICE_POWER_CURRENT 8`

Integer[] — Power Source Current (mA)

### `WB_LWM2M_RES_DEVICE_BATTERY_LEVEL 9`

Integer — Battery Level (%)

### `WB_LWM2M_RES_DEVICE_MEMORY_FREE 10`

Integer — Memory Free (KB)

### `WB_LWM2M_RES_DEVICE_ERROR_CODE 11`

Integer[] — Error Code.

### `WB_LWM2M_RES_DEVICE_RESET_ERROR_CODE 12`

Execute — Reset Error Code.

### `WB_LWM2M_RES_DEVICE_CURRENT_TIME 13`

Time — Current Time.

### `WB_LWM2M_RES_DEVICE_UTC_OFFSET 14`

String — UTC Offset.

### `WB_LWM2M_RES_DEVICE_TIMEZONE 15`

String — Timezone.

### `WB_LWM2M_RES_DEVICE_BINDING 16`

String — Supported Binding.

### `WB_LWM2M_RES_DEVICE_TYPE 17`

String — Device Type.

### `WB_LWM2M_RES_DEVICE_HW_VERSION 18`

String — Hardware Version.

### `WB_LWM2M_RES_DEVICE_SW_VERSION 19`

String — Software Version.

### `WB_LWM2M_RES_DEVICE_BATTERY_STATUS 20`

Integer — Battery Status.

### `WB_LWM2M_RES_DEVICE_MEMORY_TOTAL 21`

Integer — Memory Total (KB)

### `WB_LWM2M_RES_FW_PACKAGE 0`

Opaque — Package.

### `WB_LWM2M_RES_FW_PACKAGE_URI 1`

String — Package URI.

### `WB_LWM2M_RES_FW_UPDATE 2`

Execute — Update.

### `WB_LWM2M_RES_FW_STATE 3`

Integer — State (0-3)

### `WB_LWM2M_RES_FW_UPDATE_RESULT 5`

Integer — Update Result (0-9)

### `WB_LWM2M_RES_FW_PKG_NAME 6`

String — Package Name.

### `WB_LWM2M_RES_FW_PKG_VERSION 7`

String — Package Version.

### `WB_LWM2M_RES_FW_PROTOCOL_SUPPORT 8`

Integer[] — Protocol Support.

### `WB_LWM2M_RES_FW_DELIVERY_METHOD 9`

Integer — Delivery Method.

### `WB_LWM2M_RES_LOC_LATITUDE 0`

Float — Latitude.

### `WB_LWM2M_RES_LOC_LONGITUDE 1`

Float — Longitude.

### `WB_LWM2M_RES_LOC_ALTITUDE 2`

Float — Altitude (m)

### `WB_LWM2M_RES_LOC_RADIUS 3`

Float — Radius (m)

### `WB_LWM2M_RES_LOC_VELOCITY 4`

Opaque — Velocity.

### `WB_LWM2M_RES_LOC_TIMESTAMP 5`

Time — Timestamp.

### `WB_LWM2M_RES_LOC_SPEED 6`

Float — Speed (m/s)

### `WB_LWM2M_RES_CONN_NETWORK_BEARER 0`

Integer — Network Bearer.

### `WB_LWM2M_RES_CONN_AVAIL_BEARERS 1`

Integer[] — Available Network Bearer.

### `WB_LWM2M_RES_CONN_RADIO_SIGNAL 2`

Integer — Radio Signal Strength (dBm)

### `WB_LWM2M_RES_CONN_LINK_QUALITY 3`

Integer — Link Quality.

### `WB_LWM2M_RES_CONN_IP_ADDRESSES 4`

String[] — IP Addresses.

### `WB_LWM2M_RES_CONN_ROUTER_IP 5`

String[] — Router IP Addresses.

### `WB_LWM2M_RES_CONN_LINK_UTILIZATION 6`

Integer — Link Utilization (%)

### `WB_LWM2M_RES_CONN_APN 7`

String[] — APN.

### `WB_LWM2M_RES_CONN_CELL_ID 8`

Integer — Cell ID.

### `WB_LWM2M_RES_CONN_SMNC 9`

Integer — SMNC.

### `WB_LWM2M_RES_CONN_SMCC 10`

Integer — SMCC.

### `WB_LWM2M_OP_READ (1 << 0)`

Server can read this resource.

### `WB_LWM2M_OP_WRITE (1 << 1)`

Server can write this resource.

### `WB_LWM2M_OP_EXECUTE (1 << 2)`

Server can execute this resource.

### `WB_LWM2M_OP_RW (`

Read + Write.

### `WB_LWM2M_VALUE_STRING     (`

Construct a String value.

### `WB_LWM2M_VALUE_STRING_LEN     (`

Construct a String value with explicit length (for non-NUL-terminated)

### `WB_LWM2M_VALUE_INT     (`

Construct a signed Integer value.

### `WB_LWM2M_VALUE_UINT     (`

Construct an unsigned Integer value (LWM2M 1.1+)

### `WB_LWM2M_VALUE_FLOAT     (`

Construct a Float value (double precision)

### `WB_LWM2M_VALUE_BOOL     (`

Construct a Boolean value.

### `WB_LWM2M_VALUE_OPAQUE     (`

Construct an Opaque (binary) value.

### `WB_LWM2M_VALUE_TIME     (`

Construct a Time value (Unix timestamp)

### `WB_LWM2M_VALUE_OBJLINK     (`

Construct an Object Link value.

### `WB_LWM2M_VALUE_CORELNK     (`

Construct a CoRE Link-Format value.

### `WB_LWM2M_MAX_INSTANCES 4`

### `WB_LWM2M_MAX_RESOURCES 24`

## Functions

### wb_lwm2m_type_name

Get type name as string (for logging)

```c
static const char * wb_lwm2m_type_name(wb_lwm2m_res_type_t type)
```

**Parameters:**

- **type** (`wb_lwm2m_res_type_t`)

---

### wb_lwm2m_value_get_int

Get integer from value (auto-converts from int, uint, time, bool)

```c
static int64_t wb_lwm2m_value_get_int(const wb_lwm2m_value_t *v)
```

**Parameters:**

- **v** (`const wb_lwm2m_value_t *`)

---

### wb_lwm2m_value_get_float

Get float from value (auto-converts from int, uint)

```c
static double wb_lwm2m_value_get_float(const wb_lwm2m_value_t *v)
```

**Parameters:**

- **v** (`const wb_lwm2m_value_t *`)

---

### wb_lwm2m_value_is_string

Check if value carries string-like data (String or CoreLnk)

```c
static bool wb_lwm2m_value_is_string(const wb_lwm2m_value_t *v)
```

**Parameters:**

- **v** (`const wb_lwm2m_value_t *`)

---

### wb_lwm2m_value_is_numeric

Check if value carries numeric data (Integer, UInteger, Float, Time)

```c
static bool wb_lwm2m_value_is_numeric(const wb_lwm2m_value_t *v)
```

**Parameters:**

- **v** (`const wb_lwm2m_value_t *`)

---
