variable "cluster_name" {
  description = "Name of the ECS cluster."
  type        = string
}

variable "service_name" {
  description = "Name of the ECS service."
  type        = string
}

variable "target_group_arn_suffix" {
  description = "ARN suffix of the ALB target group."
  type        = string
}

variable "load_balancer_arn_suffix" {
  description = "ARN suffix of the Application Load Balancer."
  type        = string
}