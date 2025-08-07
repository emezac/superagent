# SuperAgent AI Framework API Reference

Welcome to the SuperAgent AI Framework API documentation. This document provides comprehensive information about the available endpoints, including authentication, rate limiting, error handling, and usage examples.

## Base URL

All API requests are made to the following base URL:

```
https://api.superagent.ai/v1
```

## Authentication

The SuperAgent AI Framework API uses API keys for authentication. You must include your API key in the `Authorization` header of every request. Your API key is a unique identifier associated with your account.

Example of the `Authorization` header:

```
Authorization: Bearer YOUR_API_KEY
```

## Rate Limiting

To ensure fair usage and service availability, the API implements rate limiting. The standard rate limit is 100 requests per minute. If you exceed this limit, you will receive a `429 Too Many Requests` response. The `Retry-After` header will indicate how long you need to wait before making another request.

## Endpoints

### 1. Get Workflows

#### `GET /workflows`

Retrieve a list of all workflows available in your SuperAgent account.

**Request:**

- **Method:** GET
- **Path:** `/workflows`

**Query Parameters:**

- `limit` (optional): The number of workflows to return. Default is 10.
- `offset` (optional): The number of workflows to skip before starting to collect the result set. Default is 0.

**Response:**

- **200 OK**: Returns a JSON array of workflow objects.
- **401 Unauthorized**: If the API key is missing or invalid.
- **429 Too Many Requests**: If the rate limit is exceeded.

**Example Request:**

```http
GET /workflows?limit=5&offset=10 HTTP/1.1
Host: api.superagent.ai
Authorization: Bearer YOUR_API_KEY
```

**Example Response:**

```json
[
  {
    "id": "workflow1",
    "name": "Data Processing Workflow",
    "status": "active"
  },
  {
    "id": "workflow2",
    "name": "Image Recognition Workflow",
    "status": "inactive"
  }
]
```

### 2. Create a Workflow

#### `POST /workflows`

Create a new workflow in your SuperAgent account.

**Request:**

- **Method:** POST
- **Path:** `/workflows`
- **Headers:**
  - `Content-Type: application/json`
  - `Authorization: Bearer YOUR_API_KEY`

**Request Body:**

```json
{
  "name": "New Workflow",
  "description": "Description of the new workflow",
  "config": {
    "type": "data-processing",
    "parameters": {
      "input": "data.csv",
      "output": "results.json"
    }
  }
}
```

**Response:**

- **201 Created**: Returns the created workflow object.
- **400 Bad Request**: If the request body is missing or invalid.
- **401 Unauthorized**: If the API key is missing or invalid.
- **429 Too Many Requests**: If the rate limit is exceeded.

**Example Request:**

```http
POST /workflows HTTP/1.1
Host: api.superagent.ai
Authorization: Bearer YOUR_API_KEY
Content-Type: application/json

{
  "name": "New Workflow",
  "description": "Description of the new workflow",
  "config": {
    "type": "data-processing",
    "parameters": {
      "input": "data.csv",
      "output": "results.json"
    }
  }
}
```

**Example Response:**

```json
{
  "id": "workflow3",
  "name": "New Workflow",
  "status": "active",
  "description": "Description of the new workflow",
  "config": {
    "type": "data-processing",
    "parameters": {
      "input": "data.csv",
      "output": "results.json"
    }
  }
}
```

### 3. Get Tasks

#### `GET /tasks`

Retrieve a list of all tasks associated with your workflows.

**Request:**

- **Method:** GET
- **Path:** `/tasks`

**Query Parameters:**

- `workflow_id` (optional): Filter tasks by a specific workflow ID.
- `status` (optional): Filter tasks by status (`pending`, `completed`, etc.).

**Response:**

- **200 OK**: Returns a JSON array of task objects.
- **401 Unauthorized**: If the API key is missing or invalid.
- **429 Too Many Requests**: If the rate limit is exceeded.

**Example Request:**

```http
GET /tasks?workflow_id=workflow1&status=completed HTTP/1.1
Host: api.superagent.ai
Authorization: Bearer YOUR_API_KEY
```

**Example Response:**

```json
[
  {
    "id": "task1",
    "workflow_id": "workflow1",
    "status": "completed",
    "result": "success"
  },
  {
    "id": "task2",
    "workflow_id": "workflow1",
    "status": "completed",
    "result": "failure"
  }
]
```

## Error Handling

The API uses standard HTTP status codes to indicate the success or failure of an API request. Common error codes include:

