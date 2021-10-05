provider "aws" {
  region = "us-west-2"
  access_key = ""
  secret_key = ""
}

resource "random_pet" "petname" {
  length    = 5
  separator = "-"
}

resource "aws_s3_bucket" "sample" {
  bucket = random_pet.petname.id
  acl    = "public-read"

  region = "us-west-2"
}
