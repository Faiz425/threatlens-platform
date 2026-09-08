variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "task_family" {
  description = "Family name for the ECS task definition."
  type        = string
}

variable "cpu" {
  description = "CPU units for the ECS task definition."
  type        = number
}

variable "memory" {
  description = "Memory for the ECS task definition in MiB."
  type        = number
}

variable "execution_role_arn" {
  description = "ARN of the ECS task execution role."
  type        = string
}

variable "container_name" {
  description = "Name of the container in the task definition."
  type        = string
}

variable "container_image" {
  description = "Docker image to run in the ECS task."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service."
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs for the ECS service network configuration."
  type        = list(string)
}

variable "security_group_ids" {
  description = "Security group IDs for the ECS service network configuration."
  type        = list(string)
}

variable "target_group_arn" {
  description = "ARN of the ALB target group"
  type        = string
}

variable "aws_region" {
  description = "AWS region used for ECS CloudWatch logging."
  type        = string
}