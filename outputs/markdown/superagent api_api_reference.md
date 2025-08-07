# SuperAgent API Reference Documentation

Welcome to the SuperAgent API Reference. This document provides detailed information about the available endpoints, parameters, responses, and usage examples. The API is designed to manage and execute workflows efficiently.

## Base URL
```
https://api.superagent.com
```

## Authentication

All requests to the SuperAgent API require authentication using an API key. The API key should be included in the `Authorization` header as a Bearer token.

### Example
```
Authorization: Bearer YOUR_API_KEY
```

## Rate Limiting

The SuperAgent API enforces rate limiting to ensure fair usage and prevent abuse. The default rate limit is 100 requests per minute. If you exceed this limit, you will receive a `429 Too Many Requests` response.

## Error Handling

The API uses standard HTTP status codes to indicate success or failure. Common error codes include:

- `400 Bad Request`: The request was invalid or cannot be served.
- `401 Unauthorized`: The request requires user authentication.
- `404 Not Found`: The requested resource could not be found.
- `429 Too Many Requests`: Rate limit exceeded.
- `500 Internal Server Error`: An error occurred on the server.

## Endpoints

### 1. List All Workflows

- **Endpoint**: `/api/v1/workflows`
- **Method**: GET
- **Description**: Retrieve a list of all workflows.

#### Request
```http
GET /api/v1/workflows HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
```

#### Response
- **Status Code**: 200 OK
- **Content-Type**: application/json
- **Body**:
  ```json
  [
    {
      "id": "1",
      "name": "Data Processing",
      "created_at": "2023-10-01T00:00:00Z"
    },
    {
      "id": "2",
      "name": "Email Notification",
      "created_at": "2023-10-02T00:00:00Z"
    }
  ]
  ```

### 2. Create New Workflow

- **Endpoint**: `/api/v1/workflows`
- **Method**: POST
- **Description**: Create a new workflow.

#### Request
- **Headers**:
  - `Content-Type`: application/json
- **Body**:
  ```json
  {
    "name": "New Workflow",
    "steps": [
      {
        "task": "fetch_data",
        "parameters": {
          "url": "https://example.com/data"
        }
      }
    ]
  }
  ```

#### Response
- **Status Code**: 201 Created
- **Content-Type**: application/json
- **Body**:
  ```json
  {
    "id": "3",
    "name": "New Workflow",
    "created_at": "2023-10-03T00:00:00Z"
  }
  ```

### 3. Get Workflow Details

- **Endpoint**: `/api/v1/workflows/:id`
- **Method**: GET
- **Description**: Retrieve details of a specific workflow.

#### Request
```http
GET /api/v1/workflows/1 HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
```

#### Response
- **Status Code**: 200 OK
- **Content-Type**: application/json
- **Body**:
  ```json
  {
    "id": "1",
    "name": "Data Processing",
    "steps": [
      {
        "task": "fetch_data",
        "parameters": {
          "url": "https://example.com/data"
        }
      }
    ],
    "created_at": "2023-10-01T00:00:00Z"
  }
  ```

### 4. Execute Workflow

- **Endpoint**: `/api/v1/workflows/:id/execute`
- **Method**: POST
- **Description**: Execute a specific workflow.

#### Request
```http
POST /api/v1/workflows/1/execute HTTP/1.1
Host: api.superagent.com
Authorization: Bearer YOUR_API_KEY
```

#### Response
- **Status Code**: 200 OK
- **Content-Type**: application/json
- **Body**:
  ```json
  {
    "message": "Workflow execution started",
    "workflow_id": "1",
    "execution_id": "12345"
  }
  ```

## Conclusion

This API documentation provides a comprehensive guide to interacting with the SuperAgent API, including endpoints for managing workflows and executing them. Please ensure to handle authentication properly and respect the rate limits to maintain uninterrupted access. For further assistance, contact our support team.

## Enhanced Examples

Sure! Below are practical code samples in multiple programming languages for creating API endpoints with authentication, error handling, and best practices. We'll use a simple example of a RESTful API for managing users, which includes a GET and POST endpoint.

