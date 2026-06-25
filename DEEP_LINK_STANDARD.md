# OneSignal Push Notification Deep Link Standard

## Overview
This document defines the standardized deep link format for OneSignal push notifications in the Yakut app.

## Standardized Deep Link Format

When sending push notifications via OneSignal, use the following standardized deep link format in the `additionalData` field:

### Supported Routes

| Deep Link Format | Maps To | Description |
|-----------------|---------|-------------|
| `/product/:id` | `/products/:id` | Navigate to product detail screen |
| `/chat/:id` | `/chat/:id` | Navigate to chat room screen |
| `/live/:id` | `/live/:id` | Navigate to live stream screen |

## Implementation Details

### Backend Payload Example
```json
{
  "contents": {
    "en": "New message from seller"
  },
  "data": {
    "deeplink": "/chat/12345"
  }
}
```

### Supported Field Names
The app supports multiple field name variations for the deep link (case-insensitive):
- `deeplink` (recommended)
- `deepLink`
- `deep_link`

### Examples

#### Product Notification
```json
{
  "contents": {
    "en": "New product available!"
  },
  "data": {
    "deeplink": "/product/abc123"
  }
}
```

#### Chat Notification
```json
{
  "contents": {
    "en": "You have a new message"
  },
  "data": {
    "deeplink": "/chat/room456"
  }
}
```

#### Live Stream Notification
```json
{
  "contents": {
    "en": "Live stream started!"
  },
  "data": {
    "deeplink": "/live/stream789"
  }
}
```

## Legacy Support (Backward Compatibility)

The app still supports the legacy type-based routing format for existing integrations:

```json
{
  "contents": {
    "en": "New message"
  },
  "data": {
    "type": "chat",
    "roomId": "12345"
  }
}
```

However, **new implementations should use the standardized `deeplink` format**.

## Notes

- The deep link path is trimmed of whitespace before processing
- `/product/:id` is automatically mapped to `/products/:id` to match the app's router
- `/chat/:id` and `/live/:id` match the router directly
- If an unknown deep link format is provided, it will be passed through as-is with a debug warning
