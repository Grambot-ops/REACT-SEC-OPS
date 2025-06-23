<p align="center">
  <img alt="AWS Logo" src="https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazon-aws&logoColor=white" />
  <img alt="React Logo" src="https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" />
  <img alt="Node.js Logo" src="https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white" />
  <img alt="Docker Logo" src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img alt="PostgreSQL Logo" src="https://img.shields.io/badge/PostgreSQL-316192?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img alt="OpenTofu Logo" src="https://img.shields.io/badge/OpenTofu-FFDA18?style=for-the-badge&logo=terraform&logoColor=black" />
</p>

# React-Sec-Ops: A Secure 3-Tier Application on AWS

This repository contains the code and infrastructure definitions for a full-stack, 3-tier web application deployed on AWS. The project is designed to demonstrate a modern, secure, and automated approach to cloud application deployment.

## Important Limitation: AWS Learner Lab Environment

The original goal of this project was **100% automated deployment** using OpenTofu. However, through iterative testing, we have conclusively determined that the IAM policies governing the **AWS Learner Lab `LabRole`** include an **explicit `Deny`** on programmatic creation of certain AWS resources, including AWS CodeBuild, CodeCommit, and CloudFront OAI.

This `Deny` policy cannot be overridden, even when using a trusted service like CloudFormation. Therefore, a fully automated deployment is **not possible** within this specific lab environment.

This repository now reflects the necessary **hybrid deployment model**:

1.  **Automated (IaC):** Core infrastructure (VPC, Networking, ECS, RDS, ECR) is deployed via OpenTofu.
2.  **Manual:** CI/CD components (CodePipeline, CodeBuild, etc.) and the CloudFront distribution must be configured manually via the AWS Management Console.

This outcome is a valuable demonstration of diagnosing and adapting to the real-world constraints of managed enterprise or educational cloud environments.

## Table of Contents

