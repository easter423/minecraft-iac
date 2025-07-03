# 이 코드는 Terraform 4.25.0 및 4.25.0과(와) 하위 호환되는 버전과 호환됩니다.
# 이 Terraform 코드를 검증하는 방법은 https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#format-and-validate-the-configuration을 참조하세요.

resource "google_compute_instance" "instance-20250702-074431" {
  boot_disk {
    auto_delete = true
    device_name = "instance-mc-server"

    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/ubuntu-2404-noble-amd64-v20250628"
      size  = 50
      type  = "pd-ssd"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src           = "vm_add-tf"
    goog-ops-agent-policy = "v2-x86-template-1-4-0"
  }

  machine_type = "n2-standard-2"

  metadata = {
    enable-osconfig = "TRUE"
    ssh-keys = <<EOT
      ubuntu:ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINzp6ZVMEbAVNXo8s7YLI9KkQ1LFqMLQzW1JjOAUvqnc minecraft-fabric
      angryapple1103:ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCg8az7ILEKazAQq1Vd9XfAC1AxZLBSWIECxKuJtFGp6a4+0LfZoXGhZjqXk89PDLAw5j97R7y9kstW00Ho2vHxaDFpMNwdogECLPCfU1Np7wwz6uk3iEQ5YFgGU4DLd6xUVwyJS8co7VuEUn1MlWOr3VUfTHSQD7zLZ7aInTIaUZ7m7bhAwLE4ug8nCOQnB0qM0WKqr80DegiOZED3Er6GsIt6AScEd/TIKRaAcbFJ7lWggqLK5f9bFQnRgDMPlGjRx6H13W13qfCOKbsLB44CGSSFvHTHJOd3/vng6UExFAAX7nBj/J7VGSquI9h7bmUvD1Kfk0vwzf/XG9YhyRHd angryapple1103
    EOT
  }

  name = "instance-20250702-074431"

  network_interface {
    access_config {
      nat_ip       = "34.22.89.91"
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/quixotic-alloy-464416-d9/regions/asia-northeast3/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  service_account {
    email  = "686021559130-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["http-server", "https-server"]
  zone = var.zone
}

module "ops_agent_policy" {
  source          = "github.com/terraform-google-modules/terraform-google-cloud-operations/modules/ops-agent-policy"
  project         = "quixotic-alloy-464416-d9"
  zone            = var.zone
  assignment_id   = "goog-ops-agent-v2-x86-template-1-4-0-asia-northeast3-c"
  agents_rule = {
    package_state = "installed"
    version = "latest"
  }
  instance_filter = {
    all = false
    inclusion_labels = [{
      labels = {
        goog-ops-agent-policy = "v2-x86-template-1-4-0"
      }
    }]
  }
}
