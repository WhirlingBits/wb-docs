---
id: wb_idf_sntp_init
title: Initialization & Management
sidebar_label: Initialization & Management
---

# Initialization & Management

Functions for SNTP service initialization and time management.

## Functions

### initialize_sntp

Initialize SNTP service.

```c
void initialize_sntp(void)
```

**Parameters:**

- **** (`void`)

This function initializes the SNTP service and sets the time synchronization mode. It configures the SNTP server and starts the SNTP service.

---

### obtain_time

Obtain current time from SNTP server.

```c
void obtain_time(struct tm *local_time, char *timezone)
```

**Parameters:**

- **local_time** (`struct tm *`): Pointer to struct tm to store the local time
- **timezone** (`char *`): Timezone string (e.g., "CET-1CEST,M3.5.0,M10.5.0/3") or NULL

This function waits for time to be set and then retrieves the current time. It also sets the timezone if provided.

---
