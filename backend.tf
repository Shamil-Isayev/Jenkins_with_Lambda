terraform {
  backend "s3" {
    bucket = "sisayev-tfstate"
    key    = "fasmt-04.3/terraform.tfstate"
    role_arn = "arn:aws:iam::314053136453:role/TerraformRole"
    region = "eu-central-1"
  }
}