output "uat_public_ip" {
  description = "UAT EC2 Instance Public IP"
  value       = aws_instance.uat_server.public_ip
}

output "prod_public_ip" {
  description = "Production EC2 Instance Public IP"
  value       = aws_instance.prod_server.public_ip
}

output "uat_instance_id" {
  description = "UAT EC2 Instance ID"
  value       = aws_instance.uat_server.id
}

output "prod_instance_id" {
  description = "Production EC2 Instance ID"
  value       = aws_instance.prod_server.id
}
