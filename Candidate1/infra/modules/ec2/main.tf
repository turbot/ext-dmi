# modules/ec2/main.tf

resource "aws_instance" "ec2_instance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name
  associate_public_ip_address = true

  tags = {
    Name = var.instance_name
  }

  # User data script to install AWS CLI, clone repo, and run script in dry-run mode
  user_data = <<-EOF
    #!/bin/bash
    # Update the instance
    sudo yum update -y

    # Install necessary tools
    sudo yum install -y git python3 unzip
    pip3 install boto3

    # Install the latest AWS CLI
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install

    # Clone the specified GitHub repository
    git clone https://github.com/agenerette/candidate1-ext-dmi

    # Navigate to the cloned repo directory
    cd ext-dmi

    # Run the Python script in dry-run mode and save the output to /root/script_output.log
    python3 list_and_tag_buckets.py --dry-run > /root/script_output.log 2>&1

    echo "Script executed and output saved to /root/script_output.log"
  EOF

  # Security group allowing SSH
  vpc_security_group_ids = [var.security_group_id]

}
