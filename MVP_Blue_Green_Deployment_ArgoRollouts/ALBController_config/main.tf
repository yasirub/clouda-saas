terraform {
  required_providers{
    aws ={
        source = "hashicorp/aws"
        version = ">=2.7.0"
        configuration_aliases = [ aws ]
    }
    helm={
        version = ">=1.3.2"
        source = "hashicorp/helm"
    }
    kubernetes = {
        version = ">=1.13.3"
        source = "hashicorp/kubernetes"
    }

  }
}

data "aws_iam_policy_document" "aws_load_balancer_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(var.EKS-cluster-OIDC-Provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [var.EKS-cluster-OIDC-Provider.arn]
      type        = "Federated"
    }
  }
  depends_on = [var.EKS-cluster-OIDC-Provider]
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  assume_role_policy = data.aws_iam_policy_document.aws_load_balancer_controller_assume_role_policy.json
  name               = "${var.EKS-cluster.name}-load-balancer-controller"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  policy = file("./ALBController_config/AWSLoadBalancerController.json")
  name   = "${var.EKS-cluster.name}-AWSLoadBalancerController"
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller_attach" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

output "aws_load_balancer_controller_role_arn" {
  value = aws_iam_role.aws_load_balancer_controller.arn
}