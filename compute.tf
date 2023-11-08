resource "aws_instance" "academy_instance1" {
    ami = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.securitygrp1.id]
    key_name = "pgpcc-key1"
    subnet_id = data.aws_subnet.subnet_us-east-1a.id
    user_data = <<-EOF
              #!/bin/bash
              echo "Web server 1 " > index.html
              EOF
    
    tags = {
        name = "httpserver1"
    }
  
}

resource "aws_instance" "academy_instance2" {
    ami = var.ami
    instance_type = var.instance_type
    security_groups = [aws_security_group.securitygrp1.id]
    key_name = "pgpcc-key1"
    subnet_id = data.aws_subnet.subnet_us-east-1b.id
    user_data = <<-EOF
              #!/bin/bash
              echo "Web server 2 " > index.html
              EOF
    
    tags = {
        name = "httpserver2"
    }
  
}



resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.load_balancer.arn

  port = 80

  protocol = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}


resource "aws_lb_target_group" "academy_tg" {
  name     = "web-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc.id

  health_check {
    path                = "/health.html"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group_attachment" "academy_tg_attach1" {
  target_group_arn = aws_lb_target_group.academy_tg.arn
  target_id        = aws_instance.academy_instance1.id
  port             = 8080
}

resource "aws_lb_target_group_attachment" "academy_tg_attach2" {
  target_group_arn = aws_lb_target_group.academy_tg.arn
  target_id        = aws_instance.academy_instance2.id
  port             = 8080
}

resource "aws_lb_listener_rule" "instances" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.academy_tg.arn
  }
}


#resource "aws_security_group" "alb" {
#  name = "alb-security-group"
#}

resource "aws_security_group_rule" "allow_alb_http_inbound" {
  type              = "ingress"
  security_group_id = aws_security_group.securitygrp1.id

  from_port   = 80
  to_port     = 80
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

}

resource "aws_security_group_rule" "allow_alb_all_outbound" {
  type              = "egress"
  security_group_id = aws_security_group.securitygrp1.id

  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

}


resource "aws_lb" "load_balancer" {
  name               = "web-lb"
  load_balancer_type = "application"
  subnets            = [data.aws_subnet.subnet_us-east-1a.id, data.aws_subnet.subnet_us-east-1b.id]
  security_groups    = [aws_security_group.securitygrp1.id]

}

#Create the public EC2 instance
resource "aws_instance" "public_instance" {
  ami           = "ami-0e8a34246278c21e4"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name      = "pgpcc-key1"  # Replace with your key pair name

  user_data = <<-EOF
#!/bin/bash
yum update -y
yum install httpd -y
service httpd start
chkconfig httpd on
IP_ADDR=\$(curl http://169.254.169.254/latest/meta-data/public-ipv4)
echo "Instance in the public subnet with IP \$IP_ADDR" > /var/www/html/index.html
EOF
  
}

#Create the private EC2 instance
resource "aws_instance" "private_instance" {
  ami           = "ami-0e8a34246278c21e4"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name      = "pgpcc-key1"  # Replace with your key pair name
  
}