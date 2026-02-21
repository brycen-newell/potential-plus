output "instance_details" {
  description = "A map of all created instances, keyed by their name tag, with their details."
  sensitive   = true

  value = {
    for instance in concat(aws_instance.web_server_dev, aws_instance.monitoring_server, [aws_instance.bastion]) :
    
    instance.tags.Name => {
      public_ip   = instance.public_ip
      instance_id = instance.id
      private_ip  = instance.private_ip
    }
  }
}
