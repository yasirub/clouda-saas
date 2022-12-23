output "vpc-resource" {
    value = aws_vpc.clouda-commerce
}

output "subnet-ids" {
  value = [aws_subnet.clcom-private-1.id,aws_subnet.clcom-private-2.id]
}