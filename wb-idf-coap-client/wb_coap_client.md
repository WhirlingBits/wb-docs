---
id: wb_coap_client
title: CoAP Client
sidebar_label: CoAP Client
---

# CoAP Client

Simplified, event-driven CoAP client wrapper for ESP-IDF.

This module provides a high-level CoAP client with an API modeled after `esp_mqtt_client` . It wraps libcoap into a simple init/start/request/stop lifecycle with an internal request queue and unified event callback.

## Type Definitions

### `wb_coap_client_handle_t`

```c
typedef struct wb_coap_client* wb_coap_client_handle_t
```

Opaque client handle.

### `wb_coap_event_handler_t`

```c
typedef void(* wb_coap_event_handler_t) (wb_coap_event_data_t *event_data, void *user_ctx)
```

User event handler callback type.

## Enumerations

### `wb_coap_content_format_t`

CoAP content format identifiers.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_COAP_FORMAT_TEXT_PLAIN` | = 0 |  |
| `WB_COAP_FORMAT_LINK_FORMAT` | = 40 |  |
| `WB_COAP_FORMAT_XML` | = 41 |  |
| `WB_COAP_FORMAT_OCTET_STREAM` | = 42 |  |
| `WB_COAP_FORMAT_JSON` | = 50 |  |
| `WB_COAP_FORMAT_CBOR` | = 60 |  |

### `wb_coap_event_t`

CoAP event types delivered to the user callback.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_COAP_EVENT_CONNECTED` |  | CoAP/DTLS session established. |
| `WB_COAP_EVENT_DISCONNECTED` |  | Session lost or closed. |
| `WB_COAP_EVENT_RESPONSE` |  | Response or Observe notification received. |
| `WB_COAP_EVENT_ERROR` |  | Internal error occurred. |

### `wb_coap_method_t`

CoAP request method enumeration.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_COAP_METHOD_GET` | = 1 |  |
| `WB_COAP_METHOD_POST` | = 2 |  |
| `WB_COAP_METHOD_PUT` | = 3 |  |
| `WB_COAP_METHOD_DELETE` | = 4 |  |

### `wb_coap_response_code_t`

CoAP response codes.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_COAP_RESP_CREATED` | = 0x41 |  |
| `WB_COAP_RESP_DELETED` | = 0x42 |  |
| `WB_COAP_RESP_VALID` | = 0x43 |  |
| `WB_COAP_RESP_CHANGED` | = 0x44 |  |
| `WB_COAP_RESP_CONTENT` | = 0x45 |  |
| `WB_COAP_RESP_BAD_REQUEST` | = 0x80 |  |
| `WB_COAP_RESP_UNAUTHORIZED` | = 0x81 |  |
| `WB_COAP_RESP_FORBIDDEN` | = 0x83 |  |
| `WB_COAP_RESP_NOT_FOUND` | = 0x84 |  |
| `WB_COAP_RESP_INTERNAL_SERVER_ERROR` | = 0xA0 |  |

### `wb_coap_security_t`

DTLS security mode selection.

| Enumerator | Value | Description |
|------------|-------|-------------|
| `WB_COAP_SECURITY_NONE` |  | Plain CoAP over UDP (no encryption) |
| `WB_COAP_SECURITY_PSK` |  | DTLS with Pre-Shared Key. |
| `WB_COAP_SECURITY_PKI` |  | DTLS with X.509 certificates. |

## Macros

### `WB_COAP_CONNECTED_BIT BIT0`

Set when session is established.

### `WB_COAP_FAIL_BIT BIT1`

Set when connection attempt fails.

### `WB_COAP_LOCATION_MAX 128`

Maximum length for assembled Location-Path string.

### `WB_COAP_TOKEN_MAX_LEN 8`

Maximum CoAP token length per RFC 7252 (up to 8 bytes)

## Functions

### wb_coap_client_delete

Send a DELETE request.

```c
esp_err_t wb_coap_client_delete(wb_coap_client_handle_t client, const char *path)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle
- **path** (`const char *`): URI path

**Returns:**

ESP_OK if the request was queued

---

### wb_coap_client_destroy

Destroy the CoAP client and free all resources.

```c
esp_err_t wb_coap_client_destroy(wb_coap_client_handle_t client)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

---

### wb_coap_client_get

Send a GET request.

```c
esp_err_t wb_coap_client_get(wb_coap_client_handle_t client, const char *path)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle
- **path** (`const char *`): URI path, e.g. "/sensor/temperature"

**Returns:**

ESP_OK if the request was queued

---

### wb_coap_client_init

Initialize the CoAP client.

```c
wb_coap_client_handle_t wb_coap_client_init(const wb_coap_client_config_t *config)
```

**Parameters:**

- **config** (`const wb_coap_client_config_t *`): Pointer to client configuration

**Returns:**

Client handle on success, NULL on failure

Creates internal resources and the CoAP processing task.

---

### wb_coap_client_is_connected

Check whether the CoAP session is currently active.

```c
bool wb_coap_client_is_connected(wb_coap_client_handle_t client)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle

**Returns:**

true if connected

---

### wb_coap_client_observe

Register an observe on a resource (GET with Observe option)

```c
esp_err_t wb_coap_client_observe(wb_coap_client_handle_t client, const char *path)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle
- **path** (`const char *`): URI path to observe

**Returns:**

ESP_OK if the observe request was queued

The server will send notifications whenever the resource changes. Notifications arrive via the event handler as WB_COAP_EVENT_RESPONSE.

---

### wb_coap_client_post

Send a POST request with payload.

```c
esp_err_t wb_coap_client_post(wb_coap_client_handle_t client, const char *path, const uint8_t *data, size_t data_len, wb_coap_content_format_t format)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle
- **path** (`const char *`): URI path
- **data** (`const uint8_t *`): Payload data
- **data_len** (`size_t`): Payload length
- **format** (`wb_coap_content_format_t`): Content format

**Returns:**

ESP_OK if the request was queued

---

### wb_coap_client_put

Send a PUT request with payload.

```c
esp_err_t wb_coap_client_put(wb_coap_client_handle_t client, const char *path, const uint8_t *data, size_t data_len, wb_coap_content_format_t format)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle
- **path** (`const char *`): URI path
- **data** (`const uint8_t *`): Payload data
- **data_len** (`size_t`): Payload length
- **format** (`wb_coap_content_format_t`): Content format

**Returns:**

ESP_OK if the request was queued

---

### wb_coap_client_start

Start / connect the CoAP client.

```c
esp_err_t wb_coap_client_start(wb_coap_client_handle_t client)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

Resolves the server address and establishes a CoAP session.

---

### wb_coap_client_stop

Stop the CoAP client.

```c
esp_err_t wb_coap_client_stop(wb_coap_client_handle_t client)
```

**Parameters:**

- **client** (`wb_coap_client_handle_t`): Client handle

**Returns:**

ESP_OK on success

Tears down the CoAP session but keeps resources allocated.

---
