# API Documentation for WeatherApp

Welcome to the API documentation for WeatherApp, a comprehensive weather forecasting service. This documentation aims to guide developers on how to integrate and utilize the WeatherApp API to retrieve weather data efficiently.

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Authentication](#authentication)
4. [Endpoints](#endpoints)
   - [Current Weather](#current-weather)
   - [Weather Forecast](#weather-forecast)
   - [Historical Data](#historical-data)
5. [Request and Response Formats](#request-and-response-formats)
6. [Error Handling](#error-handling)
7. [Rate Limiting](#rate-limiting)
8. [Best Practices](#best-practices)
9. [FAQs](#faqs)
10. [Support](#support)

## Introduction

The WeatherApp API provides developers with access to real-time weather data, forecast information, and historical weather records. It is designed to be easy to use, with a consistent and intuitive interface.

## Getting Started

To begin using the WeatherApp API, you need to:

1. Sign up for an API key at [WeatherApp's Developer Portal](https://developer.weatherapp.com).
2. Familiarize yourself with the API's features and capabilities by reading through this documentation.
3. Use the provided API key in your requests to authenticate and access weather data.

## Authentication

The WeatherApp API uses API keys to authenticate requests. You must include your API key in the `Authorization` header of each request.

### Example

```http
GET /weather/current?city=London HTTP/1.1
Host: api.weatherapp.com
Authorization: Bearer YOUR_API_KEY
```

## Endpoints

### Current Weather

Retrieve real-time weather data for a specific location.

- **URL:** `/weather/current`
- **Method:** `GET`
- **Parameters:**
  - `city` (required): Name of the city.
  - `units` (optional): Units of measurement. Options are `metric`, `imperial`. Default is `metric`.

#### Example Request

```http
GET /weather/current?city=London&units=metric HTTP/1.1
Host: api.weatherapp.com
Authorization: Bearer YOUR_API_KEY
```

#### Example Response

```json
{
  "city": "London",
  "temperature": 15,
  "units": "Celsius",
  "conditions": "Partly Cloudy"
}
```

### Weather Forecast

Retrieve weather forecast data for the next 7 days.

- **URL:** `/weather/forecast`
- **Method:** `GET`
- **Parameters:**
  - `city` (required): Name of the city.
  - `days` (optional): Number of days to forecast. Default is 7.

#### Example Request

```http
GET /weather/forecast?city=London&days=5 HTTP/1.1
Host: api.weatherapp.com
Authorization: Bearer YOUR_API_KEY
```

#### Example Response

```json
{
  "city": "London",
  "forecast": [
    {"day": "Monday", "temperature": 16, "conditions": "Sunny"},
    {"day": "Tuesday", "temperature": 14, "conditions": "Rain"},
    // Additional days...
  ]
}
```

### Historical Data

Retrieve historical weather data for a specific date.

- **URL:** `/weather/historical`
- **Method:** `GET`
- **Parameters:**
  - `city` (required): Name of the city.
  - `date` (required): Date in `YYYY-MM-DD` format.

#### Example Request

```http
GET /weather/historical?city=London&date=2023-10-01 HTTP/1.1
Host: api.weatherapp.com
Authorization: Bearer YOUR_API_KEY
```

#### Example Response

```json
{
  "city": "London",
  "date": "2023-10-01",
  "temperature": 12,
  "conditions": "Cloudy"
}
```

## Request and Response Formats

All requests and responses are formatted in JSON. Ensure that your application can handle JSON encoding and decoding.

## Error Handling

The API uses standard HTTP status codes to indicate success or failure of API requests. Here are some common codes:

- `200 OK`: Request was successful.
- `400 Bad Request`: The request could not be understood or was missing required parameters.
- `401 Unauthorized`: Authentication failed or API key is invalid.
- `404 Not Found`: The requested resource could not be found.
- `500 Internal Server Error`: An error occurred on the server.

### Example Error Response

```json
{
  "error": {
    "code": 400,
    "message": "Bad Request: Missing 'city' parameter."
  }
}
```

## Rate Limiting

The WeatherApp API enforces rate limiting to ensure fair use. The default rate limit is 1000 requests per hour per API key. If this limit is exceeded, a `429 Too Many Requests` status will be returned.

## Best Practices

- Always check for the HTTP response status code to handle errors gracefully.
- Cache responses where possible to reduce API requests and improve performance.
- Use the `days` parameter wisely to limit the amount of data returned in forecast requests.

## FAQs

**Q: How do I reset my API key?**  
A: You can reset your API key from the Developer Portal under the "API Keys" section.

**Q: Can I access the API without an API key?**  
A: No, an API key is required for all requests to authenticate and authorize access.

## Support

For further assistance, visit our [Support Page](https://support.weatherapp.com) or contact us at support@weatherapp.com.

---

This documentation should provide a comprehensive guide to integrating with the WeatherApp API. For more detailed information and advanced topics, please refer to the [full documentation](https://docs.weatherapp.com).