terraform {
  backend "s3" {
    bucket       = "potential-plus-tfstate-project-2026"
    key          = "dev/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
  }
}
