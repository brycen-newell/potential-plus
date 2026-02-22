[webservers]
%{ for server in webservers ~}
${server.private_ip} ansible_user=ec2-user
%{ endfor ~}

[monitoring_servers]
%{ for server in monitoring_servers ~}
${server.private_ip} ansible_user=ec2-user
%{ endfor ~}
