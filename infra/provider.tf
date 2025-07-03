# infra/provider.tf
provider "google" {
  project = var.project_id    # 필수
  region  = var.region        # 선택(권장)
  zone    = var.zone          # 선택
}
