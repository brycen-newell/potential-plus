[webservers]
%{ for server in webservers ~}
${server.public_ip} ansible_user=ec2-user
%{ endfor ~}