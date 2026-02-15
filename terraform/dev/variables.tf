variable "aws_region" {
  description = "The AWS region to deploy resources in."
  type        = string
  default     = "us-east-2"
}

variable "ssh_key_name" {
  description = "The name of the EC2 Key Pair for SSH"
  type        = string
  default     = "deployer-key"
}

variable "ssh_public_key" {
  description = "The public key to be used for SSH access."
  type        = string
}

variable "runner_ip" {
  description = "The public IP of the GitHub Actions runner."
  type        = string
}
