locals {
    function_name = "${var.prefix}-${terraform.workspace}-lambda"
    lb_name = "${var.prefix}-${terraform.workspace}-lb"
    tg_name="${var.prefix}-${terraform.workspace}-tg"
    role_name = "${var.prefix}-${terraform.workspace}-lambda-role"
    sg_name="${var.prefix}-${terraform.workspace}-sg"
    
}


resource "aws_iam_role" "lambda_role" {
  name = local.role_name

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": "lambda"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.prefix}-send_message_policy-${terraform.workspace}"
  path        = "/"
  description = "sqs send policy"
  policy      = <<EOT
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": "sqs:SendMessage",
            "Resource": "${aws_sqs_queue.terraform_sqs.arn}"
        }
    ]
}
EOT
  tags = {
    Environment = "${terraform.workspace}"
  }
}


resource "aws_sqs_queue" "terraform_sqs" {
  name = "${var.prefix}-sqs-${terraform.workspace}"

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_cloudWatch_attach" {
    role = aws_iam_role.lambda_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"

}
data "archive_file" "function_code_zip" {
    type        = "zip"
    output_path = "function.zip"
    source {
        content = file("files/main.py")
        filename = "main.py"
    }
}




resource "aws_lb_target_group" "lambda-tg" {
  name        = local.tg_name
  target_type = "lambda"
}

resource "aws_lambda_permission" "alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda-tg.arn
}

resource "aws_lb_target_group_attachment" "main" {
  target_group_arn = aws_lb_target_group.lambda-tg.arn
  target_id        = aws_lambda_function.lambda_function.arn
  depends_on       = [ aws_lambda_permission.alb]
}



resource "aws_lambda_function" "lambda_function" {
    function_name   = local.function_name
    runtime         = "python3.9"
    handler         = "main.lambda_handler"
    role            = aws_iam_role.lambda_role.arn
    filename        = data.archive_file.function_code_zip.output_path
    source_code_hash = data.archive_file.function_code_zip.output_base64sha256

    environment {
        variables={
            MY_CONSTANT = "Kebab_lover"
            SQS_URL = aws_sqs_queue.terraform_sqs.url
        }
    }
    tags = {
        Environment = "${terraform.workspace}"
    }

}


resource "aws_security_group" "lambda_vpn-sg" {
  name        = local.sg_name
  description = "_V_P_N_"
  vpc_id      = "vpc-087b4e0167a2591a9"


  ingress = [
    {
      description      = "Access via VPN"
      from_port        = 80
      to_port          = 80
      protocol         = "TCP"
      cidr_blocks      = ["195.56.119.209/32"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    },
    
  ]

  tags = {
    Name = "V.P.N"
  }

  egress = [
    {
      description      = "anywere"
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = true
    },
  ]


}

resource "aws_lb" "lambda-example" {
  name               = local.lb_name
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-0ad4947b529ea6577","subnet-0056cb89cd49ab2e4"]
  security_groups    = [aws_security_group.lambda_vpn-sg.id]

  tags = {
    Environment = "${terraform.workspace}"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.lambda-example.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda-tg.arn
  }
}





output "tf_workspace"  {
    value = "${terraform.workspace}"
}
