---
id: index
slug: /
title: WhirlingBits CoAP Client Documentation
sidebar_label: Overview
---

# WhirlingBits CoAP Client Documentation

The **wb-idf-coap-client** component provides a simplified, event-driven CoAP client for ESP-IDF projects. Built on top of , it offers an API similar to `esp_mqtt_client` with a config-struct + handle pattern, internal request queue, and unified event callback.

- ✅ Simple API : Config-struct + handle pattern (like esp_mqtt_client)
- ✅ Event-Driven : Unified callback for connect, disconnect, response, error
- ✅ Full CRUD : GET, POST, PUT, DELETE requests
- ✅ Observe Support : Subscribe to resource changes (RFC 7641)
- ✅ Thread-Safe : Request functions callable from any FreeRTOS task
- ✅ DTLS Security : Pre-Shared Key (PSK) and PKI certificate modes
- ✅ Request Queue : Internal queue decouples callers from CoAP task
- ✅ Token Tracking : Full token pass-through for request/response correlation
- ✅ Location-Path : Automatic assembly from response options
- ✅ Content Formats : Text, JSON, CBOR, XML, Link-Format, Octet-Stream
- ✅ Configurable : Timeout, task stack, priority, queue size via Kconfig

```
* ┌──────────────────────────────────────┐
* │         User Application Tasks       │
* │   get() / post() / put() / delete()  │
* ├──────────────────────────────────────┤
* │  wb-idf-coap-client                  │
* │  ├── Public API (thread-safe)        │
* │  ├── Internal Request Queue          │
* │  ├── CoAP Processing Task            │
* │  └── Event Dispatcher                │
* ├──────────────────────────────────────┤
* │  libcoap (espressif/coap >= 4.3.4)   │
* ├──────────────────────────────────────┤
* │  ESP-IDF (lwIP, mbedTLS, FreeRTOS)   │
* └──────────────────────────────────────┘
* 
```

The user application enqueues requests through the public API. An internal FreeRTOS task processes requests sequentially, manages the CoAP session, and dispatches events back to the user via the registered callback.

**Option 1: EXTRA_COMPONENT_DIRS**

```c
# In your project CMakeLists.txt, before project()
list(APPEND EXTRA_COMPONENT_DIRS "/path/to/wb-idf-coap-client")
```

**Option 2: idf_component.yml**

```c
dependencies:
  whirlingbits/wb-idf-coap-client:
    version: "*"
    git: https://gitlab.whirlingbits.de/whirlingbits/wb-idf-coap-client.git
```

**Option 3: Git Submodule**

```c
cd components
git submodule add https://gitlab.whirlingbits.de/whirlingbits/wb-idf-coap-client.git
```

```c
#include "wb_coap_client.h"

static void my_handler(wb_coap_event_data_t *event, void *ctx)
{
    switch (event->event) {
    case WB_COAP_EVENT_CONNECTED:
        ESP_LOGI(TAG, "Connected");
        break;
    case WB_COAP_EVENT_RESPONSE: {
        wb_coap_response_t *r = event->response;
        ESP_LOGI(TAG, "Response %d.%02d (%zu bytes)",
                 r->code >> 5, r->code & 0x1F, r->data_len);
        break;
    }
    case WB_COAP_EVENT_DISCONNECTED:
        ESP_LOGW(TAG, "Disconnected");
        break;
    case WB_COAP_EVENT_ERROR:
        ESP_LOGE(TAG, "Error");
        break;
    }
}

void app_main(void)
{
    wb_coap_client_config_t cfg = {
        .uri = "coap://192.168.1.100",
        .event_handler = my_handler,
    };

    wb_coap_client_handle_t client = wb_coap_client_init(&cfg);
    wb_coap_client_start(client);
    wb_coap_client_get(client, "/sensor/temperature");

    // ... later ...
    wb_coap_client_stop(client);
    wb_coap_client_destroy(client);
}
```

| Mode | URI Scheme | Config Fields |
|---|---|---|
| NoSec | coap:// | security = WB_COAP_SECURITY_NONE |
| PSK | coaps:// | security = WB_COAP_SECURITY_PSK + .psk |
| PKI | coaps:// | security = WB_COAP_SECURITY_PKI + .pki |

Mode

URI Scheme

Config Fields

NoSec

coap://

`security = WB_COAP_SECURITY_NONE`

PSK

coaps://

`security = WB_COAP_SECURITY_PSK` + `.psk`

PKI

coaps://

`security = WB_COAP_SECURITY_PKI` + `.pki`

```c
wb_coap_client_config_t cfg = {
    .uri = "coaps://server.example.com",
    .security = WB_COAP_SECURITY_PSK,
    .psk = {
        .identity = "my-device",
        .key = (const uint8_t *)"secret",
        .key_len = 6,
    },
    .event_handler = handler,
};
```

```c
extern const uint8_t ca_start[] asm("_binary_ca_pem_start");
extern const uint8_t ca_end[]   asm("_binary_ca_pem_end");

wb_coap_client_config_t cfg = {
    .uri = "coaps://server.example.com",
    .security = WB_COAP_SECURITY_PKI,
    .pki = {
        .ca_cert     = ca_start,
        .ca_cert_len = (size_t)(ca_end - ca_start),
    },
    .event_handler = handler,
};
```

