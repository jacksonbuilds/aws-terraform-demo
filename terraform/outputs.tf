output "api_endpoint" {
  value = "${aws_api_gateway_deployment.deployment.invoke_url}${aws_api_gateway_resource.items_resource.path}"
}

output "s3_bucket_name" {
  value = aws_s3_bucket.static_assets.bucket
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.items_table.name
}