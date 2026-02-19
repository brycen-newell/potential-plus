output "dev_server_ip" {
  value       = aws_instance.web_server_dev-${count.index}.public_ip
  description = "The public IP address of the dev web server."
}

output "dev_server_id" {
  value       = aws_instance.web_server_dev-${count.index}.id
  description = "The ID of the dev web server instance."
}
