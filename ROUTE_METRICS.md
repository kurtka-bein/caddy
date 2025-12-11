# Route ID Metrics Feature

## Overview

This feature adds support for tracking metrics per individual route using the route's `@id` field.

## Changes Made

### 1. Route Structure (`modules/caddyhttp/routes.go`)
- Added `ID string` field to the `Route` struct with JSON tag `@id`
- Created `RouteIDCtxKey` context key for passing route ID through the request context
- Modified `wrapRoute()` to inject route ID into request context when present

### 2. Metrics Configuration (`modules/caddyhttp/metrics.go`)
- Added `PerRoute bool` configuration option to enable per-route metrics
- Updated `initHTTPMetrics()` to include `route_id` label when `PerRoute` is enabled
- Modified `metricsInstrumentedHandler.ServeHTTP()` to extract and use route ID from context

## Usage

### Configuration Example

```json
{
  "apps": {
    "http": {
      "metrics": {
        "per_host": true,
        "per_route": true
      },
      "servers": {
        "srv0": {
          "routes": [
            {
              "@id": "7d1bdf9f-985c-4039-8598-965d131f4c8d",
              "match": [
                {
                  "host": ["example.com"]
                }
              ],
              "handle": [
                {
                  "handler": "reverse_proxy",
                  "upstreams": [
                    {"dial": "backend:8000"}
                  ]
                }
              ]
            }
          ]
        }
      }
    }
  }
}
```

### Caddyfile Example

```caddyfile
{
  servers {
    metrics {
      per_route
    }
  }
}

example.com {
  # Routes added dynamically via Admin API will have @id fields
  reverse_proxy backend:8000
}
```

## Metrics Output

When `per_route: true` is enabled, all HTTP metrics will include the `route_id` label:

```
# Without route_id (PerRoute: false)
caddy_http_requests_total{server="srv0",handler="reverse_proxy",host="example.com",code="200",method="GET"} 42

# With route_id (PerRoute: true)
caddy_http_requests_total{server="srv0",handler="reverse_proxy",host="example.com",route_id="7d1bdf9f-985c-4039-8598-965d131f4c8d",code="200",method="GET"} 42

# Routes without @id will have empty route_id
caddy_http_requests_total{server="srv0",handler="static_response",host="example.com",route_id="",code="200",method="GET"} 10
```

## Affected Metrics

All HTTP metrics now support the optional `route_id` label:

- `caddy_http_requests_in_flight` (gauge)
- `caddy_http_requests_total` (counter)
- `caddy_http_request_errors_total` (counter)
- `caddy_http_request_duration_seconds` (histogram)
- `caddy_http_request_size_bytes` (histogram)
- `caddy_http_response_size_bytes` (histogram)
- `caddy_http_response_duration_seconds` (histogram)

## API Integration

The `@id` field is already supported by Caddy's Admin API. You can query routes by ID:

```bash
curl http://localhost:2019/id/7d1bdf9f-985c-4039-8598-965d131f4c8d/
```

Now these IDs are also available in metrics for monitoring and alerting.

## Notes

- The `@id` field is optional. Routes without an ID will have an empty string as the `route_id` label value.
- The `@id` field is automatically indexed by Caddy's Admin API for easy route management.
- When using dynamic route management (adding/removing routes via API), route IDs provide a stable identifier for metrics tracking.
