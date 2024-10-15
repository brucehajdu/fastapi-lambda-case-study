# Uncomment the following block to use the local backend
# terraform {
#   backend "local" {
#     path = "terraform.tfstate"
#   }
# }

# Comment this block out to use the local backend above
# Change the bucket name to the bucket you created in the bootstrap step
terraform {
  backend "s3" {
    bucket         = "reorg-bhajdu-tfstate"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
