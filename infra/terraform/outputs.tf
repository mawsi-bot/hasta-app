output "secrets_arn" { value = aws_secretsmanager_secret.app.arn }
output "api_lb_dns" { value = aws_lb.api.dns_name }
output "media_bucket" { value = aws_s3_bucket.media.bucket }
