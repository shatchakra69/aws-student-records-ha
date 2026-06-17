# ---------------------------------------------------------------------------
# Amazon RDS for MySQL in the isolated database subnets. No public access;
# reachable only from the application security group on port 3306.
# ---------------------------------------------------------------------------

resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnets"
  subnet_ids = aws_subnet.db[*].id

  tags = { Name = "${local.name_prefix}-db-subnets" }
}

resource "aws_db_instance" "this" {
  identifier     = "${local.name_prefix}-db"
  engine         = "mysql"
  engine_version = "8.0.43"
  instance_class = var.db_instance_class

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp3"
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = false
  multi_az               = var.db_multi_az

  # Demo-friendly lifecycle: easy to tear down. Tighten these for production.
  skip_final_snapshot = true
  deletion_protection = false
  apply_immediately   = true

  tags = { Name = "${local.name_prefix}-db" }
}
