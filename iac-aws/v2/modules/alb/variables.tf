variable "project_name" {
  description = "The name of the project, used to name resources"
  type        = string
}

variable "internal" {
  description = "Whether the ALB is internal or public"
  type        = bool
  default     = false
}

variable "alb_security_group" {

  description = "Security group ID for the ALB"

  type        = string
}

variable "subnet_ids" {

  description = "List of subnet IDs for the ALB"

  type        = list(string)

}


variable "vpc_id" {
  description = "The VPC ID where the ALB will be deployed"
  type        = string
}

variable "listener_port" {
  description = "The port to use for the ALB listener"
  type        = number
  default     = 80
}

variable "listener_protocol" {
  description = "The protocol to use for the ALB listener (HTTP or HTTPS)"
  type        = string
  default     = "HTTP"
}
