provider "aws" {
    region = "eu-west-3"  
}

output "alb_dns_name" {
  value = aws_lb.web.dns_name
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.web_data.name
}