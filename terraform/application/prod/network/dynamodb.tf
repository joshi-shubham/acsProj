#tfsec:ignore:aws-dynamodb-table-customer-key
resource "aws_dynamodb_table" "dynamodb-terraform-state-lock-prod" {
  name           = module.globalvars.state_lock_table_prod
  hash_key       = "LockID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "LockID"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}