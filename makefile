# 定义变量
ISO_NAME = cloud-init.iso
IMG_NAME = ubuntu-24.04-server-cloudimg-amd64.img
IMG_BASE_PATH= /mnt/sdc/cloudServer/
#IMG_BASE_PATH= /mnt/test/
name = master
IMG_PATH = $(IMG_BASE_PATH)$(name)

# 下载 Ubuntu cloud img 文件
# https://cloud-images.ubuntu.com/releases/
#

.PHONY: installKvm
installKvm:
	sudo apt update && sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils cloud-utils genisoimage

.PHONY: resize
resize:
	qemu-img info $(IMG_NAME)
	qemu-img resize $(IMG_NAME) 20G

.PHONY: all iso move install clean

# 生成 cloud-init ISO
iso:
	rm -rf $(ISO_NAME)
	mkdir -p cloud-init/
	cp cloud-init-config/* cloud-init/
	sudo sed -i "s|NodeName|$(name)|g" cloud-init/user-data
	genisoimage -output $(ISO_NAME) -volid cidata -joliet -rock cloud-init/
	rm -rf cloud-init

# 移动文件
move: iso
	mkdir -p $(IMG_PATH)
	cp $(IMG_NAME) $(IMG_PATH)/
	cp $(ISO_NAME) $(IMG_PATH)/

# 安装虚拟机
install: iso move
	virt-install --name=$(name) \
		--vcpus=4 --ram=4048 \
		--disk path=$(IMG_PATH)/$(IMG_NAME),size=20 \
		--disk path=$(IMG_PATH)/$(ISO_NAME),device=cdrom \
		--os-variant=ubuntu24.04 \
		--import --network bridge=br0,model=virtio \
		--graphics none --console pty,target_type=serial

# 清理生成的 ISO 文件
clean:
	rm -f $(ISO_NAME)

.PHONY: shutdown
shutdown: 
	sudo virsh shutdown $(name)

.PHONY: del
del: 
	sudo virsh destroy $(name)
	sudo virsh undefine --remove-all-storage $(name)

.PHONY: cmd
cmd:
	ssh root@192.168.5.11 hostnamectl set-hostname $(name)
