---
id: wb_lwm2m_tlv
title: TLV Encoder/Decoder
sidebar_label: TLV Encoder/Decoder
---

# TLV Encoder/Decoder

Binary TLV encoding and decoding per OMA LWM2M spec §6.4.3.

This module implements the OMA LWM2M TLV (Type-Length-Value) binary content-format used for Read responses and Write requests in LWM2M 1.0.

CoAP Content-Format: `application/vnd.oma.lwm2m+tlv` (11542)

## Enumerations

### `wb_lwm2m_tlv_type_t`

TLV Identifier Types (OMA-TS-LightweightM2M_Core §6.4.3)

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_TLV_TYPE_OBJECT_INSTANCE` | = 0x00 | Bits 7-6 = 00. |
| `WB_LWM2M_TLV_TYPE_RESOURCE_INSTANCE` | = 0x40 | Bits 7-6 = 01. |
| `WB_LWM2M_TLV_TYPE_MULTI_RESOURCE` | = 0x80 | Bits 7-6 = 10. |
| `WB_LWM2M_TLV_TYPE_RESOURCE` | = 0xC0 | Bits 7-6 = 11. |

## Macros

### `WB_LWM2M_CONTENT_FORMAT_TLV 11542`

application/vnd.oma.lwm2m+tlv

### `WB_LWM2M_CONTENT_FORMAT_JSON 11543`

application/vnd.oma.lwm2m+json

### `WB_LWM2M_CONTENT_FORMAT_SENML_JSON 110`

application/senml+json

## Functions

### wb_lwm2m_tlv_decode_header

Decode a single TLV record from a buffer.

```c
int wb_lwm2m_tlv_decode_header(const uint8_t *buf, size_t buf_len, wb_lwm2m_tlv_type_t *tlv_type, uint16_t *id, size_t *value_offset, size_t *value_len)
```

**Parameters:**

- **buf** (`const uint8_t *`): Input buffer
- **buf_len** (`size_t`): Remaining buffer length
- **tlv_type** (`wb_lwm2m_tlv_type_t *`): Output: TLV identifier type
- **id** (`uint16_t *`): Output: resource/instance ID
- **value_offset** (`size_t *`): Output: offset of the value data within buf
- **value_len** (`size_t *`): Output: length of the value data

**Returns:**

Total bytes consumed (header + value), or -1 on error

On success, *tlv_type, *id, *value_offset, *value_len describe the record.

---

### wb_lwm2m_tlv_decode_value

Decode a TLV value into an lwm2m_value_t based on the expected type.

```c
esp_err_t wb_lwm2m_tlv_decode_value(wb_lwm2m_res_type_t type, const uint8_t *data, size_t data_len, wb_lwm2m_value_t *value)
```

**Parameters:**

- **type** (`wb_lwm2m_res_type_t`): Expected resource data type
- **data** (`const uint8_t *`): Pointer to the TLV value bytes
- **data_len** (`size_t`): Length of value bytes
- **value** (`wb_lwm2m_value_t *`): Output: decoded value

**Returns:**

ESP_OK on success, ESP_ERR_INVALID_SIZE if length is unexpected

---

### wb_lwm2m_tlv_encode_instance

Encode an entire object instance as concatenated TLV records.

```c
int wb_lwm2m_tlv_encode_instance(const wb_lwm2m_object_def_t *obj, uint16_t inst_id, uint8_t *buf, size_t buf_size)
```

**Parameters:**

- **obj** (`const wb_lwm2m_object_def_t *`): Object definition
- **inst_id** (`uint16_t`): Instance ID
- **buf** (`uint8_t *`): Output buffer
- **buf_size** (`size_t`): Size of output buffer

**Returns:**

Number of bytes written, or -1 on error

Reads each resource via its read callback and concatenates TLV records.

---

### wb_lwm2m_tlv_encode_resource

Encode a single resource value as a TLV record.

```c
int wb_lwm2m_tlv_encode_resource(uint16_t res_id, const wb_lwm2m_value_t *value, uint8_t *buf, size_t buf_size)
```

**Parameters:**

- **res_id** (`uint16_t`): Resource ID
- **value** (`const wb_lwm2m_value_t *`): Resource value to encode
- **buf** (`uint8_t *`): Output buffer
- **buf_size** (`size_t`): Size of output buffer

**Returns:**

Number of bytes written, or -1 on error

Output format (per OMA spec §6.4.3): [type_byte] [id: 1-2 bytes] [length: 0-3 bytes] [value: N bytes]

---
