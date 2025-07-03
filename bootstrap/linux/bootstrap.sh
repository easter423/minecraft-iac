#!/usr/bin/env bash
# 위치 : repo 최상단(minecraft-iac/) 에서 실행
set -e

# ----------------------------------------------------------------------
# ⛏️ apt 미러 서버를 kakao로 대체 (DNS 불안정 대응)
#    - /etc/apt/sources.list.d/ubuntu.sources 에서 archive.ubuntu.com → mirror.kakao.com
# ----------------------------------------------------------------------
sudo sed -i 's|http://archive.ubuntu.com/ubuntu/|http://mirror.kakao.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources
sudo sed -i 's|http://security.ubuntu.com/ubuntu/|http://mirror.kakao.com/ubuntu/|g' /etc/apt/sources.list.d/ubuntu.sources
echo "🔄 Checking for apt updates..."
sudo apt-get update -y
UPGRADABLE_COUNT=$(apt list --upgradable 2>/dev/null | grep -v Listing | wc -l || echo 0)
if (( UPGRADABLE_COUNT > 0 )); then
  echo "⬆️  $UPGRADABLE_COUNT packages upgradable – upgrading now."
  sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold"
else
  echo "✅ No upgrades available."
fi
REQUIRED=("apt-transport-https" "ca-certificates" "gnupg" "curl" "ansible" "openjdk-21-jdk-headless" "jq")
TO_INSTALL=()
for pkg in "${REQUIRED[@]}"; do
  if ! dpkg-query -Wf'${db:Status-abbrev}' "$pkg" 2>/dev/null | grep -q '^i'; then
    TO_INSTALL+=("$pkg")
  fi
done
if (( ${#TO_INSTALL[@]} > 0 )); then
  echo "📦 Installing required tools: ${TO_INSTALL[*]}"
  sudo apt-get install -y "${TO_INSTALL[@]}"
else
  echo "✅ All required tools already installed."
fi
sudo apt-get autoremove -y && sudo apt-get clean
echo "🧹 System update & cleanup finished."

apt install -y python3.12-venv

# 1. Python 가상환경 생성
python3 -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
pip install -r bootstrap/linux/requirements.txt


# 2. 시스템 패키지 설치
# OpenTofu CLI
PKG=tofu
KEY1=/etc/apt/keyrings/opentofu.gpg
KEY2=/etc/apt/keyrings/opentofu-repo.gpg
LIST=/etc/apt/sources.list.d/opentofu.list

if dpkg-query -Wf'${db:Status-abbrev}' "$PKG" 2>/dev/null | grep -q '^i'; then  # 설치 확인 :contentReference[oaicite:3]{index=3}
  echo "✅ $PKG already installed – skipping repository setup."
else
  sudo install -m 0755 -d /etc/apt/keyrings

  if [[ ! -s "$KEY1" ]]; then
    curl -fsSL https://get.opentofu.org/opentofu.gpg \
      | sudo tee "$KEY1" >/dev/null
  fi

  if [[ ! -s "$KEY2" ]]; then
    curl -fsSL https://packages.opentofu.org/opentofu/tofu/gpgkey \
      | sudo gpg --no-tty --batch --dearmor -o "$KEY2"
  fi

  sudo chmod a+r "$KEY1" "$KEY2"
  if [[ ! -f "$LIST" ]]; then
    echo "deb [signed-by=$KEY1,$KEY2] https://packages.opentofu.org/opentofu/tofu/any/ any main
  deb-src [signed-by=$KEY1,$KEY2] https://packages.opentofu.org/opentofu/tofu/any/ any main" \
      | sudo tee "$LIST" >/dev/null
    sudo chmod a+r "$LIST"
  fi

  sudo apt-get update -y
  sudo apt-get install -y "$PKG"
fi

# Google Cloud CLI (gcloud)
KEYRING=/usr/share/keyrings/cloud.google.gpg
LIST=/etc/apt/sources.list.d/google-cloud-sdk.list
PKG=google-cloud-cli

if dpkg-query -Wf'${db:Status-abbrev}' "$PKG" 2>/dev/null | grep -q '^i'; then
  echo "✅ $PKG already installed — skipping gcloud setup."
else
  sudo mkdir -p "$(dirname "$KEYRING")"
  curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
    | sudo gpg --yes --dearmor -o "$KEYRING"
  if ! grep -qxF "deb [signed-by=$KEYRING] https://packages.cloud.google.com/apt cloud-sdk main" "$LIST" 2>/dev/null; then
    echo "deb [signed-by=$KEYRING] https://packages.cloud.google.com/apt cloud-sdk main" \
      | sudo tee -a "$LIST" >/dev/null
  fi
  sudo apt-get update -y && sudo apt-get install -y "$PKG"
  sudo apt-get autoremove -y && sudo apt-get clean
fi

# ----------------------------------------------------------------------
# 3. Ansible로 로컬 필수 패키지(self‑heal)
#    - curl / ca-certificates / gnupg 설치 여부 확인 & 보정
# ----------------------------------------------------------------------
# ansible-playbook -i "localhost," -c local \
#   -e "ansible_python_interpreter=$(which python)" \
#   bootstrap/linux/bootstrap.yml

# 4. gcloud 초기 설정(대화식)
# ── gcloud init 재실행 방지 로직 ─────────────────────────────
ACTIVE=$(gcloud config configurations list --format='value(is_active)' | grep '^True$' || true)
PROJECT_ID=$(gcloud config get-value project 2>/dev/null || echo "")

if [[ "$ACTIVE" != "True" || -z "$PROJECT_ID" ]]; then
  echo -e "\n🛠️ gcloud init 진행 — 프로젝트 ID, 리전을 지정하세요."
  gcloud init --no-launch-browser
  gcloud auth application-default login --no-launch-browser
else
  echo "✅ gcloud 이미 초기화됨 (project=$PROJECT_ID)"
fi

echo -e "\n✅ 로컬 툴체인 설치가 끝났습니다. infra/ 및 ansible/ 디렉터리로 이동해 다음 단계를 진행하세요."