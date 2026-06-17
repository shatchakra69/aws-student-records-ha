variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as a prefix for all resources."
  type        = string
  default     = "student-records"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
  default     = "10.0.0.0/16"
}

variable "az_count" {
  description = "Number of Availability Zones to spread across (>= 2 for HA)."
  type        = number
  default     = 2
}

# --- Application tier ---
variable "instance_type" {
  description = "EC2 instance type for the application tier."
  type        = string
  default     = "t3.micro"
}

variable "asg_min" {
  description = "Minimum number of app instances."
  type        = number
  default     = 2
}

variable "asg_desired" {
  description = "Desired number of app instances."
  type        = number
  default     = 2
}

variable "asg_max" {
  description = "Maximum number of app instances."
  type        = number
  default     = 3
}

variable "app_port" {
  description = "Port the Node.js app listens on (behind NGINX)."
  type        = number
  default     = 3000
}

variable "app_repo_url" {
  description = "Public Git URL the EC2 instances clone the app from at boot. Set this after you push the repo to GitHub."
  type        = string
}

variable "app_repo_branch" {
  description = "Git branch to deploy."
  type        = string
  default     = "main"
}

# --- Database tier ---
variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name created in RDS."
  type        = string
  default     = "student_records"
}

variable "db_username" {
  description = "Master username for RDS."
  type        = string
  default     = "appuser"
}

variable "db_allocated_storage" {
  description = "RDS storage size in GB."
  type        = number
  default     = 20
}

variable "db_multi_az" {
  description = "Deploy RDS across multiple AZs (higher cost, higher availability)."
  type        = bool
  default     = false
}
