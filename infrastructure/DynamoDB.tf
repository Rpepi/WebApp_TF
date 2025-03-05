# DynamoDB Table
resource "aws_dynamodb_table" "web_data" {
  name           = "WebAppData"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S" # String
  }

  tags = {
    Name = "webapp-data"
  }
}