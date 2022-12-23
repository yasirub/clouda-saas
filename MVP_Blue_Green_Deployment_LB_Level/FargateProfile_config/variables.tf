variable "EKS-cluster" {
  description = "instancee of the eks cluster"
}

variable "subnet_ids"{
  type = list(string)
}