Register interest in a resource to receive automatic notifications:

```c
wb_coap_client_observe(client, "/sensor/temperature");
// Notifications arrive as WB_COAP_EVENT_RESPONSE events
```

| Option | Default | Description |
|---|---|---|
| WB_COAP_DEFAULT_RESPONSE_TIMEOUT_MS | 10000 | Response timeout (ms) |
| WB_COAP_TASK_STACK_SIZE | 8192 | Internal task stack size |
| WB_COAP_TASK_PRIORITY | 5 | Internal task FreeRTOS priority |
| WB_COAP_REQUEST_QUEUE_SIZE | 8 | Max pending requests in queue |

Option

Default

Description

`WB_COAP_DEFAULT_RESPONSE_TIMEOUT_MS`

10000

Response timeout (ms)

`WB_COAP_TASK_STACK_SIZE`

8192

Internal task stack size

`WB_COAP_TASK_PRIORITY`

5

Internal task FreeRTOS priority

`WB_COAP_REQUEST_QUEUE_SIZE`

8

Max pending requests in queue

Per-instance overrides available via `wb_coap_client_config_t` fields: `response_timeout_ms` , `task_stack_size` , `task_priority` .

All responses arrive asynchronously via the event handler as `WB_COAP_EVENT_RESPONSE` . The `wb_coap_response_t` struct provides:

| Field | Description |
|---|---|
| code | CoAP response code (e.g., 0x45 = 2.05 Content) |
| data | Response payload pointer (valid during callback only) |
| data_len | Payload length in bytes |
| request_path | URI path of the original request |
| request_method | Method of the original request |
| token / token_len | CoAP token for correlation |
| location_path | Assembled Location-Path from response options |

Field

Description

`code`

CoAP response code (e.g., 0x45 = 2.05 Content)

`data`

Response payload pointer (valid during callback only)

`data_len`

Payload length in bytes

`request_path`

URI path of the original request

`request_method`

Method of the original request

`token` / `token_len`

CoAP token for correlation

`location_path`

Assembled Location-Path from response options

| Code | Enum | Meaning |
|---|---|---|
| 2.01 | WB_COAP_RESP_CREATED | Resource created (POST) |
| 2.02 | WB_COAP_RESP_DELETED | Resource deleted |
| 2.04 | WB_COAP_RESP_CHANGED | Resource updated (PUT/POST) |
| 2.05 | WB_COAP_RESP_CONTENT | Content delivered (GET) |
| 4.00 | WB_COAP_RESP_BAD_REQUEST | Malformed request |
| 4.01 | WB_COAP_RESP_UNAUTHORIZED | Authentication required |
| 4.04 | WB_COAP_RESP_NOT_FOUND | Resource not found |
| 5.00 | WB_COAP_RESP_INTERNAL_SERVER_ERROR | Server error |

Code

Enum

Meaning

2.01

WB_COAP_RESP_CREATED

Resource created (POST)

2.02

WB_COAP_RESP_DELETED

Resource deleted

2.04

WB_COAP_RESP_CHANGED

Resource updated (PUT/POST)

2.05

WB_COAP_RESP_CONTENT

Content delivered (GET)

4.00

WB_COAP_RESP_BAD_REQUEST

Malformed request

4.01

WB_COAP_RESP_UNAUTHORIZED

Authentication required

4.04

WB_COAP_RESP_NOT_FOUND

Resource not found

5.00

WB_COAP_RESP_INTERNAL_SERVER_ERROR

Server error

- Request functions (get, post, put, delete, observe) are thread-safe and can be called from any FreeRTOS task.
- The event handler callback is invoked from the internal CoAP task — avoid blocking operations inside it.
- wb_coap_client_is_connected() is safe to call from any context.
- wb_coap_client_start() / stop() / destroy() should not be called concurrently from multiple tasks.

- Insufficient heap memory
- NULL uri or event_handler in config

- DNS resolution failed
- DTLS handshake failed (check PSK/PKI credentials)
- Server unreachable (check firewall, port 5683/5684)

- Server not listening on the path
- Timeout too short (increase response_timeout_ms )
- Firewall blocking UDP

```c
esp_log_level_set("wb_coap", ESP_LOG_DEBUG);
esp_log_level_set("coap", ESP_LOG_DEBUG);
```

| Component | RAM (approx.) |
|---|---|
| Client handle + internal state | ~512 bytes |
| Processing task stack | 8192 bytes (configurable) |
| Request queue (8 entries) | ~256 bytes |
| DTLS session (when using security) | ~10-20 KB |

Component

RAM (approx.)

Client handle + internal state

~512 bytes

Processing task stack

8192 bytes (configurable)

Request queue (8 entries)

~256 bytes

DTLS session (when using security)

~10-20 KB

- ESP-IDF Version: 5.0 or higher
- Dependencies: espressif/coap >= 4.3.4
- Supported SoCs: ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- Network: WiFi or Ethernet (IP connectivity required)
- License: Apache License 2.0

- GitLab Repository
- Issue Tracker
- Examples
- wb-idf-lwm2m (LWM2M client built on this component)

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See LICENSE file in the project root for details.

## Components

### [CoAP Client](./wb_coap_client)

Simplified, event-driven CoAP client wrapper for ESP-IDF.
