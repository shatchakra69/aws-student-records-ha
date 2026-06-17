# ---------------------------------------------------------------------------
# Application tier: a Launch Template + Auto Scaling Group of EC2 instances
# running the Node.js app behind NGINX, in the private app subnets.
# ---------------------------------------------------------------------------

# Latest Ubuntu 22.04 LTS AMI (Canonical).
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "${local.name_prefix}-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  # Require IMDSv2 (mitigates SSRF-based credential theft).
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  user_data = base64encode(templatefile("${path.module}/templates/user-data.sh.tftpl", {
    region          = var.aws_region
    db_host         = aws_db_instance.this.address
    db_port         = aws_db_instance.this.port
    db_name         = var.db_name
    secret_arn      = aws_secretsmanager_secret.db.arn
    app_repo_url    = var.app_repo_url
    app_repo_branch = var.app_repo_branch
    app_port        = var.app_port
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "${local.name_prefix}-app" }
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "${local.name_prefix}-asg-"
  min_size            = var.asg_min
  desired_capacity    = var.asg_desired
  max_size            = var.asg_max
  vpc_zone_identifier = aws_subnet.app[*].id
  target_group_arns   = [aws_lb_target_group.app.arn]

  # Use the ALB's view of health; give instances time to run user-data.
  health_check_type         = "ELB"
  health_check_grace_period = 600

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  # The DB secret must exist before instances boot and try to read it.
  depends_on = [
    aws_secretsmanager_secret_version.db,
    aws_nat_gateway.this,
  ]

  instance_refresh {
    strategy = "Rolling"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target-tracking policy: scale to keep average CPU around 50%.
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name_prefix}-cpu-target-tracking"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
