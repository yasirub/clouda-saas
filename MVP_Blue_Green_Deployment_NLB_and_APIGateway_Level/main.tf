provider "aws" {
  alias  = "frankfurt"
  region = "eu-central-1"
}

module "vpc-clouda-commerce" {
  source = "./Network_config"
  providers = {
    aws = aws.frankfurt
  }
  cluster_name = "clouda-commerce-EKS"
}

module "EKS-cluster-Green" {
  source = "./EksCluster_config"
  providers = {
    aws = aws.frankfurt
  }
  cluster_name    = "clouda-commerce-EKS-Green"
  cluster_version = "1.22"
  subnet_ids      = module.vpc-clouda-commerce.subnet-ids
}

module "EKS-cluster-Blue" {
  source = "./EksCluster_config"
  providers = {
    aws = aws.frankfurt
  }
  cluster_name    = "clouda-commerce-EKS-Blue"
  cluster_version = "1.22"
  subnet_ids      = module.vpc-clouda-commerce.subnet-ids
}

module "EKS-Fargate-Blue" {
  source = "./FargateProfile_config"
  providers = {
    aws = aws.frankfurt
  }
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  subnet_ids  = module.vpc-clouda-commerce.subnet-ids
}

module "EKS-Fargate-Green" {
  source = "./FargateProfile_config"
  providers = {
    aws = aws.frankfurt
  }
  EKS-cluster = module.EKS-cluster-Green.EKS-Cluster
  subnet_ids  = module.vpc-clouda-commerce.subnet-ids
}

module "EKS-OIDC-Provider-Blue" {
  source = "./IamOdic_config"
  providers = {
    aws = aws.frankfurt
  }
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
}

module "EKS-OIDC-Provider-Green" {
  source = "./IamOdic_config"
  providers = {
    aws = aws.frankfurt
  }
  EKS-cluster = module.EKS-cluster-Green.EKS-Cluster
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

provider "helm" {
  alias = "green"
  kubernetes {
    host                   = module.EKS-cluster-Green.EKS-Cluster.endpoint
    cluster_ca_certificate = base64decode(module.EKS-cluster-Green.EKS-Cluster.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.EKS-cluster-Green.EKS-Cluster.id]
      command     = "aws"
    }
  }
}

module "setup-LB-Blue" {
  source = "./ALBController_config"
  providers = {
    aws = aws.frankfurt
    helm = helm.blue
  }
  EKS-cluster-OIDC-Provider = module.EKS-OIDC-Provider-Blue.OIDC-Provider
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  vpc = module.vpc-clouda-commerce.vpc-resource
  Fargate-profile = module.EKS-Fargate-Blue.profile
}

module "setup-LB-Green" {
  source = "./ALBController_config"
  providers = {
    aws = aws.frankfurt
    helm = helm.green
  }
  EKS-cluster-OIDC-Provider = module.EKS-OIDC-Provider-Green.OIDC-Provider
  EKS-cluster = module.EKS-cluster-Green.EKS-Cluster
  vpc = module.vpc-clouda-commerce.vpc-resource
  Fargate-profile = module.EKS-Fargate-Green.profile
}

module "kubectl-update-blue" {
  source = "./KubectlUpdate_config"
  EKS-cluster = module.EKS-cluster-Blue.EKS-Cluster
  config-file = "./k8s_config/ingress_blue.yaml"
  providers = {
    aws = aws.frankfurt
  }
}

module "kubectl-update-green" {
  source = "./KubectlUpdate_config"
  EKS-cluster = module.EKS-cluster-Green.EKS-Cluster
  config-file = "./k8s_config/ingress_green.yaml"
  providers = {
    aws = aws.frankfurt
  }
  depends_on = [
    module.kubectl-update-blue
  ]
}
