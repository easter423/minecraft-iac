cd ~/minecraft-iac
sudo bash ./bootstrap/linux/bootstrap.sh

The bootstrap script installs local packages only.
Run the following commands manually on a machine
with access to Google Cloud endpoints:
  gcloud init --no-launch-browser
  gcloud auth application-default login --no-launch-browser

ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -C "minecraft-fabric"

=====

cd ~/minecraft-iac/infra
source ../.venv/bin/activate

tofu init -upgrade

tofu plan -out plan.out

tofu apply plan.out

=====

cd ~/minecraft-iac/ansible
source ../.venv/bin/activate
ansible-playbook -i inventory.ini site.yml
or
ansible-playbook -i inventory.ini -vv site.yml

=====
https://www.notion.so/MC-2241afe72e6980da8b2ac86e0bcf270e