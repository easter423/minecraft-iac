# State 저장용 GCS 버킷 – 첫 적용 시 자동 생성
resource "google_storage_bucket" "tf_state" {
  name     = var.storage_bucket_name      # 예: "tofu-state-${var.project_id}"
  location = var.region
  versioning {
    enabled = true                     # state 버전 관리
  }
  uniform_bucket_level_access = true
  lifecycle_rule {
    action { type = "Delete" }
    condition { age = 365 }            # 1년 지난 객체 자동 삭제(선택)
  }
}