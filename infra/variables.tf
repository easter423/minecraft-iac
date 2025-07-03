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

variable "ssh_public_keys" {
  description = "SSH 공개 키 목록"
  type        = string
  default = <<EOT
    ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINzp6ZVMEbAVNXo8s7YLI9KkQ1LFqMLQzW1JjOAUvqnc minecraft-fabric
    angryapple1103:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCg8az7ILEKazAQq1Vd9XfAC1AxZLBSWIECxKuJtFGp6a4+0LfZoXGhZjqXk89PDLAw5j97R7y9kstW00Ho2vHxaDFpMNwdogECLPCfU1Np7wwz6uk3iEQ5YFgGU4DLd6xUVwyJS8co7VuEUn1MlWOr3VUfTHSQD7zLZ7aInTIaUZ7m7bhAwLE4ug8nCOQnB0qM0WKqr80DegiOZED3Er6GsIt6AScEd/TIKRaAcbFJ7lWggqLK5f9bFQnRgDMPlGjRx6H13W13qfCOKbsLB44CGSSFvHTHJOd3/vng6UExFAAX7nBj/J7VGSquI9h7bmUvD1Kfk0vwzf/XG9YhyRHd angryapple1103
    ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDaAMIP3k12/ZyJL5xNfVvJ2DKSE0Q9YmezkRxngH1p4 minecraft-fabric2
  EOT
}