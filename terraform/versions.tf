terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  # Uncomment this to use the 'ai' profile locally
  #profile = "ai"
  # Profile is set via AWS_PROFILE environment variable
  # In CI: AWS_PROFILE="" (uses default credentials)
  # Locally: AWS_PROFILE=ai (uses 'ai' profile)
  region = "us-east-1"
}

provider "aws" {
  alias   = "us_east_1"
  # Uncomment this to use the 'ai' profile locally
  #profile = "ai"
  # Profile is set via AWS_PROFILE environment variable
  # In CI: AWS_PROFILE="" (uses default credentials)
  # Locally: AWS_PROFILE=ai (uses 'ai' profile)
  region  = "us-east-1"
}