- [Learning Objectives & Key Accomplishments](#learning-objectives--key-accomplishments)
- [Project Overview](#project-overview)
- [Architecture Diagram](#architecture-diagram)
- [Key Technologies](#key-technologies)
- [Prerequisites](#prerequisites)
- [Project Setup and Deployment (Hybrid Model)](#project-setup-and-deployment-hybrid-model)
  - [Part A: Automated Infrastructure Deployment (OpenTofu)](#part-a-automated-infrastructure-deployment-opentofu)
  - [Part B: Manual CI/CD & Frontend Configuration (AWS Console)](#part-b-manual-cicd--frontend-configuration-aws-console)
  - [Part C: Pushing Application Code](#part-c-pushing-application-code)
- [Accessing the Application](#accessing-the-application)
- [Project Structure](#project-structure)
- [Security Measures](#security-measures)
- [Cleaning Up](#cleaning-up)

## Learning Objectives & Key Accomplishments

This project serves as a practical demonstration of several core competencies:

- **Infrastructure as Code (IaC) Mastery:** Utilizing OpenTofu to define and manage a complex set of interdependent AWS resources.
- **Cloud-Native Architecture:** Designing a scalable and secure 3-tier architecture using AWS-managed services.
- **DevSecOps Principles:** Implementing security through network segmentation, least privilege, and secure credential management.
- **Advanced Problem-Solving:** Diagnosing un-overridable IAM policy restrictions and adapting the deployment strategy from a fully automated to a hybrid model, documenting the process and constraints.

## Project Overview

The "React-Sec-Ops" project consists of three distinct tiers:

1.  **Presentation Tier (Frontend):** A React.js application, hosted on S3 and served via CloudFront.
2.  **Application Tier (Backend API):** A containerized Node.js/Express REST API running on AWS Fargate.
3.  **Data Tier (Database):** An Amazon Aurora PostgreSQL database in isolated private subnets.

## Architecture Diagram

This diagram illustrates the intended architecture. The CI/CD and CloudFront components, while shown as automated, must be created manually as per the lab's limitations.

```mermaid
graph TB
    %% Styling Classes
    classDef userStyle fill:#f5f5f5,stroke:#333,stroke-width:2px,color:#000
    classDef presentationStyle fill:#ffebee,stroke:#c62828,stroke-width:2px,color:#000
    classDef applicationStyle fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef dataStyle fill:#e3f2fd,stroke:#1565c0,stroke-width:2px,color:#000
    classDef automatedStyle fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px,color:#000
    classDef manualStyle fill:#fff3e0,stroke:#ef6c00,stroke-width:3px,stroke-dasharray: 5 5,color:#000
    classDef securityStyle fill:#fce4ec,stroke:#ad1457,stroke-width:2px,color:#000

    %% User Access
    subgraph UserZone["User Access Layer"]
        User["User Browser"]:::userStyle
    end

    %% Presentation Tier - Manual Setup Required
    subgraph PresentationZone["Presentation Tier - Manual Setup Required"]
        CF["CloudFront Distribution<br/>Global CDN<br/>MANUAL SETUP REQUIRED"]:::manualStyle
        OAI["Origin Access Identity<br/>S3 Bucket Access<br/>MANUAL SETUP REQUIRED"]:::manualStyle
        S3Frontend["S3 Bucket<br/>reactsecops-frontend-hosting<br/>Static Website<br/>OPENTOFU MANAGED"]:::automatedStyle
    end

    %% Application Tier - Automated
    subgraph ApplicationZone["Application Tier - OpenTofu Managed"]
        ALB["Application Load Balancer<br/>Auto Scaling Target<br/>OPENTOFU MANAGED"]:::automatedStyle
        
        subgraph ECSZone["ECS Fargate Cluster"]
            ECSCluster["ECS Cluster<br/>reactsecops-cluster<br/>OPENTOFU MANAGED"]:::automatedStyle
            ECSService["ECS Service<br/>Node.js/Express API<br/>OPENTOFU MANAGED"]:::automatedStyle
            ECSTask["ECS Task Definition<br/>Docker Container<br/>OPENTOFU MANAGED"]:::automatedStyle
        end
        
        ECR["ECR Repository<br/>Container Images<br/>OPENTOFU MANAGED"]:::automatedStyle
    end

    %% Data Tier - Automated
    subgraph DataZone["Data Tier - OpenTofu Managed"]
        Aurora["Aurora PostgreSQL<br/>Multi-AZ Database<br/>Private Subnets<br/>OPENTOFU MANAGED"]:::automatedStyle
        SecretsManager["Secrets Manager<br/>Database Credentials<br/>OPENTOFU MANAGED"]:::automatedStyle
    end

    %% Networking - Automated
    subgraph NetworkZone["Networking - OpenTofu Managed"]
        VPC["VPC<br/>Isolated Network<br/>OPENTOFU MANAGED"]:::automatedStyle
        PublicSubnets["Public Subnets<br/>ALB Placement<br/>OPENTOFU MANAGED"]:::automatedStyle
        PrivateSubnets["Private Subnets<br/>ECS & RDS Placement<br/>OPENTOFU MANAGED"]:::automatedStyle
        SecurityGroups["Security Groups<br/>Network Access Control<br/>OPENTOFU MANAGED"]:::automatedStyle
    end

    %% CI/CD Pipeline - Manual Setup Required
    subgraph CICDZone["CI/CD Pipeline - Manual Setup Required"]
        
        subgraph SourceRepos["Source Code Repositories - MANUAL SETUP"]
            BackendRepo["CodeCommit Repository<br/>reactsecops-backend-api-repo<br/>MANUAL SETUP REQUIRED"]:::manualStyle
            FrontendRepo["CodeCommit Repository<br/>reactsecops-frontend-app-repo<br/>MANUAL SETUP REQUIRED"]:::manualStyle
        end
        
        subgraph BuildProjects["Build Projects - MANUAL SETUP"]
            BackendBuild["CodeBuild Project<br/>reactsecops-backend-build<br/>Docker Build & Push<br/>MANUAL SETUP REQUIRED"]:::manualStyle
            FrontendBuild["CodeBuild Project<br/>reactsecops-frontend-build<br/>React Build & Deploy<br/>MANUAL SETUP REQUIRED"]:::manualStyle
        end
        
        subgraph Pipelines["Deployment Pipelines - MANUAL SETUP"]
            BackendPipeline["CodePipeline<br/>reactsecops-backend-pipeline<br/>Source → Build → Deploy<br/>MANUAL SETUP REQUIRED"]:::manualStyle
            FrontendPipeline["CodePipeline<br/>reactsecops-frontend-pipeline<br/>Source → Build → Deploy<br/>MANUAL SETUP REQUIRED"]:::manualStyle
        end
    end

    %% Main Application Flow
    User ---|"HTTPS Requests"| CF
    CF ---|"Static Content<br/>(React App)"| S3Frontend
    CF ---|"API Requests<br/>/api/*"| ALB
    ALB ---|"Load Balanced<br/>Traffic"| ECSService
    ECSService ---|"Container<br/>Orchestration"| ECSTask
    ECSTask ---|"Database<br/>Queries"| Aurora
    ECSTask ---|"Fetch DB<br/>Credentials"| SecretsManager

    %% CloudFront Configuration
    CF ---|"Secure Access<br/>via OAI"| OAI
    OAI ---|"Bucket Policy<br/>Authorization"| S3Frontend

    %% CI/CD Flow - Backend
    BackendRepo ---|"Git Push<br/>Triggers"| BackendPipeline
    BackendPipeline ---|"Build Stage"| BackendBuild
    BackendBuild ---|"Docker Build<br/>& Push"| ECR
    BackendBuild ---|"Deploy New<br/>Task Definition"| ECSService

    %% CI/CD Flow - Frontend
    FrontendRepo ---|"Git Push<br/>Triggers"| FrontendPipeline
    FrontendPipeline ---|"Build Stage"| FrontendBuild
    FrontendBuild ---|"Deploy Static<br/>Files"| S3Frontend
    FrontendBuild ---|"Cache<br/>Invalidation"| CF

    %% Network Relationships
    ALB -.->|"Deployed in"| PublicSubnets
    ECSService -.->|"Deployed in"| PrivateSubnets
    Aurora -.->|"Deployed in"| PrivateSubnets
    SecurityGroups -.->|"Controls Access"| ECSService
    SecurityGroups -.->|"Controls Access"| Aurora

    %% Deployment Constraints
    subgraph ConstraintsZone["AWS Learner Lab Constraints"]
        Constraint1["IAM Policy Limitations:<br/>• Explicit DENY on CodeBuild creation<br/>• Explicit DENY on CodeCommit creation<br/>• Explicit DENY on CloudFront OAI creation<br/>• Cannot be overridden by CloudFormation<br/>• Requires hybrid deployment model"]:::manualStyle
    end

    %% OpenTofu Outputs Required for Manual Setup
    subgraph OutputsZone["OpenTofu Outputs for Manual Setup"]
        Outputs["Required Outputs:<br/>• alb_dns_name<br/>• ecr_repo_name<br/>• ecs_cluster_name<br/>• ecs_service_name<br/>• frontend_s3_bucket_name<br/>• s3_policy_for_cloudfront_reference"]:::automatedStyle
    end
```

## Key Technologies

- **Frontend:** React.js
- **Backend:** Node.js, Express.js
- **Database:** Amazon Aurora (PostgreSQL Compatible)
- **Containerization:** Docker
- **Infrastructure as Code:** OpenTofu
- **CI/CD:** AWS CodePipeline, AWS CodeBuild, AWS CodeCommit
- **Hosting & Compute:** S3, CloudFront, ECS Fargate
- **Security:** AWS IAM, Secrets Manager, VPC, Security Groups

## Prerequisites

- **Git**
- **AWS CLI** (configured)
- **OpenTofu**
- **Node.js & npm**

## Project Setup and Deployment (Hybrid Model)

### Part A: Automated Infrastructure Deployment (OpenTofu)

This step deploys all the resources that the Learner Lab _allows_ to be created programmatically.

1.  **Clone the Repository**
    ```bash
    git clone <your-repository-url>
    cd react-sec-ops-project
    ```
2.  **Deploy with OpenTofu**
    ```bash
    cd infrastructure
    tofu init
    tofu apply --auto-approve
    ```
3.  **Collect Outputs:** After the apply completes, OpenTofu will have created the core infrastructure. Collect the following output values, which are needed for the manual steps:
    ```bash
    tofu output
    ```
    Save the values for:
    - `alb_dns_name`
    - `ecr_repo_name`
    - `ecs_cluster_name`
    - `ecs_service_name`
    - `frontend_s3_bucket_name`
    - `s3_policy_for_cloudfront_reference` (This is a JSON policy string)

### Part B: Manual CI/CD & Frontend Configuration (AWS Console)

Now, log in to the AWS Console and create the restricted resources.

1.  **Create CodeCommit Repositories:**

    - Navigate to **CodeCommit**.
    - Create two repositories with the exact names: `reactsecops-backend-api-repo` and `reactsecops-frontend-app-repo`.

2.  **Create CloudFront OAI & Apply S3 Policy:**

    - Navigate to **CloudFront** > **Origin access** > **Origin access identities (legacy)**.
    - Click **Create origin access identity**.
    - Once created, click its ID and copy the **S3 canonical user ID**.
    - Navigate to **S3** and find your `reactsecops-frontend-hosting-...` bucket.
    - Go to **Permissions** > **Bucket policy** and click **Edit**.
    - Paste the JSON policy you got from the `s3_policy_for_cloudfront_reference` OpenTofu output.
    - **Replace** the placeholder string `"REPLACE_WITH_OAI_CANONICAL_USER_ID"` with the actual canonical user ID you just copied.
    - Save the policy.

3.  **Create CloudFront Distribution:**

    - Navigate to **CloudFront** > **Create distribution**.
    - **Origin domain:** Select your `reactsecops-frontend-hosting-...` S3 bucket.
    - **S3 bucket access:** Choose **Yes, use OAI** and select the OAI you just created.
    - **Viewer protocol policy:** **Redirect HTTP to HTTPS**.
    - Create the distribution. It will take several minutes to deploy.

4.  **Create CI/CD Pipelines:**
    - Navigate to **CodePipeline** > **Create pipeline**.
    - **Backend Pipeline (`reactsecops-backend-pipeline`):**
      - **Source:** `AWS CodeCommit`, `reactsecops-backend-api-repo`, `main` branch.
      - **Build:** `AWS CodeBuild`. Click **Create project**. In the new window:
        - **Project name:** `reactsecops-backend-build`.
        - **Environment:** Amazon Linux 2, Standard image, check the **Privileged** box.
        - **Service role:** Use existing service role > `LabRole`.
        - **Buildspec:** Use a buildspec file.
        - **Environment Variables (Plaintext):** Add `IMAGE_REPO_NAME` with the value from your `ecr_repo_name` output.
      - **Deploy:** `Amazon ECS`. Choose your `ecs_cluster_name` and `ecs_service_name` from the outputs.
    - **Frontend Pipeline (`reactsecops-frontend-pipeline`):**
      - **Source:** `AWS CodeCommit`, `reactsecops-frontend-app-repo`, `main` branch.
      - **Build:** `AWS CodeBuild`. Click **Create project**.
        - **Project name:** `reactsecops-frontend-build`.
        - **Environment:** Amazon Linux 2, Standard image.
        - **Service role:** Use existing service role > `LabRole`.
        - **Buildspec:** Use a buildspec file.
        - **Environment Variables (Plaintext):** Add `S3_BUCKET_NAME` (from `frontend_s3_bucket_name` output) and `CLOUDFRONT_DISTRIBUTION_ID` (from your manually created distribution).

### Part C: Pushing Application Code

1.  **Configure Frontend:**

    - Open `frontend-app/src/App.js`.
    - Replace the `API_ENDPOINT` placeholder with your `alb_dns_name` output.

2.  **Push Backend Code:**

    - Navigate to `backend-api/`, initialize git, and add the CodeCommit repo as the remote.
    - `git remote add origin <your-backend-repo-url>`
    - `git push -u origin main`

3.  **Push Frontend Code:**
    - Navigate to `frontend-app/`, initialize git, and add the CodeCommit repo as the remote.
    - `git remote add origin <your-frontend-repo-url>`
    - `git push -u origin main`

Pushing the code will trigger the pipelines you created manually.

## Accessing the Application

Once the pipelines complete, find your **Distribution domain name** in the CloudFront console and open it in your browser.

## Project Structure

(This section remains as-is)
...

## Security Measures

(This section remains as-is)
...

## Cleaning Up

To avoid ongoing AWS charges, you must destroy both the automated and manual resources.

1.  **Manual Destruction:**
    - Go to the AWS Console and delete the two **CodePipelines**.
    - Delete the two **CodeBuild projects**.
    - Delete the **CloudFront distribution**.
    - Delete the two **CodeCommit repositories**.
2.  **Automated Destruction:**
    - Navigate to the `infrastructure` directory.
    - Run `tofu destroy --auto-approve`.
