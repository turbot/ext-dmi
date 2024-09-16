# Outputs to view after apply
output "instance_id" {
  value = module.ec2_instance.instance_id
}

output "instance_public_ip" {
  value = module.ec2_instance.instance_public_ip
}

output "private_key_file" {
  value = local_file.private_key_pem.filename
}