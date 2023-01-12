terraform {
  required_providers{
    aws ={
        source = "hashicorp/aws"
        version = ">=2.7.0"
        configuration_aliases = [ aws ]
    }
  }
}

resource "aws_iam_role" "eks-fargate-profile" {
  name = "${var.EKS-cluster.name}-fargate-profile"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks-fargate-profile" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks-fargate-profile.name
}

resource "aws_eks_fargate_profile" "kube-system" {
  cluster_name           = var.EKS-cluster.name
  fargate_profile_name   = "kube-system"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = var.subnet_ids
  selector {
    namespace = "kube-system"
  }
}

resource "aws_eks_fargate_profile" "blue-green" {
  cluster_name           = var.EKS-cluster.name
  fargate_profile_name   = "blue-green"
  pod_execution_role_arn = aws_iam_role.eks-fargate-profile.arn

  # These subnets must have the following resource tag: 
  # kubernetes.io/cluster/<CLUSTER_NAME>.
  subnet_ids = var.subnet_ids
  selector {
    namespace = "blue-green"
  }
}

data "aws_eks_cluster_auth" "eks" {
  name = var.EKS-cluster.id
}

resource "null_resource" "k8s_patcher" {
  depends_on = [aws_eks_fargate_profile.kube-system]

  triggers = {
    endpoint = var.EKS-cluster.endpoint
    ca_crt   = base64decode(var.EKS-cluster.certificate_authority[0].data)
    token    = data.aws_eks_cluster_auth.eks.token
  }

  provisioner "local-exec" {
    command = <<EOH
cat >/tmp/ca-${var.EKS-cluster.name}.crt <<EOF
${base64decode(var.EKS-cluster.certificate_authority[0].data)}
EOF
kubectl \
  --server="${var.EKS-cluster.endpoint}" \
  --certificate_authority=/tmp/ca-${var.EKS-cluster.name}.crt \
  --token="${data.aws_eks_cluster_auth.eks.token}" \
  patch deployment coredns \
  -n kube-system --type json \
  -p='[{"op": "remove", "path": "/spec/template/metadata/annotations/eks.amazonaws.com~1compute-type"}]'
EOH
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}