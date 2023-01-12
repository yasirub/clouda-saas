terraform {
  required_providers{
    aws ={
        source = "hashicorp/aws"
        version = ">=2.7.0"
        configuration_aliases = [ aws ]
    }
  }
}

data aws_region current {}
resource "null_resource" "kubectl-update" {
  depends_on = [var.EKS-cluster]

  triggers = {
    endpoint = var.EKS-cluster.endpoint
    cluster = var.EKS-cluster.id
    arn = var.EKS-cluster.arn
  }

  provisioner "local-exec" {
    command = <<EOH
aws eks update-kubeconfig --name ${var.EKS-cluster.name} --region ${data.aws_region.current.name}
EOH
  }

  provisioner "local-exec" {
    when = destroy
    command = <<EOH
kubectl config delete-context ${self.triggers.arn} && kubectl config delete-cluster ${self.triggers.arn} && kubectl config delete-user ${self.triggers.arn}
EOH
  }

  lifecycle {
    ignore_changes = [triggers]
  }
}