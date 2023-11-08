#EC2 variable

variable "ami" {
    description = "Amazon machine image to use for ec2 instance"
    type = string
    default = "ami-00588af4e4d549f20"
}

variable "instance_type" {
    description = "ec2 instance type"
    type = string
    default = "t2.micro"
}

variable "aws_security_group" {
    description = "security group for compute instance"
    type = string
    default = ""
}
