# Highly Available and Scalable Student Records on AWS

A three tier student records web app I built and ran on AWS, defined end to end as
**Infrastructure as Code**. A Node.js CRUD app sits behind an **Application Load Balancer**,
runs on an **EC2 Auto Scaling Group** in private subnets, and keeps its data in a private
**Amazon RDS (MySQL)** database. Everything lives in a custom VPC with separate public and
private subnets across two Availability Zones. I wrote the whole stack twice, once in
**Terraform** and once in **AWS CloudFormation**.

[![CI](https://github.com/shatchakra69/AWS-Student-Records/actions/workflows/ci.yml/badge.svg)](https://github.com/shatchakra69/AWS-Student-Records/actions/workflows/ci.yml)

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

**Design notes**

- The app tier runs in two Availability Zones behind the load balancer, and Auto Scaling replaces any instance that fails its health check.
- The database has no public access. Security groups only allow `internet → ALB → app → RDS`, and I get a shell on the instances through SSM Session Manager instead of opening an SSH port.
- The database password is generated at deploy time, kept in AWS Secrets Manager, and read by the instances through their IAM role, so nothing sensitive lands in the repo.
- CloudWatch alarms watch app CPU and ALB target health.

## Tech stack

- **App:** Node.js, Express, EJS, MySQL (`mysql2`)
- **Infra:** Terraform and CloudFormation
- **AWS:** VPC, ALB, EC2 Auto Scaling, RDS (MySQL), Secrets Manager, CloudWatch, IAM, NAT and Internet Gateway
- **CI/CD:** GitHub Actions running app lint/test, `terraform validate`, `cfn-lint`, security scans (tfsec, Checkov, cfn-nag), and an OIDC deploy pipeline that plans on PRs and applies behind a manual gate (no long-lived keys)

## Run it locally

You can run the app locally before deploying anything to AWS.

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

I deployed the whole stack to AWS, confirmed the app worked end to end, then tore it down so it stops costing money. A single `terraform apply` brings it back.

![Running live on AWS](docs/screenshots/04-live-on-aws.png)

*The app running on AWS. Traffic comes in through the load balancer to the EC2 instances, which read the records from the private RDS database.*

**From the AWS console while it was live:**

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

For any questions, suggestions, or opportunities, feel free to reach me out:
- Email: [shatchakra69@gmail.com](mailto:shatchakra69@gmail.com)
- [LinkedIn](https://www.linkedin.com/in/shat-chakra-pawar-amgothu-a6921a2b4/)

## License

[MIT](LICENSE) © Shat Chakra Pawar Amgothu
