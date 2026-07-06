---
id: wb_lwm2m
title: Client Lifecycle
sidebar_label: Client Lifecycle
---

# Client Lifecycle

LWM2M client initialization, registration, and runtime management.

This module provides the top-level API for the wb-idf-lwm2m component. It manages the full client lifecycle:

## Type Definitions

### `wb_lwm2m_client_handle_t`

```c
typedef struct wb_lwm2m_client* wb_lwm2m_client_handle_t
```

Opaque client handle.

### `wb_lwm2m_event_handler_t`

```c
typedef void(* wb_lwm2m_event_handler_t) (wb_lwm2m_event_t *event, void *user_ctx)
```

User event handler callback.

## Enumerations

### `wb_lwm2m_event_type_t`

LWM2M event type enumeration.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_EVENT_CONNECTED` |  | CoAP session established. |
| `WB_LWM2M_EVENT_DISCONNECTED` |  | CoAP session lost. |
| `WB_LWM2M_EVENT_REGISTERED` |  | Registration successful. |
| `WB_LWM2M_EVENT_REG_FAILED` |  | Registration failed. |
| `WB_LWM2M_EVENT_REG_UPDATED` |  | Registration update successful. |
| `WB_LWM2M_EVENT_DEREGISTERED` |  | Deregistration successful. |
| `WB_LWM2M_EVENT_BOOTSTRAP_DONE` |  | Bootstrap completed (future use) |
| `WB_LWM2M_EVENT_ERROR` |  | Generic error. |

### `wb_lwm2m_state_t`

LWM2M client state enumeration.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_LWM2M_STATE_IDLE` |  |  |
| `WB_LWM2M_STATE_CONNECTING` |  |  |
| `WB_LWM2M_STATE_REGISTERING` |  |  |
| `WB_LWM2M_STATE_REGISTERED` |  |  |
| `WB_LWM2M_STATE_UPDATING` |  |  |
| `WB_LWM2M_STATE_DEREGISTERING` |  |  |
| `WB_LWM2M_STATE_ERROR` |  |  |

## Functions

### wb_lwm2m_add_object

Register an LWM2M object with the client.

```c
esp_err_t wb_lwm2m_add_object(wb_lwm2m_client_handle_t client, const wb_lwm2m_object_def_t *obj)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle
- **obj** (`const wb_lwm2m_object_def_t *`): Object definition

**Returns:**

ESP_OK on success

Must be called BEFORE `wb_lwm2m_start()` . The object definition is referenced (not copied), so it must remain valid.

---

### wb_lwm2m_destroy

Destroy the LWM2M client and free all resources.

```c
esp_err_t wb_lwm2m_destroy(wb_lwm2m_client_handle_t client)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

---

### wb_lwm2m_get_state

Get the current LWM2M client state.

```c
wb_lwm2m_state_t wb_lwm2m_get_state(wb_lwm2m_client_handle_t client)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle

**Returns:**

Current state

---

### wb_lwm2m_init

Create an LWM2M client instance.

```c
wb_lwm2m_client_handle_t wb_lwm2m_init(const wb_lwm2m_client_config_t *config)
```

**Parameters:**

- **config** (`const wb_lwm2m_client_config_t *`): Client configuration

**Returns:**

Client handle, or NULL on failure

Allocates resources and creates the underlying CoAP client. Does NOT connect or register yet — call `wb_lwm2m_start()` for that.

---

### wb_lwm2m_is_registered

Check if the client is currently registered.

```c
bool wb_lwm2m_is_registered(wb_lwm2m_client_handle_t client)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle

**Returns:**

true if registered

---

### wb_lwm2m_notify

Notify the server about a changed resource value.

```c
esp_err_t wb_lwm2m_notify(wb_lwm2m_client_handle_t client, uint16_t obj_id, uint16_t inst_id, uint16_t res_id)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle
- **obj_id** (`uint16_t`): Object ID
- **inst_id** (`uint16_t`): Instance ID
- **res_id** (`uint16_t`): Resource ID

**Returns:**

ESP_OK if the notification was queued

Sends a CoAP POST with the resource value in SenML-JSON format. Can be used to proactively push telemetry data.

---

### wb_lwm2m_start

Start the LWM2M client.

```c
esp_err_t wb_lwm2m_start(wb_lwm2m_client_handle_t client)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

Connects the CoAP client and sends the LWM2M Registration request. Registration updates are sent automatically based on the configured lifetime.

---

### wb_lwm2m_stop

Deregister and stop the LWM2M client.

```c
esp_err_t wb_lwm2m_stop(wb_lwm2m_client_handle_t client)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

Sends a Deregistration request and tears down the CoAP session.

---

### wb_lwm2m_update_registration

Send a registration update.

```c
esp_err_t wb_lwm2m_update_registration(wb_lwm2m_client_handle_t client)
```

**Parameters:**

- **client** (`wb_lwm2m_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

Typically called automatically, but can be triggered manually (e.g., after object list changes).

---
