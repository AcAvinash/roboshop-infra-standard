

variable "project_name" {
  default = "roboshop"
}

variable "env" {
  default = "dev"
}

variable "common_tags" {
  default = {
    Project = "roboshop"
    Component = "web"
    Environment = "DEV"
    Terraform = "true"
  }
}

variable "health_check" {

  default = {
    enabled = true
    healthy_threshold = 2 # consider as healthy if 2 health checks are success
    interval = 15
    matcher = "200-299"
    path = "/"
    port = 80
    protocol = "HTTP"
    timeout = 5
    unhealthy_threshold = 3
  }
}

variable "target_group_port" {
  default = 80
}


variable "launch_template_tags" {
  default = [
    {
      resource_type = "instance"

      tags = {
        Name = "web"
      }
    },

    {
      resource_type = "volume"

      tags = {
        Name = "web"
      }
    }

  ]
}

variable "autoscaling_tags" {
  default = [
    {
      key                 = "Name"
      value               = "web"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "Roboshop"
      propagate_at_launch = true
    }
  ]
}