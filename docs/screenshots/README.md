# Screenshots

## Application UI (included)

- `01-students-list.png` — records list with search, count, and edit/delete
- `02-add-student.png` — add student form
- `03-edit-student.png` — edit student form

## AWS console (add after your first `terraform apply`)

- The running website via the ALB DNS URL
- EC2 → Target Groups showing 2 **healthy** targets
- EC2 instances spread across two Availability Zones
- RDS instance (Single-AZ, no public access)
- CloudWatch alarms in OK state
