output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.app_repo.repository_url
}

output "dev_instance_public_ip" {
  description = "Public IP of Dev EC2 instance"
  value       = aws_instance.dev_ec2.public_ip
}

output "prod_instance_public_ip" {
  description = "Public IP of Prod EC2 instance"
  value       = aws_instance.prod_ec2.public_ip
}

output "dev_instance_id" {
  description = "Instance ID of Dev EC2"
  value       = aws_instance.dev_ec2.id
}

output "prod_instance_id" {
  description = "Instance ID of Prod EC2"
  value       = aws_instance.prod_ec2.id
}
