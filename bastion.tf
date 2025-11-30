# Launch Template del Bastion
resource "aws_launch_template" "bastion" {
  name_prefix   = "bastion-"
  image_id      = "ami-0c02fb55956c7d316"  # Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "bluegreen-key"

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo yum update -y
              EOF
            )
}

# Auto Scaling Group del Bastion (solo 1 instancia)
resource "aws_autoscaling_group" "bastion_asg" {
  launch_template {
    id      = aws_launch_template.bastion.id
    version = "$Latest"
  }

  vpc_zone_identifier = [aws_subnet.public.id]

  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  tag {
    key                 = "Name"
    value               = "Bastion"
    propagate_at_launch = true
  }
}

