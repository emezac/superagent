# SuperAgent API Reference Documentation

Welcome to the SuperAgent API documentation. This document provides detailed information on using the SuperAgent API, including endpoints, parameters, responses, authentication, rate limiting, error handling, and examples.

## Base URL
All API requests are made to the following base URL:
```
https://api.superagent.com/api/v1
```

## Authentication
SuperAgent API uses API keys to authenticate requests. You must include your API key in the `Authorization` header of every request. Here is an example of how to set the header:

```
Authorization: Bearer YOUR_API_KEY
```

## Rate Limiting
The SuperAgent API imposes a rate limit of 100 requests per minute. If you exceed this limit, you will receive a `429 Too Many Requests` response. Ensure your application handles rate limits and retries requests as necessary.

## Endpoints

### List All Workflows
- **Endpoint**: `/workflows`
- **Method**: `GET`
- **Description**: Retrieve a list of all workflows.

#### Request
##### Headers
- `Authorization`: `Bearer YOUR_API_KEY`

##### Query Parameters
None

#### Response
- **Status Code**: `200 OK`
- **Body**: A JSON array of workflow objects.

```json
[
  {
    "id": "workflow_123",
    "name": "Daily Report",
    "status": "active"
  },
  {
    "id": "workflow_456",
    "name": "Weekly Backup",
    "status": "inactive"
  }
]
```

#### Example Request

```http
GET /api/v1/workflows HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
```

### Create New Workflow
- **Endpoint**: `/workflows`
- **Method**: `POST`
- **Description**: Create a new workflow.

#### Request
##### Headers
- `Authorization`: `Bearer YOUR_API_KEY`
- `Content-Type`: `application/json`

##### Body Parameters
- `name` (string, required): Name of the workflow.
- `tasks` (array, required): List of tasks included in the workflow.

```json
{
  "name": "New Workflow",
  "tasks": [
    "task1",
    "task2"
  ]
}
```

#### Response
- **Status Code**: `201 Created`
- **Body**: A JSON object containing the newly created workflow details.

```json
{
  "id": "workflow_789",
  "name": "New Workflow",
  "status": "active"
}
```

#### Example Request

```http
POST /api/v1/workflows HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "name": "New Workflow",
  "tasks": ["task1", "task2"]
}
```

### Get Workflow Details
- **Endpoint**: `/workflows/:id`
- **Method**: `GET`
- **Description**: Retrieve details of a specific workflow.

#### Request
##### Headers
- `Authorization`: `Bearer YOUR_API_KEY`

##### Path Parameters
- `id` (string, required): The ID of the workflow.

#### Response
- **Status Code**: `200 OK`
- **Body**: A JSON object containing workflow details.

```json
{
  "id": "workflow_123",
  "name": "Daily Report",
  "status": "active",
  "tasks": ["task1", "task2"]
}
```

#### Example Request

```http
GET /api/v1/workflows/workflow_123 HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
```

### Execute Workflow
- **Endpoint**: `/workflows/:id/execute`
- **Method**: `POST`
- **Description**: Execute a specific workflow.

#### Request
##### Headers
- `Authorization`: `Bearer YOUR_API_KEY`

##### Path Parameters
- `id` (string, required): The ID of the workflow to execute.

#### Response
- **Status Code**: `202 Accepted`
- **Body**: A JSON object indicating the execution status.

```json
{
  "message": "Execution started",
  "workflow_id": "workflow_123"
}
```

#### Example Request

```http
POST /api/v1/workflows/workflow_123/execute HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
```

## Error Handling
The SuperAgent API uses standard HTTP status codes to indicate the success or failure of an API request. In addition to the `429 Too Many Requests` error mentioned in the rate limiting section, here are some common error responses:

- **400 Bad Request**: The request was invalid or cannot be otherwise served.
- **401 Unauthorized**: Authentication failed or API key missing.
- **404 Not Found**: The requested resource could not be found.
- **500 Internal Server Error**: An error occurred on the server.

Error responses include a JSON body with more details:

```json
{
  "error": "Invalid request parameters"
}
```

