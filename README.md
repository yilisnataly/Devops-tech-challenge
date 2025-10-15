# DevOps Tech Challenge

This project implements a **Cars REST API** (`cars-api`), deployed on **AWS ECS Fargate** with container images stored in **ECR**, infrastructure automated with **AWS CLI scripts**, and a **CI/CD pipeline with GitHub Actions**.

---

## Author
👩‍💻 **Yilis Nataly**  

---

## Project Description

The application is a **Cars API** with basic REST endpoints, developed in **Python (Flask)** with connection to a **MySQL database**.  

It runs inside Docker containers and is deployed to AWS via **ECS Fargate**.  

## Tech Stack

- **Language & Framework**: Python 3 + Flask  
- **Database**: MySQL (credentials managed via AWS Secrets Manager)  
- **Infrastructure**:  
  - Docker & Docker Compose (local setup)  
  - AWS ECR (image registry)  
  - AWS ECS Fargate (serverless container orchestration)  
  - AWS CloudWatch Logs (centralized logging)  
- **CI/CD**: GitHub Actions
  
## 1. Build and containerize a REST API  

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
## 2. Infrastructure

All required infrastructure is deployed with a single script:

```bash
 infra/aws-deploy.sh
```
This script is structured into two main modes: setup and deploy, allowing it to be executed in different ways depending on the desired action.

setup:
Prepares and validates the basic AWS resources required by the application, including:

- Checking or creating the ECR repository.
- Verifying or creating the ECS cluster.
- Checking or creating the CloudWatch log group.

deploy:
Handles deployment of the application by:
- Registering the ECS task definition (optionally updating the container image if IMAGE_TAG is provided).
- Updating the ECS service with the new task definition.

This ensures:

- ECR repository creation
- ECS cluster setup
- Networking (subnets, security groups)
- CloudWatch log group creation

## 3. Implement CI/CD Pipeline with Github Actions

Pipeline defined in (`.github/workflows/ci-cd.yml`):

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
## 4. Testing

- Unit tests implemented with pytest and pytest-mock
- Database interactions mocked (no dependency on real DB)
- Automatically executed in the CI pipeline

  Example:

  ```bash
  pytest -v
  ```

## 5. Rollback Strategy
Manual rollback from GitHub Actions executing a re-run the workflow with parameter rollback_tag (e.g., cars-api:abc1234).

<img width="328" height="255" alt="Image" src="https://github.com/user-attachments/assets/0e3367e2-8ece-485a-b396-be8e82c8bab2" />

Checking the rollback tag in the logs

<img width="309" height="118" alt="image" src="https://github.com/user-attachments/assets/603a7301-b634-4fcf-9fba-ef4864aefd8f" />

Checking the task definition is taking the correct rollback tag

<img width="383" height="257" alt="Image" src="https://github.com/user-attachments/assets/f9b46b97-d063-463c-a874-cd19e00cf774" />


## 6. Scalability and Resilience

For production environments:

#### ECS Fargate Auto Scaling:

- Configure Service Auto Scaling to increase or decrease containers based on CPU or memory utilization.
- Enables handling traffic spikes without manual intervention.

#### Multi-AZ Deployment:
- Create subnets across multiple Availability Zones.
- Assign subnets to ECS awsvpcConfiguration so that containers are distributed.

#### Load Balancer:
- Use an Application Load Balancer (ALB) to distribute traffic among tasks.
- Configure health checks to automatically remove failed tasks.

#### Database Resilience:
- Use RDS Multi-AZ or Aurora for automatic failover.
- Daily backups and snapshots for disaster recovery.

#### Observability:
- CloudWatch Logs + Metrics for monitoring.
- Alarms on CPU, memory, or HTTP errors.

## 7. Monitoring

CloudWatch Logs: Logs available in local console and streamed to **CloudWatch Logs** in AWS
- Log group: `/ecs/cars-api
  
<img width="1073" height="456" alt="Image" src="https://github.com/user-attachments/assets/97ac3daa-980e-4fdc-9816-ecdc056587c2" />

## 8. Security

- AWS Secrets Manager to store database credentials
- (`ecsTaskExecutionRole`) with least privileges
- No sensitive values exposed in GitHub pipeline; therefore, they are stored as repository secrets 
