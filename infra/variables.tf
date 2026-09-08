variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "container_image" {
  description = "Docker image URI to deploy to ECS."
  type        = string
  default     = "113462084471.dkr.ecr.eu-west-2.amazonaws.com/threatlens:latest"
}