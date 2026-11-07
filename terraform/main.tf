terraform {
  backend "s3" {
    bucket       = "junyong-tfstate-0416-890988596463-ap-northeast-2-an"
    key          = "aws-autoscaling/terraform.tfstate"
    region       = "ap-northeast-2"
    use_lockfile = true
  }
}

# 리전은 서울
provider "aws" {
    region = "ap-northeast-2"
    }

variable "image_tag" {
  type    = string
  default = "latest"
}

# 최신 AMI 이미지를 조회
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# ALB용 보안그룹 생성 / 80번을 모든 ip에 허용
resource "aws_security_group" "alb"{
    name = "tf-alb-sg"

    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress{
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }    
}

# 서버 설계도 생성 (AMI, t3.micro, 키 페어, 보안그룹, User Data)
resource "aws_launch_template" "app"{
    name = "tf-autoscaling-template"

    instance_type = "t3.micro"
    image_id = data.aws_ami.al2023.id
    key_name = "autoscaling-key"
    vpc_security_group_ids = [aws_security_group.app.id]
    user_data = base64encode(<<-EOF
        #!/bin/bash
        dnf install -y docker
        systemctl enable --now docker
        docker run -d --restart always -p 5000:5000 junyong0416/flask-app:${var.image_tag}
    EOF
    )
}

# 서버용 보안 그룹(5000번 허용)
resource "aws_security_group" "app" {
    name = "tf-app-sg"

    ingress{
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress{
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}

# 기본 VPC 조회
data "aws_vpc" "default" {
    default = true
}

# 서버 명단 생성
resource "aws_lb_target_group" "app" {
    name = "tf-autoscaling-tg"
    port = 5000
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
    }
}


data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_lb" "app" {
    name = "tf-autoscaling-alb"
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

resource "aws_autoscaling_group" "app" {
  name = "tf-autoscaling-asg"
  min_size = 1
  max_size = 3
  desired_capacity = 1

  launch_template {
    id = aws_launch_template.app.id 
    version = aws_launch_template.app.latest_version
  }
  
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.app.arn]
  health_check_type = "ELB"
  health_check_grace_period = 300

  instance_refresh {
  strategy = "Rolling"
  preferences {
    min_healthy_percentage = 50
  }
}
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "tf-cpu-50"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.app.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50
  }
}