provider "aws" {
  alias  = "london"
  region = "eu-west-2"
}

module "vpc-clouda-commerce" {
  source = "./Network_config"
  providers = {
    aws = aws.london
  }
  cluster_name = "clouda-commerce-EKS"
}

module "EKS-cluster-Blue" {
  source = "./EksCluster_config"
  providers = {
    aws = aws.london
  }
  cluster_name    = "clouda-commerce-EKS-Blue"
  cluster_version = "1.20"
  subnet_ids      = module.vpc-clouda-commerce.subnet-ids
}

module "kubectl-update-blue" {
  source = "./KubectlUpdate_config"
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  providers = {
    aws = aws.london
  }
}

module "EKS-Fargate-Blue" {
  source = "./FargateProfile_config"
  providers = {
    aws = aws.london
  }
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  subnet_ids  = module.vpc-clouda-commerce.subnet-ids
  depends_on = [
    module.kubectl-update-blue
  ]
}

module "EKS-OIDC-Provider-Blue" {
  source = "./IamOdic_config"
  providers = {
    aws = aws.london
  }
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
}

provider "helm" {
  alias = "blue"
  kubernetes {
    host                   = module.EKS-cluster-Blue.EKS-Cluster.endpoint
    cluster_ca_certificate = base64decode(module.EKS-cluster-Blue.EKS-Cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.EKS-cluster-Blue.EKS-Cluster.id]
      command     = "aws"
    }
  }
}

module "setup-LB-Blue" {
  source = "./ALBController_config"
  providers = {
    aws = aws.london
    helm = helm.blue
  }
  EKS-cluster-OIDC-Provider = module.EKS-OIDC-Provider-Blue.OIDC-Provider
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  vpc = module.vpc-clouda-commerce.vpc-resource
  Fargate-profile = module.EKS-Fargate-Blue.profile
}


module "setup-nginx-ingress" {
  source = "./Nginx_Ingress_Controller_config"
  providers = {
    aws = aws.london
    helm = helm.blue
  }
  EKS-cluster-OIDC-Provider = module.EKS-OIDC-Provider-Blue.OIDC-Provider
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  vpc = module.vpc-clouda-commerce.vpc-resource
  Fargate-profile = module.EKS-Fargate-Blue.profile
  depends_on = [
    module.setup-LB-Blue
  ]
}


