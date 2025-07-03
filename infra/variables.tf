variable "project_id" {
  description = "GCP 프로젝트 ID"
  type        = string
  default     = "quixotic-alloy-464416-d9"
}

variable "region" {
  description = "GCP 리전"
  type        = string
  default     = "asia-northeast3"
}

variable "zone" {
  description = "GCP 존"
  type        = string
  default     = "asia-northeast3-c"
}

variable "storage_bucket_name" {
  description = "GCS 버킷 이름 (Terraform state 저장용)"
  type        = string
  default     = "tofu-state-quixotic-alloy-464416-d9"
}

variable "credentials_file_path" {
  description = "GCP 서비스 계정 키 파일 경로"
  type        = string
  default     = "~/.config/gcloud/application_default_credentials.json"
}