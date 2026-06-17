# Cost estimate

Approximate **on-demand** pricing for `us-east-1`, running 24/7. Real cost
depends on traffic, free-tier eligibility, and how long you leave it up.

| Service | Spec | ~Monthly |
|---------|------|----------|
| NAT Gateway | 1 gateway + data processing | ~$33 |
| Application Load Balancer | 1 ALB + minimal LCUs | ~$17 |
| EC2 | 2 × `t3.micro` (app tier) | ~$15 |
| RDS MySQL | `db.t3.micro`, Single-AZ, 20 GB gp3 | ~$15 |
| EBS | 2 × 8 GB gp3 (root volumes) | ~$1 |
| Secrets Manager | 1 secret | ~$0.40 |
| CloudWatch | 2 alarms + basic metrics | ~$0.60 |
| **Total** | | **~$80 / month** |

> The original course presentation estimated **~$48.79/month** — that figure
> assumed free-tier EC2 hours and excluded most NAT Gateway data processing.
> The table above is the fuller on-demand picture.

## Keeping it cheap

The NAT Gateway, ALB, and RDS are billed per hour whether or not anyone uses
the app. For a portfolio demo:

1. `terraform apply` (or deploy the CloudFormation stack)
2. Capture screenshots / record a short demo
3. `terraform destroy` (or delete the stack)

Spinning it up for an hour or two costs **a couple of dollars at most**.

## Cheaper variants

- Replace the NAT Gateway with a NAT instance on `t3.micro` (saves ~$30/mo).
- Use VPC interface endpoints for Secrets Manager + SSM and drop the NAT
  Gateway entirely if the app needs no other outbound internet.
- Scale the ASG `desired` to 1 while idle (loses single-AZ-failure tolerance).
