provider "aws" {
 region  = "eu-central-1"
  assume_role {
      role_arn = "arn:aws:iam::314053136453:role/TerraformRole"
    }

}