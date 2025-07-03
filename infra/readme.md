cd ~/minecraft-iac
sudo bash ./bootstrap/linux/bootstrap.sh

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
또는 ansible-playbook -i inventory.ini -vv site.yml