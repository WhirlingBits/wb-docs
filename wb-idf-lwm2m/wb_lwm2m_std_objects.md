---
id: wb_lwm2m_std_objects
title: Standard Object Factory
sidebar_label: Standard Object Factory
---

# Standard Object Factory

Pre-built factory functions for OMA LWM2M standard objects.

This module provides convenient factory functions that create fully configured `wb_lwm2m_object_def_t` instances for the standard OMA LWM2M objects. Each factory function:

## Functions

### wb_lwm2m_create_conn_mon_object

Create a Connectivity Monitoring Object (/4) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_conn_mon_object(const wb_lwm2m_conn_mon_info_t *info, void *user_ctx)
```

**Parameters:**

- **info** (`const wb_lwm2m_conn_mon_info_t *`): Config with read callback
- **user_ctx** (`void *`): User context

**Returns:**

Heap-allocated object def, or NULL. Caller owns the memory.

Resources: Network Bearer (0), Avail Bearers (1), Signal Strength (2), Link Quality (3), IP Addresses (4), Router IPs (5), Link Utilization (6), APN (7), Cell ID (8), SMNC (9), SMCC (10)

---

### wb_lwm2m_create_conn_stats_object

Create a Connectivity Statistics Object (/7) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_conn_stats_object(const wb_lwm2m_conn_stats_info_t *info, void *user_ctx)
```

**Parameters:**

- **info** (`const wb_lwm2m_conn_stats_info_t *`): Config with callbacks
- **user_ctx** (`void *`): User context

**Returns:**

Heap-allocated object def, or NULL. Caller owns the memory.

Resources: SMS Tx Counter (0), SMS Rx Counter (1), Tx Data (2), Rx Data (3), Max Message Size (4), Average Message Size (5), Start/Reset (6), Stop (7), Collection Period (8)

---

### wb_lwm2m_create_device_object

Create an LWM2M Device Object (/3) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_device_object(const wb_lwm2m_device_info_t *info, void *user_ctx)
```

**Parameters:**

- **info** (`const wb_lwm2m_device_info_t *`): Device info
- **user_ctx** (`void *`): User context for callbacks

**Returns:**

Heap-allocated object def, or NULL on error. Caller owns the memory.

All mandatory resources (0, 1, 2, 11, 16) are always included. Optional resources are included when the corresponding field in info is non-NULL.

Dynamic resources (battery level, free memory, error code, current time) use a built-in read callback. Override with info->read_cb if needed.

---

### wb_lwm2m_create_firmware_object

Create a Firmware Update Object (/5) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_firmware_object(const wb_lwm2m_firmware_info_t *info, void *user_ctx)
```

**Parameters:**

- **info** (`const wb_lwm2m_firmware_info_t *`): Config with callbacks
- **user_ctx** (`void *`): User context

**Returns:**

Heap-allocated object def, or NULL. Caller owns the memory.

Resources: Package (0), Package URI (1), Update (2), State (3), Update Result (5), Pkg Name (6), Pkg Version (7), Protocol Support (8), Delivery Method (9)

---

### wb_lwm2m_create_location_object

Create a Location Object (/6) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_location_object(const wb_lwm2m_location_info_t *info, void *user_ctx)
```

**Parameters:**

- **info** (`const wb_lwm2m_location_info_t *`): Config with read callback
- **user_ctx** (`void *`): User context

**Returns:**

Heap-allocated object def, or NULL. Caller owns the memory.

Resources: Latitude (0, mandatory), Longitude (1, mandatory), Altitude (2), Radius (3), Velocity (4), Timestamp (5, mandatory), Speed (6)

---

### wb_lwm2m_create_security_object

Create an LWM2M Security Object (/0) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_security_object(const wb_lwm2m_security_info_t *info, uint16_t inst_id)
```

**Parameters:**

- **info** (`const wb_lwm2m_security_info_t *`): Security parameters
- **inst_id** (`uint16_t`): Instance ID (typically 0)

**Returns:**

Heap-allocated object def, or NULL on error. Caller owns the memory.

---

### wb_lwm2m_create_server_object

Create an LWM2M Server Object (/1) definition.

```c
wb_lwm2m_object_def_t * wb_lwm2m_create_server_object(const wb_lwm2m_server_info_t *info, uint16_t inst_id, wb_lwm2m_execute_cb_t reg_update_cb, wb_lwm2m_execute_cb_t disable_cb, void *user_ctx)
```

**Parameters:**

- **info** (`const wb_lwm2m_server_info_t *`): Server parameters
- **inst_id** (`uint16_t`): Instance ID (typically 0)
- **reg_update_cb** (`wb_lwm2m_execute_cb_t`): Optional execute callback for Reg Update Trigger (res 8)
- **disable_cb** (`wb_lwm2m_execute_cb_t`): Optional execute callback for Disable (res 4)
- **user_ctx** (`void *`): User context for callbacks

**Returns:**

Heap-allocated object def, or NULL on error. Caller owns the memory.

---

### wb_lwm2m_destroy_std_object

Free a standard object definition previously created by wb_lwm2m_create_*.

```c
void wb_lwm2m_destroy_std_object(wb_lwm2m_object_def_t *obj)
```

**Parameters:**

- **obj** (`wb_lwm2m_object_def_t *`): Object definition to free (may be NULL)

Safe to call with NULL (no-op). Must be called after the client is destroyed, as the client holds a reference to the object definition.

---
