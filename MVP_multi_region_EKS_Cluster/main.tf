provider "aws" {
  alias = "asia"
  region ="ap-south-1"
}

provider "aws" {
    alias = "europe"
  region ="eu-west-1"
}

provider "aws" {
    alias = "america"
  region ="us-west-1"
}

module "vpc-asia" {
    source = "./Network_config"
    providers = {
      aws = aws.asia
     }
    cluster_name = "clouda-commerce-EKS"
}

module "vpc-europe" {
    source = "./Network_config"
    providers = {
      aws = aws.europe
     }
    cluster_name = "clouda-commerce-EKS"
}

module "vpc-america" {
    source = "./Network_config"
    providers = {
      aws = aws.america
    }
    cluster_name = "clouda-commerce-EKS"
}

output "echo-vpc" {
   value = module.vpc-america.vpc-resource
}