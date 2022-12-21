# clouda-commerce-eks-config
This repository contains terraform scripts to provision cloud infastructer and k8s config files for application deployment

You can run either ECR_Config or EKS_Config 1st. Order doesen't matter.

ECR_Config
    you have to update repository address and token in 0-provider.tf
    aws ecr get-login-password --region us-east-1  
