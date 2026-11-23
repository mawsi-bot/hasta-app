variable "env" {
  type        = string
  description = "dev | staging | production"
  validation {
    condition     = contains(["dev", "staging", "production"], var.env)
    error_message = "env must be dev, staging or production."
  }
}
variable "region" {
  type    = string
  default = "ap-southeast-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.40.0.0/16"
}
variable "server_image" {
  type        = string
  description = "ECR image URI for apps/server"
}
variable "db_instance_class" {
  type    = string
  default = "db.t4g.medium"
}
variable "redis_node_type" {
  type    = string
  default = "cache.t4g.small"
}
