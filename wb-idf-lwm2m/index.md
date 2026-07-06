---
id: index
slug: /
title: WhirlingBits LWM2M Client Documentation
sidebar_label: Overview
---

# WhirlingBits LWM2M Client Documentation

The **wb-idf-lwm2m** component provides a production-ready OMA LWM2M 1.0/1.1 client for ESP-IDF projects. Built on top of , it implements the LWM2M Registration Interface and Object Model, enabling standards-compliant device management with servers such as Eclipse Leshan, ThingsBoard, or AVSystem Coiote.

- ✅ LWM2M Registration : Register, Update, Deregister operations
- ✅ Standard Objects : Security (/0), Server (/1), Device (/3), Connectivity Monitoring (/4), Firmware Update (/5), Location (/6), Connectivity Statistics (/7)
- ✅ Custom Objects : Define your own objects with read/write/execute callbacks
- ✅ DTLS Security : Pre-Shared Key and X.509 Certificate modes
- ✅ TLV Encoding : Full encoder/decoder per OMA spec §6.4.3
- ✅ SenML-JSON : Encoding for notifications and resource reads
- ✅ Observe/Notify : Push resource changes to the server
- ✅ OTA Firmware : Firmware Update Object with state machine
- ✅ Value Helpers : Type-safe macros and accessor functions
- ✅ Event-Driven : Unified event callback for all lifecycle events
- ✅ Automatic Updates : Timer-based registration keepalive at 80% lifetime

- wb_lwm2m.h — Client init, start, stop, destroy, notify

- wb_lwm2m_object.h — Object/Resource definitions, value types, callback types, helper macros

- wb_lwm2m_std_objects.h — Factory functions for OMA standard objects (Security, Server, Device, Firmware, Location, …)

- wb_lwm2m_encode.h — CoRE Link-Format and SenML-JSON
- wb_lwm2m_tlv.h — TLV binary encoder/decoder

```
* ┌──────────────────────────────────────┐
* │           User Application           │
* ├──────────────────────────────────────┤
* │  wb-idf-lwm2m                        │
* │  ├── Object/Resource Model           │
* │  ├── Registration Interface          │
* │  ├── Link-Format / SenML Encoding    │
* │  ├── TLV Encoder/Decoder             │
* │  └── Lifecycle Management            │
* ├──────────────────────────────────────┤
* │  wb-idf-coap-client                  │
* │  └── GET / POST / PUT / DELETE       │
* │  └── Observe / DTLS-PSK / DTLS-PKI  │
* ├──────────────────────────────────────┤
* │  libcoap (espressif/coap)            │
* ├──────────────────────────────────────┤
* │  ESP-IDF (lwIP, mbedTLS, FreeRTOS)   │
* └──────────────────────────────────────┘
* 
```

Add to your ESP-IDF project via `idf_component.yml` :

```c
dependencies:
  whirlingbits/wb-idf-lwm2m:
    version: "*"
    git: https://gitlab.whirlingbits.de/whirlingbits/wb-idf-lwm2m.git
```

Or clone into your project's `components/` directory:

```c
cd components
git submodule add https://gitlab.whirlingbits.de/whirlingbits/wb-idf-lwm2m.git
```

```c
#include "wb_lwm2m.h"
#include "wb_lwm2m_object.h"
#include "wb_lwm2m_std_objects.h"

// 1. Create standard objects via factory functions
wb_lwm2m_object_def_t *security_obj = wb_lwm2m_create_security_object(
    &(wb_lwm2m_security_info_t){
        .server_uri = "coaps://server.example.com:5684",
        .mode = WB_LWM2M_SEC_MODE_PSK,
        .short_server_id = 1,
        .pub_key_identity = (const uint8_t *)"my-device",
        .pub_key_identity_len = 9,
        .secret_key = psk_key,
        .secret_key_len = sizeof(psk_key),
    }, 0);

wb_lwm2m_object_def_t *server_obj = wb_lwm2m_create_server_object(
    &(wb_lwm2m_server_info_t){
        .short_server_id = 1,
        .lifetime = 300,
        .binding = "U",
    }, 0, NULL, NULL, NULL);

wb_lwm2m_object_def_t *device_obj = wb_lwm2m_create_device_object(
    &(wb_lwm2m_device_info_t){
        .manufacturer     = "WhirlingBits",
        .model_number     = "ESP32-WB-LWM2M",
        .serial_number    = "0001",
        .binding          = "U",
        .firmware_version = "1.0.0",
        .reboot_cb        = my_reboot_cb,
    }, NULL);

// 2. Create and configure the client
wb_lwm2m_client_config_t config = {
    .server_uri    = "coaps://server.example.com:5684",
    .endpoint_name = "my-device",
    .lifetime      = 300,
    .binding       = "U",
    .lwm2m_version = "1.0",
    .security      = WB_COAP_SECURITY_PSK,
    .psk = { .identity = "my-device", .key = psk_key, .key_len = sizeof(psk_key) },
    .event_handler = my_event_handler,
};

wb_lwm2m_client_handle_t lwm2m = wb_lwm2m_init(&config);

// 3. Register objects (MUST be before start)
wb_lwm2m_add_object(lwm2m, security_obj);
wb_lwm2m_add_object(lwm2m, server_obj);
wb_lwm2m_add_object(lwm2m, device_obj);

// 4. Start — connects and registers with the LWM2M server
wb_lwm2m_start(lwm2m);

// 5. Periodically push telemetry
while (1) {
    vTaskDelay(pdMS_TO_TICKS(30000));
    if (wb_lwm2m_is_registered(lwm2m)) {
        wb_lwm2m_notify(lwm2m, WB_LWM2M_OBJ_DEVICE, 0,
                        WB_LWM2M_RES_DEVICE_MEMORY_FREE);
    }
}

// 6. Clean shutdown
wb_lwm2m_stop(lwm2m);
wb_lwm2m_destroy(lwm2m);
wb_lwm2m_destroy_std_object(security_obj);
wb_lwm2m_destroy_std_object(server_obj);
wb_lwm2m_destroy_std_object(device_obj);
```

