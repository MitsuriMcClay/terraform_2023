#----------------------------------------
# VPCの作成
#----------------------------------------
resource "aws_vpc" "terraform_sample_mitsuri" {

  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = var.tags
  }
}

#----------------------------------------
# Subnetの作成
#----------------------------------------
resource "aws_subnet" "terraform_sample_mitsuri" {
  count             = 2
  cidr_block        = var.subnet_cidr_block[count.index]
  availability_zone = var.availability_zone[count.index]
  vpc_id            = aws_vpc.terraform_sample_mitsuri.id

  tags = {
    Name = "${format("subnet%02d", count.index + 1)}"
  }
}

#----------------------------------------
# InternetGatewayの作成
#----------------------------------------
resource "aws_internet_gateway" "terraform_sample_mitsuri" {
  vpc_id = aws_vpc.terraform_sample_mitsuri.id
  tags = {
    Name = "terraform_sample_mitsuri"
  }
}

#----------------------------------------
# RouteTableの作成
#----------------------------------------
resource "aws_route_table" "terraform_sample_mitsuri" {
  vpc_id = aws_vpc.terraform_sample_mitsuri.id
  tags = {
    Name = "terraform_sample_mitsuri"
  }
}

#----------------------------------------
# 作成したRouteTableのルート設定
#----------------------------------------
resource "aws_route" "terraform_sample_mitsuri" {
  route_table_id         = aws_route_table.terraform_sample_mitsuri.id
  gateway_id             = aws_internet_gateway.terraform_sample_mitsuri.id
  destination_cidr_block = "0.0.0.0/0"
}

#----------------------------------------
# Subnetの関連付け
#----------------------------------------
resource "aws_route_table_association" "terraform_sample_mitsuri" {
  count          = 2
  route_table_id = aws_route_table.terraform_sample_mitsuri.id
  subnet_id      = aws_subnet.terraform_sample_mitsuri[count.index].id
}

#----------------------------------------
# Security Groupの作成
#----------------------------------------
resource "aws_security_group" "terraform_sample_mitsuri" {
  vpc_id = aws_vpc.terraform_sample_mitsuri.id
  tags = {
    Name = "terraform_sample_mitsuri"
  }

  # インバウンドルール
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # アウトバウンドルール
  egress {
    from_port = 0
    to_port   = 0
    #protocol    = "-1" は "all" と同等
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#----------------------------------------
# ALBの作成
#----------------------------------------
resource "aws_lb" "terraform_sample_mitsuri" {
  load_balancer_type = "application"
  tags = {
    Name = "terraform_sample_mitsuri"
  }

  security_groups = [aws_security_group.terraform_sample_mitsuri.id]
  subnets         = aws_subnet.terraform_sample_mitsuri[*].id

  access_logs {
    bucket  = aws_s3_bucket.terraform_sample_mitsuri.id
    prefix  = "PREFIX"
    enabled = true
  }

}
#----------------------------------------
# Target Groupの作成
#----------------------------------------
resource "aws_alb_target_group" "terraform_sample_mitsuri" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_sample_mitsuri.id

  tags = {
    Name = "terraform_sample_mitsuri"
  }

  health_check {
    interval            = 30
    path                = "/"
    port                = 80
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
    matcher             = 200
  }
}

#----------------------------------------
# Target Groupとインスタンスの紐付け
#----------------------------------------
resource "aws_alb_target_group_attachment" "terraform_sample_mitsuri" {
  count            = 2
  target_group_arn = aws_alb_target_group.terraform_sample_mitsuri.arn
  target_id        = aws_instance.terraform_sample_mitsuri[count.index].id
  port             = 80
}

#----------------------------------------
# リスナー設定
#----------------------------------------
resource "aws_lb_listener" "terraform_sample_mitsuri" {
  load_balancer_arn = aws_lb.terraform_sample_mitsuri.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.terraform_sample_mitsuri.arn
  }
}

#----------------------------------------
# S3バケットの作成
#----------------------------------------
resource "aws_s3_bucket" "terraform_sample_mitsuri" {
  force_destroy = true
  bucket        = "terraform-sample-mitsuri-bucket"

  tags = {
    Name = "terraform_sample_mitsuri"
  }
}

#----------------------------------------
# S3バケットに対するIAMポリシー作成
#----------------------------------------
data "aws_iam_policy_document" "alb_log" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.terraform_sample_mitsuri.id}/*"]

    principals {
      type = "AWS"
      # Principalには、terraform_userアカウントIDを記載する
      identifiers = ["582318560864"]
    }
  }
}

#----------------------------------------
# S3バケットポリシー作成
#----------------------------------------
resource "aws_s3_bucket_policy" "alb_log" {
  bucket = aws_s3_bucket.terraform_sample_mitsuri.id
  policy = data.aws_iam_policy_document.alb_log.json
}

#----------------------------------------
# Route53 Zone情報登録
#----------------------------------------
resource "aws_route53_zone" "mcclaymitsuri" {
  name = "mcclaymitsuri.net"
  tags = {
    Name = var.tags
  }
}

#----------------------------------------
# Route53の構築
#----------------------------------------
# レコードを作成
resource "aws_route53_record" "mcclaymitsuri" {
  zone_id = "Z06408092SLZYAWQ0QSHX"
  name    = "mcclaymitsuri.net"
  type    = "A"

  alias {
    name                   = aws_lb.terraform_sample_mitsuri.dns_name
    zone_id                = aws_lb.terraform_sample_mitsuri.zone_id
    evaluate_target_health = true
  }
}