## Conclusion
This documentation covers the core functionalities of the SuperAgent API. For any further questions or support, please contact the SuperAgent support team.

## Enhanced Examples

Sure! Below are practical code samples in multiple programming languages for creating API endpoints. Each sample includes authentication, error handling, and follows best practices.

### 1. Python (Flask)

```python
from flask import Flask, request, jsonify
from functools import wraps
import jwt
import datetime

app = Flask(__name__)
app.config['SECRET_KEY'] = 'your_secret_key'

def token_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.args.get('token')
        if not token:
            return jsonify({'message': 'Token is missing!'}), 403
        try:
            data = jwt.decode(token, app.config['SECRET_KEY'], algorithms=["HS256"])
        except Exception as e:
            return jsonify({'message': 'Token is invalid!'}), 403
        return f(*args, **kwargs)
    return decorated

@app.route('/login', methods=['POST'])
def login():
    auth = request.json
    if not auth or not 'username' in auth or not 'password' in auth:
        return jsonify({'message': 'Could not verify'}), 401
        
    # Example: Replace with actual user validation
    if auth['username'] == 'user' and auth['password'] == 'password':
        token = jwt.encode({'user': auth['username'], 'exp': datetime.datetime.utcnow() + datetime.timedelta(hours=1)}, app.config['SECRET_KEY'])
        return jsonify({'token': token})
    
    return jsonify({'message': 'Login failed!'}), 401

@app.route('/protected', methods=['GET'])
@token_required
def protected():
    return jsonify({'message': 'This is a protected route'})

if __name__ == '__main__':
    app.run(debug=True)
```

### 2. Node.js (Express)

```javascript
const express = require('express');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;
app.use(bodyParser.json());
const SECRET_KEY = 'your_secret_key';

const authenticateToken = (req, res, next) => {
    const token = req.query.token;
    if (!token) return res.sendStatus(403);
    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
};

app.post('/login', (req, res) => {
    const { username, password } = req.body;
    // Example: Replace with actual user validation
    if (username === 'user' && password === 'password') {
        const token = jwt.sign({ username }, SECRET_KEY, { expiresIn: '1h' });
        return res.json({ token });
    }
    return res.status(401).json({ message: 'Login failed!' });
});

app.get('/protected', authenticateToken, (req, res) => {
    res.json({ message: 'This is a protected route' });
});

app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
});
```

### 3. Java (Spring Boot)

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.*;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.http.ResponseEntity;

import java.util.Date;

@SpringBootApplication
@RestController
@RequestMapping("/api")
public class ApiApplication {

    private static final String SECRET_KEY = "your_secret_key";

    public static void main(String[] args) {
        SpringApplication.run(ApiApplication.class, args);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody User user) {
        // Example: Replace with actual user validation
        if (user.getUsername().equals("user") && user.getPassword().equals("password")) {
            String token = Jwts.builder()
                    .setSubject(user.getUsername())
                    .setExpiration(new Date(System.currentTimeMillis() + 3600000)) // 1 hour
                    .signWith(SignatureAlgorithm.HS256, SECRET_KEY)
                    .compact();
            return ResponseEntity.ok(new AuthResponse(token));
        }
        return ResponseEntity.status(401).body("Login failed!");
    }

    @GetMapping("/protected")
    public ResponseEntity<?> protectedRoute(@RequestHeader("Authorization") String token) {
        // Token validation logic goes here
        return ResponseEntity.ok("This is a protected route");
    }

    // User and AuthResponse classes can be defined as needed
}
```

### Error Handling Best Practices

1. **HTTP Status Codes**: Use appropriate HTTP status codes for responses (e.g., 200 for success, 401 for unauthorized, 404 for not found, etc.).
2. **Consistent JSON Structure**: Always return a consistent JSON structure for error messages to make it easier for clients to handle errors.
3. **Logging**: Implement logging for errors to track issues in production.
4. **Rate Limiting**: Implement rate limiting to protect against abuse of your API.

### Conclusion

These examples show how to create a basic API with authentication and error handling across different programming languages. Ensure to replace placeholder values and implement further validation and security measures as needed for production applications.