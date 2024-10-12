terraform {
  backend "s3" {
    bucket         = "reorg-bhajdu-tfstate"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
