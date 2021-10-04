provider "aws" {
  region = "us-west-1"
  access_key = "AKIAUFNPYU5BP4YZWSPC"
  secret_key = "DCVYK9JjX0etE21SQvKLFoZQsXMRhDFMt3cY4iX1"
}

resource "random_pet" "petname" {
  length    = 5
  separator = "-"
}

resource "aws_s3_bucket" "sample" {
  bucket = random_pet.petname.id
  acl    = "public-read"

  region = "us-west-1"
}
