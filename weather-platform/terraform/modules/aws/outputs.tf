output "eks_cluster_name" {
  value       = aws_eks_cluster.main.name
  description = "EKS Cluster Name"
}

output "eks_cluster_endpoint" {
  value       = aws_eks_cluster.main.endpoint
  description = "EKS Cluster API Endpoint"
}

output "eks_cluster_certificate_authority_data" {
  value       = aws_eks_cluster.main.certificate_authority[0].data
  description = "EKS Cluster CA certificate data"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.main.repository_url
  description = "ECR Repository URL"
}

output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private Subnet IDs"
}
