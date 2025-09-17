resource "aws_lb_target_group" "catalogue" {
  name     = "${var.project_name}-${var.common_tags.Component}"
  port     = 8080 # on which port application is running
  protocol = "HTTP"
  vpc_id   = data.aws_ssm_parameter.vpc_id.value
  health_check {
    enabled = true
    healthy_threshold = 2 # consider as healthy if 2 health checks are success
    interval = 15  # time between health checks
    matcher = "200-299" # consider as healthy if response code is between 200 to 299
    path = "/health" # health check endpoint
    port = 8080  # on which port health check will be performed 
    protocol = "HTTP"
    timeout = 5 # time to wait for a response
    unhealthy_threshold = 3 # consider as unhealthy if 3 health checks are failed
  }
}

resource "aws_launch_template" "catalogue" {
  name = "${var.project_name}-${var.common_tags.Component}"

  image_id = data.aws_ami.devops_ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"

  vpc_security_group_ids = [data.aws_ssm_parameter.catalogue_sg_id.value]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "Catalogue"
    }
  }
  user_data = filebase64("${path.module}/catalogue.sh")
}

resource "aws_autoscaling_group" "catalogue" {
  name                      = "${var.project_name}-${var.common_tags.Component}"
  # max size indicates maximum number of instances that can be launched
  max_size                  = 5
  min_size                  = 2
  # time given to instance to come up and register with load balancer before starting health checks
  health_check_grace_period = 300
  # Elb indicates that the health check of the instances will be done by the load balancer
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.catalogue.arn]
  launch_template {
    id      = aws_launch_template.catalogue.id
    version = "$Latest"
  }
  vpc_zone_identifier       = split(",",data.aws_ssm_parameter.private_subnet_ids.value)

  tag {
    key                 = "Name"
    value               = "Catalogue"
    propagate_at_launch = true
  }

  timeouts {
    delete = "15m"
  }
}

# on what policy the auto scaling will happen like cpu utilization based
resource "aws_autoscaling_policy" "catalogue" {
  autoscaling_group_name = aws_autoscaling_group.catalogue.name
  name                   = "cpu"
  # policy type can be TargetTrackingScaling, StepScaling, SimpleScaling
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 50.0
  }
}

resource "aws_lb_listener_rule" "catalogue" {
  listener_arn = data.aws_ssm_parameter.app_alb_listener_arn.value
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.catalogue.arn
  }

  condition {
    host_header {
      values = ["catalogue.app.joindevops.online"]
    }
  }
}