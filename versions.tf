terraform {
  # 1.10 introduced S3 native state locking (use_lockfile).
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # State lives in the state bucket of the account the function is deployed
  # in. The bucket name contains the AWS account ID, so it is not written
  # here. It is passed at init time:
  # terraform init -backend-config="bucket=<name>". `task init` does this.
  backend "s3" {
    key          = "infra-lambda-budget-ledger-add/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project   = "iaireal"
      ManagedBy = "terraform"
      Repo      = "infra-lambda-budget-ledger-add"
    }
  }
}