- **400 Bad Request**: The request could not be understood or was missing required parameters.
- **401 Unauthorized**: Authentication failed or user does not have permissions for the requested operation.
- **404 Not Found**: The specified resource could not be found.
- **429 Too Many Requests**: Exceeded the rate limit.
- **500 Internal Server Error**: An error occurred on the server.

## Conclusion

This documentation provides the necessary information to integrate with the SuperAgent AI Framework API. Ensure your requests are authenticated and adhere to rate limits to maintain access. For further assistance, please contact support@superagent.ai.

## Enhanced Examples

To provide you with practical code samples for API endpoints, I'll demonstrate how to create a simple REST API using several programming languages. The API will include authentication, error handling, and best practices.

### 1. Python with Flask

#### Install Dependencies
```bash
pip install Flask Flask-JWT-Extended
```

#### Code Sample
```python
from flask import Flask, jsonify, request
from flask_jwt_extended import JWTManager, create_access_token, jwt_required

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'your_secret_key'
jwt = JWTManager(app)

# Sample user data
users = {"user": "password"}

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')

    if users.get(username) == password:
        access_token = create_access_token(identity=username)
        return jsonify(access_token=access_token), 200
    return jsonify(message="Bad username or password"), 401

@app.route('/protected', methods=['GET'])
@jwt_required()
def protected():
    return jsonify(message="This is a protected route"), 200

@app.errorhandler(404)
def not_found(error):
    return jsonify(message="Resource not found"), 404

if __name__ == '__main__':
    app.run(debug=True)
```

### 2. Node.js with Express

#### Install Dependencies
```bash
npm install express jsonwebtoken body-parser
```

#### Code Sample
```javascript
const express = require('express');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');

const app = express();
const PORT = 3000;
const SECRET_KEY = 'your_secret_key';
app.use(bodyParser.json());

const users = { user: 'password' };

app.post('/login', (req, res) => {
    const { username, password } = req.body;

    if (users[username] && users[username] === password) {
        const token = jwt.sign({ username }, SECRET_KEY, { expiresIn: '1h' });
        return res.status(200).json({ accessToken: token });
    }
    return res.status(401).json({ message: 'Bad username or password' });
});

const authenticateJWT = (req, res, next) => {
    const token = req.headers['authorization']?.split(' ')[1];
    if (token) {
        jwt.verify(token, SECRET_KEY, (err, user) => {
            if (err) {
                return res.sendStatus(403);
            }
            req.user = user;
            next();
        });
    } else {
        res.sendStatus(401);
    }
};

app.get('/protected', authenticateJWT, (req, res) => {
    res.json({ message: 'This is a protected route' });
});

app.use((req, res) => {
    res.status(404).json({ message: 'Resource not found' });
});

app.listen(PORT, () => {
    console.log(`Server running on http://localhost:${PORT}`);
});
```

### 3. Java with Spring Boot

#### Dependencies (Maven)
```xml
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt</artifactId>
    <version>0.9.1</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

#### Code Sample
```java
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.http.ResponseEntity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@SpringBootApplication
@EnableWebSecurity
@RestController
public class ApiApplication {

    private static final String SECRET_KEY = "your_secret_key";
    private static final Map<String, String> users = new HashMap<>() {{
        put("user", "password");
    }};

    public static void main(String[] args) {
        SpringApplication.run(ApiApplication.class, args);
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> user) {
        String username = user.get("username");
        String password = user.get("password");

        if (users.get(username).equals(password)) {
            String token = Jwts.builder()
                    .setSubject(username)
                    .signWith(SignatureAlgorithm.HS256, SECRET_KEY)
                    .compact();
            return ResponseEntity.ok(Map.of("accessToken", token));
        }
        return ResponseEntity.status(401).body(Map.of("message", "Bad username or password"));
    }

    @GetMapping("/protected")
    public ResponseEntity<?> protectedRoute() {
        return ResponseEntity.ok(Map.of("message", "This is a protected route"));
    }

    @ResponseStatus(value = HttpStatus.NOT_FOUND)
    @ExceptionHandler(NoSuchElementException.class)
    public Map<String, String> handleNotFound() {
        return Map.of("message", "Resource not found");
    }

    protected void configure(HttpSecurity http) throws Exception {
        http.csrf().disable()
                .authorizeRequests()
                .anyRequest().authenticated()
                .and()
                .addFilterBefore(new JwtAuthenticationFilter(), UsernamePasswordAuthenticationFilter.class);
    }
}
```

### Best Practices
1. **Use HTTPS**: Always use HTTPS in production to secure your API endpoints.
2. **Rate Limiting**: Implement