| Mode | URI Scheme | Config |
|---|---|---|
| NoSec | coap:// | security = WB_COAP_SECURITY_NONE |
| PSK | coaps:// | security = WB_COAP_SECURITY_PSK + .psk |
| PKI | coaps:// | security = WB_COAP_SECURITY_PKI + .pki |

Mode

URI Scheme

Config

NoSec

coap://

`security = WB_COAP_SECURITY_NONE`

PSK

coaps://

`security = WB_COAP_SECURITY_PSK` + `.psk`

PKI

coaps://

`security = WB_COAP_SECURITY_PKI` + `.pki`

The Security Object (/0) must use the matching `wb_lwm2m_security_mode_t` .

| Option | Default | Description |
|---|---|---|
| WB_LWM2M_DEFAULT_LIFETIME | 86400 | Registration lifetime (seconds) |
| WB_LWM2M_DEFAULT_BINDING | "U" | Binding mode (U=UDP, UQ=UDP+Queue) |
| WB_LWM2M_DEFAULT_VERSION | "1.0" | LWM2M protocol version |
| WB_LWM2M_MAX_OBJECTS | 16 | Maximum number of registerable objects |

Option

Default

Description

`WB_LWM2M_DEFAULT_LIFETIME`

86400

Registration lifetime (seconds)

`WB_LWM2M_DEFAULT_BINDING`

"U"

Binding mode (U=UDP, UQ=UDP+Queue)

`WB_LWM2M_DEFAULT_VERSION`

"1.0"

LWM2M protocol version

`WB_LWM2M_MAX_OBJECTS`

16

Maximum number of registerable objects

| Server | Notes |
|---|---|
| Eclipse Leshan | Open-source reference server, great for development |
| ThingsBoard | IoT platform with LWM2M device profiles |
| AVSystem Coiote | Commercial cloud-based device management |
| WhirlingBits IoT | Custom server with DTLS-PSK support |

Server

Notes

Eclipse Leshan

Open-source reference server, great for development

ThingsBoard

IoT platform with LWM2M device profiles

AVSystem Coiote

Commercial cloud-based device management

WhirlingBits IoT

Custom server with DTLS-PSK support

- Client-initiated only : Server-initiated Read/Write/Execute (where the LWM2M server sends CoAP requests to the device) is not yet supported.
- No Bootstrap : LWM2M Bootstrap interface is not implemented.
- No Block-wise OTA : Firmware Update object execution is application-level.

- ESP-IDF Version: 5.0 or higher
- Dependencies: wb-idf-coap-client, espressif/coap >= 4.3.4
- Supported SoCs: ESP32, ESP32-S2, ESP32-S3, ESP32-C3, ESP32-C6
- Network: WiFi or Ethernet (IP connectivity required)
- License: Apache License 2.0

- GitLab Repository
- Issue Tracker
- wb-idf-coap-client
- Examples

Copyright (c) 2024 WhirlingBits

Licensed under the Apache License, Version 2.0. See LICENSE file in the project root for details.

## Components

### [Client Lifecycle](./wb_lwm2m)

LWM2M client initialization, registration, and runtime management.

### [Object / Resource Model](./wb_lwm2m_object)

LWM2M data model with typed resources and callback-driven access.

### [Standard Object Factory](./wb_lwm2m_std_objects)

Pre-built factory functions for OMA LWM2M standard objects.

### [Encoding Helpers](./wb_lwm2m_encode)

CoRE Link-Format and SenML-JSON encoding for LWM2M payloads.
