# ---------------------------------------------------------------------------
# Least-privilege security groups. Traffic only flows:
#   internet -> ALB (80) -> app (80) -> RDS (3306)
# Each tier only accepts traffic from the tier in front of it.
# ---------------------------------------------------------------------------

resource "aws_security_group" "alb" {
  name        = "${local.name_prefix}-alb-sg"
  description = "Allow inbound HTTP from the internet to the load balancer"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-alb-sg" }
}

resource "aws_security_group" "app" {
  name        = "${local.name_prefix}-app-sg"
  description = "Allow inbound HTTP from the ALB only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "HTTP from the load balancer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "All outbound (package installs, Secrets Manager, RDS)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-app-sg" }
}

resource "aws_security_group" "rds" {
  name        = "${local.name_prefix}-rds-sg"
  description = "Allow MySQL from the application tier only"
  vpc_id      = aws_vpc.this.id

  ingress {
    description     = "MySQL from the app tier"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name_prefix}-rds-sg" }
}
