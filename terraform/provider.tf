terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.32.0"
    }
  }

  required_version = "~> 1.3"
}

provider "aws" {
  region = local.common.region

  default_tags {
    tags = {
      "Slyp:Channel"     = "data"
      "Slyp:Principal"   = "common"
      "Slyp:Service"     = local.common.service
      "Slyp:Environment" = local.workspace["name"]
    }
  }
}

terraform {
  backend "s3" {}
}