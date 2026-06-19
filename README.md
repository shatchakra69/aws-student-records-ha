# Highly Available and Scalable Student Records on AWS

A production grade, three tier web application deployed on AWS as **Infrastructure as Code**.
A student records CRUD app runs behind an **Application Load Balancer** across an
**EC2 Auto Scaling Group** in private subnets, backed by a private **Amazon RDS (MySQL)**
database, all inside a custom VPC with public and private subnet isolation across two
Availability Zones. The same architecture is provided in **both Terraform and AWS CloudFormation**.

[![CI](https://github.com/shatchakra69/AWS-Student-Records/actions/workflows/ci.yml/badge.svg)](https://github.com/shatchakra69/AWS-Student-Records/actions/workflows/ci.yml)

> Built as a personal cloud engineering portfolio project. The entire stack is
> reproducible, automatically validated Infrastructure as Code.

## Architecture

![Architecture diagram](docs/architecture.svg)

<details>
<summary>Text-based version (Mermaid source)</summary>

```mermaid
flowchart TB
    user(["Internet users"])

    subgraph vpc["VPC 10.0.0.0/16"]
        igw["Internet Gateway"]

        subgraph pub["Public subnets (two Availability Zones)"]
            alb["Application Load Balancer"]
            nat["NAT Gateway"]
        end

        subgraph appt["Private app subnets (EC2 Auto Scaling Group)"]
            ec2a["EC2 app server, Zone A<br/>Node.js + NGINX"]
            ec2b["EC2 app server, Zone B<br/>Node.js + NGINX"]
        end

        subgraph datat["Private database subnet"]
            rds[("Amazon RDS for MySQL")]
        end
    end

    user -->|HTTP| igw
    igw --> alb
    alb -->|"routes + health checks"| ec2a
    alb --> ec2b
    ec2a -->|"MySQL :3306"| rds
    ec2b --> rds
    ec2a -. "outbound (updates)" .-> nat
    ec2b -. outbound .-> nat
    nat --> igw

    classDef net fill:#dbeafe,stroke:#2563eb,color:#1e3a8a;
    classDef compute fill:#fef9c3,stroke:#ca8a04,color:#713f12;
    classDef db fill:#ede9fe,stroke:#7c3aed,color:#4c1d95;
    classDef person fill:#e2e8f0,stroke:#475569,color:#0f172a;
    class igw,alb,nat net;
    class ec2a,ec2b compute;
    class rds db;
    class user person;
```
</details>

Request path: **Internet → ALB (port 80) → EC2 app tier (port 80) → RDS MySQL (port 3306)**.
Each tier accepts traffic only from the tier directly in front of it.

| Tier | Service | Placement |
|------|---------|-----------|
| Edge | Application Load Balancer | Public subnets |
| Compute | EC2 Auto Scaling Group (Node.js app) | Private subnets |
| Data | Amazon RDS for MySQL | Private subnets, reachable only by the app tier |
| Egress | NAT Gateway | Public subnet |

**Design highlights**

- **Highly available:** the app tier spans two Availability Zones behind the ALB, and Auto Scaling replaces failed instances automatically.
- **Secure by default:** RDS has no public access, least privilege security groups chain `internet to ALB to app to RDS`, and shell access is via **SSM Session Manager** with no SSH port open.
- **No hardcoded secrets:** the database password is generated at deploy time and stored in **AWS Secrets Manager**, then read by instances through an IAM role.
- **Observability:** CloudWatch alarms on app tier CPU and ALB target health.

## Tech stack

- **App:** Node.js, Express, EJS, MySQL (`mysql2`)
- **Infra:** Terraform and CloudFormation
- **AWS:** VPC, ALB, EC2 Auto Scaling, RDS (MySQL), Secrets Manager, CloudWatch, IAM, NAT and Internet Gateway
- **CI:** GitHub Actions running app lint and test, `terraform validate`, and `cfn-lint`

## Run it locally

The app runs fully on your machine before any AWS deployment.

```bash
# Option A: Docker (app and MySQL together)
docker compose up --build       # then open http://localhost:3000

# Option B: Node directly (needs a local MySQL)
cd app && cp .env.example .env   # edit DB_* values
npm install && npm start
```

Health endpoints: `GET /health` (shallow, used by the ALB) and `GET /health/db` (deep, checks the database).

## Deploy to AWS

First push this repo to GitHub as public so instances can clone the app at boot, then pick one path.

**Terraform** (see [`terraform/README.md`](terraform/README.md)):

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars   # set app_repo_url
terraform init && terraform apply
# open the printed application_url, then run `terraform destroy` when done
```

**CloudFormation** (see [`cloudformation/README.md`](cloudformation/README.md)):

```bash
aws cloudformation deploy --template-file cloudformation/student-records.yaml \
  --stack-name student-records --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides AppRepoUrl=https://github.com/shatchakra69/AWS-Student-Records.git
```

Instances take 3 to 5 minutes to bootstrap and pass health checks. Cost is roughly **$80 per month** if left running 24/7, or a couple of dollars if you tear it down after a demo. Full breakdown in [`docs/cost.md`](docs/cost.md).

## Screenshots

### Live on AWS

The full stack was deployed to AWS and verified end to end, then torn down to avoid ongoing charges. It is fully redeployable with a single `terraform apply`.

![Running live on AWS](docs/screenshots/04-live-on-aws.png)

*The application running on AWS, served by the EC2 Auto Scaling group behind the Application Load Balancer, with records read from the private RDS MySQL database.*

**Verified infrastructure (AWS console):**

| ALB target health | Compute (two AZs) | Database (private) |
|:---:|:---:|:---:|
| ![Target health](docs/screenshots/05-aws-target-health.png) | ![Instances](docs/screenshots/06-aws-instances.png) | ![RDS](docs/screenshots/07-aws-rds.png) |
| **2 of 2 targets healthy** | **2 instances** in `us-east-1a` and `us-east-1b` | **RDS MySQL** private, 2 live connections |

### Application UI

**List view** with search, a live record count, and edit or delete on every row:

![Students list](docs/screenshots/01-students-list.png)

| Add a student | Edit a student |
|---|---|
| ![Add student](docs/screenshots/02-add-student.png) | ![Edit student](docs/screenshots/03-edit-student.png) |

## Repository layout

```
.
├── app/                 # Node.js student records CRUD application
├── terraform/           # Infrastructure as Code (primary)
├── cloudformation/      # Equivalent stack in native AWS CloudFormation
├── docs/                # Cost notes and screenshots
├── Makefile             # Common tasks (make help)
└── .github/workflows/   # CI pipeline
```

## Author

Designed and built solely by **Shat Chakra Pawar Amgothu**.

For any questions, suggestions, or opportunities, feel free to reach out:
- Email: [shatchakra69@gmail.com](mailto:shatchakra69@gmail.com)
- [LinkedIn](https://www.linkedin.com/in/shat-chakra-pawar-amgothu-a6921a2b4/)

## License

[MIT](LICENSE) © Shat Chakra Pawar Amgothu
