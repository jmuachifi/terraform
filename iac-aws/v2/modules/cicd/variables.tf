
variable "project_name" {

  description = "The name of the project"

  type = string

}



variable "role_arn" {

  description = "The ARN of the IAM role"

  type = string

}



variable "artifact_store_location" {

  description = "The S3 bucket location for artifact storage"

  type = string

}
