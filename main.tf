provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

resource "aws_instance" "example" {
  ami = "ami-06380d26ad7176f2c"
  instance_type = "t3.micro"
}