### 1. Python (Flask)

**Install Flask:**
```bash
pip install Flask Flask-JWT-Extended
```

**Code:**
```python
from flask import Flask, request, jsonify
from flask_jwt_extended import JWTManager, jwt_required, create_access_token

app = Flask(__name__)
app.config['JWT_SECRET_KEY'] = 'your_secret_key'  # Change this in production
jwt = JWTManager(app)

# Mock database
users = []

@app.route('/register', methods=['POST'])
def register():
    username = request.json.get('username')
    password = request.json.get('password')
    
    if any(user['username'] == username for user in users):
        return jsonify({"msg": "User already exists."}), 400
    
    users.append({"username": username, "password": password})  # Store hashed password in production
    return jsonify({"msg": "User created successfully."}), 201

@app.route('/login', methods=['POST'])
def login():
    username = request.json.get('username')
    password = request.json.get('password')

    user = next((user for user in users if user['username'] == username and user['password'] == password), None)
    if user is None:
        return jsonify({"msg": "Bad username or password"}), 401

    access_token = create_access_token(identity=username)
    return jsonify(access_token=access_token), 200

@app.route('/user', methods=['GET'])
@jwt_required()
def get_user():
    current_user = get_jwt_identity()
    return jsonify(logged_in_as=current_user), 200

if __name__ == '__main__':
    app.run(debug=True)
```

### 2. Node.js (Express)

**Install Express and JWT:**
```bash
npm install express jsonwebtoken body-parser
```

**Code:**
```javascript
const express = require('express');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const users = [];
const SECRET_KEY = 'your_secret_key'; // Change this in production

app.post('/register', (req, res) => {
    const { username, password } = req.body;

    if (users.find(user => user.username === username)) {
        return res.status(400).json({ msg: 'User already exists.' });
    }

    users.push({ username, password }); // Store hashed password in production
    res.status(201).json({ msg: 'User created successfully.' });
});

app.post('/login', (req, res) => {
    const { username, password } = req.body;

    const user = users.find(user => user.username === username && user.password === password);
    if (!user) {
        return res.status(401).json({ msg: 'Bad username or password' });
    }

    const accessToken = jwt.sign({ username }, SECRET_KEY);
    res.json({ accessToken });
});

app.get('/user', authenticateToken, (req, res) => {
    res.json({ loggedInAs: req.user.username });
});

function authenticateToken(req, res, next) {
    const token = req.headers['authorization'] && req.headers['authorization'].split(' ')[1];
    if (!token) return res.sendStatus(401);

    jwt.verify(token, SECRET_KEY, (err, user) => {
        if (err) return res.sendStatus(403);
        req.user = user;
        next();
    });
}

app.listen(3000, () => {
    console.log('Server running on port 3000');
});
```

### 3. Java (Spring Boot)

**Add dependencies in `pom.xml`:**
```xml
<dependency>
    <groupId>io.jsonwebtoken</groupId>
    <artifactId>jjwt</artifactId>
    <version>0.9.1</version>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>
```

**Code:**
```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@SpringBootApplication
public class UserApiApplication {
    public static void main(String[] args) {
        SpringApplication.run(UserApiApplication.class, args);
    }
}

@RestController
@RequestMapping("/api")
class UserController {
    private final List<User> users = new ArrayList<>();

    @PostMapping("/register")
    public String register(@RequestBody User user) {
        if (users.stream().anyMatch(u -> u.getUsername().equals(user.getUsername()))) {
            throw new RuntimeException("User already exists");
        }
        users.add(user); // Store hashed password in production
        return "User created successfully";
    }

    @PostMapping("/login")
    public String login(@RequestBody User user) {
        if (users.stream().noneMatch(u -> u.getUsername().equals(user.getUsername()) && u.getPassword().equals(user.getPassword()))) {
            throw new RuntimeException("Bad username or password");
        }
        // Generate JWT token here
        return "Token"; // Replace with actual token generation
    }

