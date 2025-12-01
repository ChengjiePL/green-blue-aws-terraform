# -----------------------------
# Launch Template - Blue
# -----------------------------
resource "aws_launch_template" "blue" {
  name_prefix   = "blue-"
  image_id      = "ami-0c02fb55956c7d316"  # AMI válido Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "bluegreen-key"  # <- clave SSH

  # Security Group
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # User data para instalar Apache httpd

user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo yum update -y
    sudo yum install -y httpd
    HOSTNAME=$(hostname)
    cat << HEREDOC > /var/www/html/index.html
    <html>
    <head></head>
    <body bgcolor="#5DBCD2">
    <h1>Lab 3 - Blue/Green Deployment Use Case</h1>
    <h2>This is our Blue Environment</h2>
    <h3>Instance hostname: $HOSTNAME</h3>
    </body>
    </html>
    HEREDOC
    sudo systemctl enable httpd
    sudo systemctl start httpd
  EOF
  )

}

# -----------------------------
# Launch Template - Green
# -----------------------------
resource "aws_launch_template" "green" {
  name_prefix   = "green-"
  image_id      = "ami-0c02fb55956c7d316"  # AMI válido Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "bluegreen-key"  # <- clave SSH

  # Security Group
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  # User data para instalar Nginx
  user_data = base64encode(<<-EOF
              #!/bin/bash
              # Enable nginx from Amazon Linux Extras
              sudo yum update -y
              sudo amazon-linux-extras install nginx1 -y
              HOSTNAME=$(hostname)
              # Create custom index page
              sudo tee /usr/share/nginx/html/index.html > /dev/null << HTML
              <html>
              <head></head>
              <body bgcolor="#98FB98">
              <h1>Lab 3 - Blue/Green Deployment Use Case</h1>
              <h2>This is our Green Environment</h2>
              <h3>Instance hostname: $HOSTNAME</h3>
              </body>
              </html>
              HTML

              sudo systemctl enable nginx
              sudo systemctl start nginx
            EOF
          )
}



# Auto Scaling Group - Blue
resource "aws_autoscaling_group" "blue_asg" {
    launch_template {
          id      = aws_launch_template.blue.id
              version = "$Latest"
                }

                  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]

                    min_size         = 2
                      max_size         = 4
                        desired_capacity = 2

                          health_check_type         = "ELB"
                            health_check_grace_period = 300

                              target_group_arns = [aws_lb_target_group.blue.arn]

                                tag {
                                      key                 = "Name"
                                          value               = "Blue-ASG"
                                              propagate_at_launch = true
                                                }

                                                  # Instance Refresh — reemplaza instancias cuando cambia launch template
                                                    instance_refresh {
                                                          strategy = "Rolling"

                                                              preferences {
                                                                      min_healthy_percentage = 50
                                                                            instance_warmup        = 120
                                                                                }

                                                                                    triggers = ["launch_template"]
                                                                                      }
                                                                                    }

                                                                                    # Auto Scaling Group - Green
                                                                                    resource "aws_autoscaling_group" "green_asg" {
                                                                                        launch_template {
                                                                                              id      = aws_launch_template.green.id
                                                                                                  version = "$Latest"
                                                                                                    }

                                                                                                      vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]

                                                                                                        min_size         = 2
                                                                                                          max_size         = 4
                                                                                                            desired_capacity = 2

                                                                                                              health_check_type         = "ELB"
                                                                                                                health_check_grace_period = 300

                                                                                                                  target_group_arns = [aws_lb_target_group.green.arn]

                                                                                                                    tag {
                                                                                                                          key                 = "Name"
                                                                                                                              value               = "Green-ASG"
                                                                                                                                  propagate_at_launch = true
                                                                                                                                    }

                                                                                                                                      instance_refresh {
                                                                                                                                            strategy = "Rolling"

                                                                                                                                                preferences {
                                                                                                                                                        min_healthy_percentage = 50
                                                                                                                                                              instance_warmup        = 120
                                                                                                                                                                  }

                                                                                                                                                                      triggers = ["launch_template"]
                                                                                                                                                                        }
                                                                                                                                                                      }

