#!/usr/bin/env bash
iso_name="IlluminateBR-OS"
iso_label="ILLUMINATE_$(date +%Y%m)"
iso_publisher="IlluminateBR Project <https://github.com/anderson10chaves/IlluminateBR-OS>"
iso_application="IlluminateBR OS Live/Installer"
iso_version="$(date +%Y.%m.%d)"
install_dir="illuminate"
buildmodes=('iso')
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
file_permissions=(
  ["/etc/shadow"]="0:0:400"
  ["/usr/local/bin/post-install.sh"]="0:0:755"
)
