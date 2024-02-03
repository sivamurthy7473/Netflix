terraform {
  backend "s3" {
    bucket = "qt-devops-bucket-spc"
    key    = "eks/terraform.tfstate"
    region = "us-west-1"
  }
}