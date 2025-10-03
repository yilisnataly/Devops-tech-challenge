# DevOps Tech Challenge

This project implements a **Cars REST API** (`cars-api`), deployed on **AWS ECS Fargate** with container images stored in **ECR**, infrastructure automated with **AWS CLI scripts**, and a **CI/CD pipeline with GitHub Actions**.

---

## Author
👩‍💻 **Yilis Nataly**  

---

## Project Description

The application is a **Cars API** with basic REST endpoints, developed in **Python (Flask)** with connection to a **MySQL database**.  

It runs inside Docker containers and is deployed to AWS via **ECS Fargate**.  

## 1️⃣ Build and containerize a REST API  

- Implemented a Flask-based REST API to manage a collection of cars.  
- Endpoints:  
  - `GET /cars` → Get list of cars  
  - `POST /cars` → Add a new car  
  - `PUT /cars/{id}` → Update a car
 
### Build a Docker Image

Create a Docker image with the necessary code to start the server: 
```bash 
docker build --no-cache -t flask-cars-app
```
### Local execution with Docker Compose  

```bash
docker-compose up --build
```
It runs the containers defined in the ```docker-compose.yaml``` file and maps a local port to access the server
<img width="1109" height="374" alt="Image" src="https://github.com/user-attachments/assets/d3ab8a3d-3113-424f-bd43-49f76fca43d6" />

### Checking server endpoints
Once the server has been started, it is possible to test the features implemented by the server.

- Checking FastAPI server, through calls to the different endpoints:

  - Make a GET request to the /create-table endpoint:
    Returns the response:
    ```bash
    Tabla cars creada
    ```

  - Make a POST request to the /cars: endpoint:
    ```bash
    curl -X POST http://127.0.0.1:5000/cars -H "Content-Type: application/json" -d '{"brand": "Volkswagen", "model": "Golf", "year": 2018}'
    curl -X POST http://127.0.0.1:5000/cars -H "Content-Type: application/json" -d '{"brand": "Volkswagen", "model": "T-cross", "year": 2021}'
    ```
    Returns the following output:
    ```bash
    {
      "brand": "Volkswagen",
      "id": 1,
      "model": "Golf",
      "year": 2018
    }
    ```
  - Make a GET request to the /cars: endpoint:
    ```bash
    curl http://127.0.0.1:5000/cars
    ```
    Returns the list of stored cars:
    ```bash
    [
      {
        "brand": "Volkswagen",
        "id": 1,
        "model": "Golf",
        "year": 2018
      },
      {
        "brand": "Volkswagen",
        "id": 2,
        "model": "T-cross",
        "year": 2021
      }
    ]
    ```
  - Make a PUT request to the /cars/{id} endpoint:
    ```bash
    curl -X PUT http://127.0.0.1:5000/cars/1 -H "Content-Type: application/json" -d '{"brand": "Volkswagen", "model": "Polo", "year": 2019}'
    ```
    Update an existing car by id:
    ```bash
    {
      "brand": "Volkswagen",
      "id": 1,
      "model": "Polo",
      "year": 2019
    }
    curl http://127.0.0.1:5000/cars
    [
      {
        "brand": "Volkswagen",
        "id": 1,
        "model": "Polo",
        "year": 2019
      },
      {
        "brand": "Volkswagen",
        "id": 2,
        "model": "T-cross",
        "year": 2021
      }
    ```
## Infrastructure

All required infrastructure is deployed with a single script:

```bash
 bash infra/aws-deploy.sh setup
```

This ensures:

- ECR repository creation
- ECS cluster setup
- Networking (subnets, security groups)
- CloudWatch log group creation

## CI/CD Pipeline

Pipeline defined in .github/workflows/ci-cd.yml:

1. Build & Test
   - Run unit tests with pytest
   - Validate business logic
2. Docker Build & Push
   - Build image tagged with ${GITHUB_SHA} (no latest used)
   - Push image to ECR
3. Deploy
   - Register new ECS Task Definition
   - Update ECS service in Fargate
4. Rollback (manual)
    - Workflow can be re-run with a rollback_tag input
    - Allows deploying a previous container version
## Testing

- Unit tests implemented with pytest and pytest-mock
- Database interactions mocked (no dependency on real DB)
- Automatically executed in the CI pipeline

  Example:

  ```bash
  pytest -v
  ```

## Rollback Strategy
Option A: Manual from GitHub Actions

Re-run the workflow with parameter rollback_tag (e.g., cars-api:abc1234).

## Scalability and Resilience

For production environments:

- ECS Auto Scaling: Scale tasks based on CPU/Memory usage
- RDS Multi-AZ: Highly available database setup
- ALB (Application Load Balancer): Distribute incoming traffic
- CloudWatch Alarms: Alert on errors, latency, or failures
- IAM Roles with least privilege: Security by design

## Monitoring

CloudWatch Logs: Logs available in local console and streamed to **CloudWatch Logs** in AWS
- Log group: `/ecs/cars-api
- High latency
- ECS task failures
- 5xx errors from the API
  
<img width="1073" height="456" alt="Image" src="https://github.com/user-attachments/assets/97ac3daa-980e-4fdc-9816-ecdc056587c2" />

## Security

- AWS Secrets Manager for sensitive credentials
- ecsTaskExecutionRole with least privileges
- No sensitive values exposed in GitHub pipeline
