
variable "project_name" {

  description = "The name of the project"

  type = string

}
variable "vpc_id" {
  description = "The VPC ID where the security group will be created"
  type        = string
}
