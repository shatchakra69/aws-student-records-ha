provider "aws" {
  region = var.aws_region

  # Applied to every taggable resource created by this configuration.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
