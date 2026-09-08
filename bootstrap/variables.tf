variable "aws_region" {
  description = "AWS region for the Terraform state bucket"
  type        = string
  default     = "eu-west-2"
}

variable "state_bucket_name" {
  description = "Name of the S3 bucket used for Terraform remote state"
  type        = string
  default     = "threatlens-terraform-state-113462084471"
}