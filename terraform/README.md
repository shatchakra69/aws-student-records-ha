# Terraform — Student Records infrastructure

Provisions the full highly-available stack: VPC (3-tier subnets across 2 AZs),
NAT/Internet gateways, Application Load Balancer, EC2 Auto Scaling Group, RDS
MySQL, Secrets Manager, IAM, and CloudWatch alarms.

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- AWS CLI configured with credentials (`aws configure`) that can create the
  resources above
- This repository **pushed to a public GitHub repo** (the instances clone the
  app from it at boot)

## Deploy

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars and set app_repo_url to your GitHub URL

terraform init
terraform plan
terraform apply
```

After `apply`, Terraform prints `application_url`. Instances take ~3–5 minutes
to finish their bootstrap and pass health checks; once the ALB shows healthy
targets, open the URL in a browser.

## Inspect a running instance (no SSH key needed)

```bash
aws ssm start-session --target <instance-id>
sudo systemctl status student-records
sudo journalctl -u student-records -f
```

## Tear down (stop all charges)

```bash
terraform destroy
```

## What costs money

Roughly **$45–50/month** if left running 24/7 — dominated by the ALB, the NAT
Gateway, and RDS. Running it for a demo and then `terraform destroy` keeps the
total to a couple of dollars. See [`../docs/cost.md`](../docs/cost.md).

## Notes / production hardening

- HTTP only (no domain/ACM). Add an HTTPS listener + ACM certificate for prod.
- `skip_final_snapshot` and `deletion_protection = false` make teardown easy in
  a demo environment — reverse both for production.
- Single NAT Gateway (cost). For full AZ resilience, run one NAT per AZ.
