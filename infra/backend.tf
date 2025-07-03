# infra/backend.tf
terraform {
  backend "gcs" {
    bucket      = var.storage_bucket_name  # GCS 버킷 이름
    prefix      = "fabric-server"
    credentials = var.credentials_file_path   # 서비스 계정 JSON
  }
}
