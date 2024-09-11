output "subnet_1_id" {
  value = aws_subnet.subnet_1.id
}

output "subnet_2_id" {
  value = aws_subnet.subnet_2.id
}

output "ssh_sg_id" {
  value = aws_security_group.ssh_sg.id
}
