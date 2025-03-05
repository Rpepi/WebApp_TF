# Launch Template pour l'ASG
resource "aws_launch_template" "web" {
  name_prefix   = "web-template"
  image_id      = "ami-096206422ae32b993"
  instance_type = "t2.micro"
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.web_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              set -e
              yum update -y
              amazon-linux-extras install nginx1 -y  # Installe Nginx sur Amazon Linux 2
              systemctl start nginx
              systemctl enable nginx
              echo "<h1>Site Web OK</h1><p>Servi par $(hostname)</p>" > /usr/share/nginx/html/index.html
              systemctl status nginx > /var/log/nginx-status.log 2>&1
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  desired_capacity     = 2
  min_size             = 2
  max_size             = 4
  vpc_zone_identifier  = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  target_group_arns    = [aws_lb_target_group.web.arn]
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = "web-instance"
    propagate_at_launch = true
  }
}

# Politique de scaling basée sur CPU
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "cpu-based-scaling"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.web.name
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0 # Cible : 50% d'utilisation CPU moyenne
  }
}

# Application Load Balancer
resource "aws_lb" "web" {
  name               = "web-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  tags = {
    Name = "web-alb"
  }
}

# Target Group pour l'ALB
resource "aws_lb_target_group" "web" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main-vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener pour l'ALB
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.web.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}