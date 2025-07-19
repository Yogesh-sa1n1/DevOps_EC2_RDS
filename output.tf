output "ec2_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.mysql.address
}
