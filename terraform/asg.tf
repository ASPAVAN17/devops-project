resource "aws_launch_template" "devops_lt" {
  name_prefix   = "devops-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
iam_instance_profile {
  name = aws_iam_instance_profile.ec2_profile.name
}

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.ec2_sg.id]
  }

  user_data = base64encode(<<EOF
#!/bin/bash
yum update -y
yum install -y docker aws-cli
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 277541735635.dkr.ecr.us-east-1.amazonaws.com

docker pull 277541735635.dkr.ecr.us-east-1.amazonaws.com/devops-app:1.0

docker run -d -p 80:3000 277541735635.dkr.ecr.us-east-1.amazonaws.com/devops-app:1.0
EOF
)

}

resource "aws_autoscaling_group" "devops_asg" {
  desired_capacity     = 1
  max_size             = 3
  min_size             = 1

  vpc_zone_identifier = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  launch_template {
    id      = aws_launch_template.devops_lt.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.devops_tg.arn]

  health_check_type = "ELB"
}

