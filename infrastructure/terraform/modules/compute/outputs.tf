output "instance_id" {
  description = "ID of the private backend EC2 instance."
  value       = aws_instance.backend.id
}

output "private_ip" {
  description = "Private IPv4 address of the backend instance."
  value       = aws_instance.backend.private_ip
}

output "public_ip" {
  description = "Public IPv4 address; expected to be empty."
  value       = aws_instance.backend.public_ip
}

output "availability_zone" {
  description = "Availability Zone containing the backend instance."
  value       = aws_instance.backend.availability_zone
}

output "iam_role_name" {
  description = "IAM role attached to the backend instance."
  value       = aws_iam_role.backend.name
}

output "instance_profile_name" {
  description = "IAM instance profile attached to the backend instance."
  value       = aws_iam_instance_profile.backend.name
}