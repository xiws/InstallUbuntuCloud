# 打包规范
genisoimage -output cloud-init.iso -volid cidata -joliet -rock cloud-init/

# 移动文件到var/lib/libvirt/images 其他文件夹可能没有权限
cp ubuntu-22.10-server-cloudimg-amd64.img /var/lib/libvirt/images
cp cloud-init.iso /var/lib/libvirt/images

# 安装虚拟机
virt-install --name=nodeOnde \
--vcpus=4 --memory=4048 \
--disk path=/var/lib/libvirt/images/ubuntu-22.10-server-cloudimg-amd64.img,size=10 \
--disk path=/var/lib/libvirt/images/cloud-init.iso,device=cdrom \
--os-variant=ubuntu22.04 \
--import --network bridge=virbr0,model=virtio \
--graphics none --console pty,target_type=serial