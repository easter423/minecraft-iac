# Minecraft Fabric 서버 자동화 v1.0.0

이 저장소는 Google Cloud Platform(GCP)에서 Minecraft Fabric 서버를 손쉽게 구축하기 위한 인프라 코드 모음(IaC)입니다. 
[**OpenTofu**](https://opentofu.org/)를 사용해 인스턴스와 스토리지를 만들고, [**Ansible**](https://docs.ansible.com/)로 서버를 설정합니다.

## 1. 환경 준비

### Windows
1. PowerShell을 관리자 권한으로 열어 다음 스크립트를 실행합니다.
   ```powershell
   ./bootstrap/windows/install-wsl.ps1
   ```
   Ubuntu 24.04 배포판 설치까지 완료되면 새 터미널에서 이후 과정을 진행합니다.

### Linux/WSL
1. 저장소를 클론한 뒤 스크립트를 실행합니다.
   ```bash
   cd ~/minecraft-iac
   sudo bash ./bootstrap/linux/bootstrap.sh
   ```
   이 스크립트는 OpenTofu, gcloud, Ansible 등 필수 도구를 설치합니다.
2. 안내에 따라 다음 명령을 수동으로 실행해 gcloud를 초기화합니다.
   ```bash
   gcloud init --no-launch-browser
   gcloud auth application-default login --no-launch-browser
   ```
3. 서버 접속용 SSH 키를 생성합니다.
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "minecraft-fabric"
   ```

## 2. 인프라 배포(OpenTofu)
1. 가상 환경을 활성화한 뒤 `infra` 디렉터리에서 작업합니다.
   ```bash
   cd ~/minecraft-iac/infra
   source ../.venv/bin/activate
   tofu init -upgrade
   tofu plan -out plan.out
   tofu apply plan.out
   ../scripts/update_inventory.sh
   ```
   `update_inventory.sh` 스크립트는 Terraform 출력에서 인스턴스 IP를 읽어 Ansible 인벤토리를 자동으로 작성합니다.
   기본 변수 값은 `infra/variables.tf`에서 확인할 수 있으며 필요에 따라 수정합니다.

## 3. 서버 설정(Ansible)
1. 인스턴스 생성 후 `ansible` 디렉터리에서 플레이북을 실행합니다.
   ```bash
   cd ~/minecraft-iac/ansible
   source ../.venv/bin/activate
   ansible-playbook -i inventory.ini site.yml
   ```
   상태 확인만 하려면 다음을 실행합니다.
   ```bash
   ansible-playbook -i inventory.ini status.yml
   ```
   인벤토리 파일에는 대상 서버의 IP와 SSH 정보가 들어 있습니다.

## 4. 추가 정보
- 모드 목록과 서버 속성은 `ansible/vars` 하위 파일에서 관리합니다.
- 서버 메모리 크기는 `ansible/vars/server_properties.yml`의 `server_xms`, `server_xmx` 변수로 조정할 수 있습니다.
- 자세한 과정은 [Notion 문서](https://www.notion.so/MC-2241afe72e6980da8b2ac86e0bcf270e)를 참고하실 수 있습니다.

## 5. 모드 관리 스크립트
`scripts/manage_mods.py`는 [Modrinth](https://modrinth.com) API를 이용해 모드 정보를 조회하고 `ansible/vars/mods.yml`을 자동으로 갱신합니다.

### 사용 예시
```bash
source .venv/bin/activate
python scripts/manage_mods.py add fabric-api --mc-version 1.21.5
python scripts/manage_mods.py list-mods
```

## 6. 변수 파일 안내
OpenTofu나 Ansible을 실행하기 전에 필요한 주요 변수는 다음 파일에서 관리합니다. 값을 수정해 원하는 설정으로 조정할 수 있습니다.

- `infra/variables.tf` – 프로젝트 ID, 리전, 인스턴스 유형 등 인프라 전반 설정
- `ansible/vars/versions.yml` – 설치에 필요한 모드 로더 및 패키지 버전 지정
- `ansible/vars/server_properties.yml` – `server_xms`, `server_xmx`와 `minecraft_server_properties` 목록 관리
- `ansible/vars/world_sync.yml` – 월드 동기화 방식 및 경로 설정

예를 들어 `infra/variables.tf`에서 `instance_type` 값을 변경하면 생성되는 VM의 사양이 달라집니다. `ansible/vars/server_properties.yml`에서 `server_xmx` 값을 수정하면 서버의 최대 메모리를 조정할 수 있습니다.


