---
id: wb_lwm2m_encode
title: Encoding Helpers
sidebar_label: Encoding Helpers
---

# Encoding Helpers

CoRE Link-Format and SenML-JSON encoding for LWM2M payloads.

This module provides serialization functions used internally by the LWM2M client and available for direct use by applications:

## Functions

### wb_lwm2m_encode_link_format

Encode registered objects as CoRE Link-Format for registration payload.

```c
int wb_lwm2m_encode_link_format(const wb_lwm2m_object_def_t *const *objects, size_t object_count, char *buf, size_t buf_size)
```

**Parameters:**

- **objects** (`const wb_lwm2m_object_def_t *const *`): Array of object definitions
- **object_count** (`size_t`): Number of objects
- **buf** (`char *`): Output buffer
- **buf_size** (`size_t`): Size of output buffer

**Returns:**

Number of bytes written (excluding NUL), or -1 on error

Produces a string like: </1/0>,</3/0>,</5/0>

---

### wb_lwm2m_encode_senml_json

Encode a single resource value as SenML-JSON.

```c
int wb_lwm2m_encode_senml_json(uint16_t obj_id, uint16_t inst_id, uint16_t res_id, const wb_lwm2m_value_t *value, char *buf, size_t buf_size)
```

**Parameters:**

- **obj_id** (`uint16_t`): Object ID
- **inst_id** (`uint16_t`): Instance ID
- **res_id** (`uint16_t`): Resource ID
- **value** (`const wb_lwm2m_value_t *`): Resource value
- **buf** (`char *`): Output buffer
- **buf_size** (`size_t`): Size of output buffer

**Returns:**

Number of bytes written (excluding NUL), or -1 on error

Supports all LWM2M data types: String/CoreLnk -> "vs" (string value) Integer/Time -> "v" (numeric value, signed) UInteger -> "v" (numeric value, unsigned) Float -> "v" (numeric value) Boolean -> "vb" (boolean value) Opaque -> "vd" (base64-encoded data value) Objlink -> "vlo" (object link "objId:instId")

Produces: [{"bn":"/3/0/","n":"0","vs":"WhirlingBits"}]

---

### wb_lwm2m_encode_senml_json_instance

Encode all readable resources of an object instance as SenML-JSON.

```c
int wb_lwm2m_encode_senml_json_instance(const wb_lwm2m_object_def_t *obj, uint16_t inst_id, char *buf, size_t buf_size)
```

**Parameters:**

- **obj** (`const wb_lwm2m_object_def_t *`): Object definition
- **inst_id** (`uint16_t`): Instance ID
- **buf** (`char *`): Output buffer
- **buf_size** (`size_t`): Size of output buffer

**Returns:**

Number of bytes written (excluding NUL), or -1 on error

Iterates all resources, calls each read callback, and produces a single SenML-JSON array with a shared base name.

---
