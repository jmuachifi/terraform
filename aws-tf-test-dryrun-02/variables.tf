variable "tags" {
  description = "A map of tags to add to all resources"
  type = object({
    Project     = string,
    Environment = string
  })
  default = {
    Project     = "tf-test-dryrun-02"
    Environment = "dev"
  }
}