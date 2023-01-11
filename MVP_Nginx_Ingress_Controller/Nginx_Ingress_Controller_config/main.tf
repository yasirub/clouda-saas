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

resource "helm_release" "nginx-ingress-controller" {
  name       = "nginx-ingress-controller"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace = "kube-system"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set{
    name = "controller.image.allowPrivilegeEscalation"
    value = false
  }
  set{
    name= "controller.service.externalTrafficPolicy"
    value = "Local"
  }
  set{
    name = "controller.service.type"
    value = "NodePort"
  }
  set{
    name = "controller.service.httpPort.nodePort"
    value = 30080
  }
  set{
    name = "controller.publishService.enabled"
    value = true
  }
  set{
    name = "serviceAccount.create"
    value = true
  }
  set{
    name = "rbac.create"
    value = true
  }
  set{
    name = "controller.config.server-tokens"
    value = false
  }
  set{
    name = "controller.config.use-proxy-protocol"
    value = false
  }
  set{
    name = "controller.config.compute-full-forwarded-for"
    value = true
  }
  set{
    name = "controller.config.use-forwarded-headers"
    value = true
  }
  set{
    name = "controller.metrics.enabled"
    value = true
  }
}