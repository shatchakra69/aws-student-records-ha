output "application_url" {
  description = "Open this in a browser once instances are healthy."
  value       = "http://${aws_lb.app.dns_name}"
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer."
  value       = aws_lb.app.dns_name
}

output "vpc_id" {
  description = "ID of the created VPC."
  value       = aws_vpc.this.id
}

output "rds_endpoint" {
  description = "RDS endpoint (reachable only from inside the VPC)."
  value       = aws_db_instance.this.address
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret holding DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}
