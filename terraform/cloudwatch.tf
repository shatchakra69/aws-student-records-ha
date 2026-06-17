# ---------------------------------------------------------------------------
# Observability: alarms on app-tier CPU and on ALB target health.
# ---------------------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${local.name_prefix}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 120
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "App tier average CPU above 70% for 4 minutes."

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name_prefix}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 60
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  threshold           = 0
  alarm_description   = "One or more app targets are failing ALB health checks."

  dimensions = {
    TargetGroup  = aws_lb_target_group.app.arn_suffix
    LoadBalancer = aws_lb.app.arn_suffix
  }
}
