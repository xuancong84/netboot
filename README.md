Network-Booted Linux Ubuntu

This repository gives a tutorial on building a PXE-netboot Ubuntu/Linux secure cluster with OpenVPN. For such a cluster, access nodes does not require harddisk, all are booted from network with the same NFS-shared root directory that is controlled from server side. Adding an access node only requires connecting a harddiskless and UEFI-PXE-enabled PC to the cluster (for better security, add its MAC address to the allowed device list in `dnsmasq.conf` and create a new OpenVPN user using its IP address).

Note: for git repo
- all usernames (including grub) are root, all passwords are abcd1234;
- there are 2 test users: user01 is a normal user, user02 is a restricted user that can do nothing except changing password and connecting to VNC
- if you want to allow restricted users to run more commands, soft-link them to /rbash-bin/

A. Preparation
- Copy out the Linux kernel file /boot/vmlinuz-\* and /boot/initrd.gz(.img) into /netboot/tftpboot/ and modify /netboot/tftpboot/grub/grub.cfg accordingly.
- Extract initrd to /initrd-custom using `unmkinitramfs`, modify /initrd-custom/main/init, starting from mounting root directory.
- During early-stage boot, the system uses busybox for all shell commands. However, busybox-mount does not support NFS properly, so we need to add nfsmount manually into the /usr/bin folder
- Rebuild initramfs, `mkinitrd.sh initrd-custom tftpboot/initrd.gz && chmod -R 755 tftpboot/`
Optional:
- The /home and /etc folder can be encrypted, /home is linked to /etc/home; however, `mount -t ecryptfs` requires /etc/passwd and /etc/mtab to work
- To create encrypted /etc folder, run `mount -t ecryptfs -o ecryptfs_key_bytes=32,ecryptfs_cipher=aes,ecryptfs_passthrough=n src-dir dst-dir` with the new password, note down the hashcode (e.g., b8ef029f66c1edab); to mount the encrypted folder, run `mount -t ecryptfs -o ecryptfs_key_bytes=32,ecryptfs_cipher=aes,ecryptfs_passthrough=n,ecryptfs_sig=b8ef029f66c1edab,ecryptfs_fnek_sig=b8ef029f66c1edab src-dir dst-dir`. Moreover, src-dir and dst-dir can be of the same name.


B. Launch
1. Run dnsmasq.sh to launch DHCP with TFTP
2. Launch NFS to share root filesystem 
- /netboot/nfs hosts the root directory of the PXE access nodes
- To setup NFS: /etc/exports should contain the following line
```
/netboot/nfs  *(rw,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)
```
- Then run `exportfs -a` and restart NFS kernel server service

3. Start OpenVPN server service

4. Firewall need to open the following ports:
- DHCP: 67
- TFTP: 69
- NFS: 111 & 2049 & 2050
- OpenVPN: 1194
modify /etc/default/nfs-kernel-server, add `-p 2050` to RPCMOUNTDOPTS

5. VPN server need to forward port to specific IP:port and block all the rest:
iptables -P FORWARD DROP
iptables -t nat -A PREROUTING -i tun1 ! -d 20.8.0.1 -j DNAT --to-destination 20.8.0.250
iptables -t nat -A PREROUTING -i tun1 -d 20.8.0.1 -p tcp -m tcp --dport 10022 -j DNAT --to-destination 18.139.106.135:22
iptables -t nat -A POSTROUTING -s 20.8.0.0/24 -d 18.139.106.135/32 -p tcp -m tcp --dport 22 -j SNAT --to-source 192.168.50.158
iptables -A FORWARD -i tun1 ! -d 20.8.0.250 -j ACCEPT
iptables -A FORWARD -i wlan0 -o tun1 -m state --state RELATED,ESTABLISHED -j ACCEPT

**: change tun1 to VPN tunnel
**: change wlan0 to secure cluster interface

[For security]
6. SSH server must not listen on VPN tunnel and access node interface, change /etc/ssh/sshd\_config
ListenAddress 0.0.0.0


