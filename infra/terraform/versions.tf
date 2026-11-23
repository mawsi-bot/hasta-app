terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.70" }
  }
  # Remote state is configured per environment via `terraform init -backend-config=...`.
  backend "s3" {}
}

provider "aws" {
  region = var.region
  default_tags { tags = { app = "hasta", env = var.env } }
}
