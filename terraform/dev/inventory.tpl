[webservers]
%{ for server in webservers ~}
${server.public_ip} ansible_user=ec2-user
%{ endfor ~}

[monitoring_servers]
%{ for server in monitoring_servers ~}
${server.public_ip} ansible_user=ec2-user
%{ endfor ~}