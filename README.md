# Secure PXE Network-Booted Linux/Ubuntu

This repository gives a tutorial on building a secure PXE-netboot Ubuntu/Linux access node cluster with OpenVPN. For such a cluster, all access nodes do not require harddisk, all are booted from network with the same NFS-shared root directory that is read-only and controlled from server side. Adding an access node does not require any OS installation, instead, it only requires connecting a harddiskless and UEFI-PXE-enabled PC to the cluster (for better security, add its MAC address to the allowed device list in `dnsmasq.conf` and create a new OpenVPN user using its IP address).

Security features (can be optionally removed):
- MAC addresses of the allowed devices are in `dnsmasq.conf`.
- For each approved device, an OpenVPN account is needed to connect to the main cluster.
- OpenVPN credentials are encrypted using openssl.
- The root folder is mounted over NFS as read-only and via VPN.
- All internal storage and external USB storage device drivers are removed from kernel (a copy is kept in the `./all-modules` folder), data infiltration/exfiltration is not possible even with root access.

Note: for git repo
- all usernames (including grub) are root, all passwords are abcd1234;
- there are 2 test users: user01 is a normal user, user02 is a restricted user that can do nothing except connecting to VNC
- if you want to allow restricted users to run more commands, soft-link them to /rbash-bin/


## A. Full Preparation of the entire repository (only for learning purposes)
- Copy out the Linux kernel file /boot/vmlinuz-\* and /boot/initrd.gz(.img) into /netboot/tftpboot/ and modify /netboot/tftpboot/grub/grub.cfg accordingly.
- Extract initrd (initial root directory) to /initrd-custom using `unmkinitramfs`, modify /initrd-custom/main/init, starting from mounting root directory.
- During early-stage boot, the system uses busybox for all shell commands. However, busybox-mount does not support NFS properly, so we need to copy nfsmount manually into the /usr/bin folder
- If OpenVPN is used, .ovpn credentials are compressed using `tar/gzip`, encrypted using openssl, stored in `/netboot/ovpn.enc`, and shared over NFS; you can do this by putting access node .ovpn profiles in the `./ovpn.dec/` folder and run `./encrypt-ovpn.sh`; you can add/remove/change OpenVPN configurations by cd into `./openvpn-ecc` and run `./openvpn-install.sh`. Then, you also need to copy `openvpn` and `openssl` binaries together with their dependency .so files into `initrd-custom`.
- Rebuild initrd, `./mkinitrd.sh initrd-custom tftpboot/initrd.gz && chmod -R 755 tftpboot/`
- Change grub password, run `grub-mkpasswd-pbkdf2`, paste the password hash into tftpboot/grub/grub.cfg , this defends against kernel option hack
- Although root directory is shared via NFS as read-only, /var and /home must be shared as read-write (or you cannot enter desktop environment), and same for /etc (if you need to allow users to change password, but will expose some vulnerability)
- Copy over `/lib/firmware` and `lib/modules` from Live image's squashfs (you need to find the squashfs image on the ISO and mount it) to `./nfs` root file-system. Usually, the firmwares/drivers for the Live system should be enough for running the PXE terminal.
Optional:
- delete `lib/modules/6.1.0-17-amd64/kernel/drivers/ata`, `lib/modules/6.1.0-17-amd64/kernel/drivers/scsi`, and `lib/modules/6.1.0-17-amd64/kernel/drivers/usb/storage` from both `./initrd-custom` and `./nfs` to prevent mounting local internal/external harddisks from the client terminal side, for better security.
- eCryptfs is no longer used because when the underlying encrypted data is changed by another access node, the decrypted files on this access node does not change correspondingly, thus, files are not synchronized across all access nodes

## B. How to Launch
0. make sure your network interface `eth0` is up and will be used for PXE network booting, or you need to modify `dnsmasq.conf`
1. Run dnsmasq.sh to launch DHCP with TFTP
2. Launch NFS to share root filesystem 
- /netboot/nfs hosts the root directory of the PXE access nodes
- To setup NFS: /etc/exports should contain the following line, an example is in ./etc/exports
```
/netboot/nfs/ro/ovpn.enc  *(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)
/netboot/nfs/ro/rootfs  20.8.0.*(ro,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)
/netboot/nfs/rw/var  20.8.0.*(rw,sync,no_wdelay,insecure_locks,no_root_squash,insecure,no_subtree_check)
```
- Then run `exportfs -a` and restart NFS kernel server service, `service nfs-kernel-server restart`

3. Start OpenVPN server service
By default, OpenVPN server looks at configurations in the `/etc/openvpn/server` folder, you can change it via `--cd` option, a sample `/etc/openvpn/server` folder is prepared in the `./etc/openvpn/server` folder.

4. If firewall is present, need to open the following ports:
- DHCP: 67/udp
- TFTP: 69/udp
- NFS: 2049/tcp
- OpenVPN: 1194
modify /etc/default/nfs-kernel-server, add `-p 2050` to RPCMOUNTDOPTS

5. VPN server need to forward port to specific IP:port and block all the rest:
```
iptables -P FORWARD DROP
iptables -t nat -A PREROUTING -i tun1 ! -d 20.8.0.1 -j DNAT --to-destination 20.8.0.250
iptables -t nat -A PREROUTING -i tun1 -d 20.8.0.1 -p tcp -m tcp --dport 10022 -j DNAT --to-destination xxx.xxx.xxx.xxx:xx
iptables -t nat -A POSTROUTING -s 20.8.0.0/24 -d xxx.xxx.xxx.xxx:xx -p tcp -m tcp --dport 22 -j SNAT --to-source yyy.yyy.yyy.yyy
iptables -A FORWARD -i tun1 ! -d 20.8.0.250 -j ACCEPT
iptables -A FORWARD -i wlan0 -o tun1 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

**: change tun1 to VPN tunnel<br/>
**: change wlan0 to secure cluster interface<br/>
**: xxx.xxx.xxx.xxx:xx is your inner cluster server IP, yyy.yyy.yyy.yyy is this machine's IP on inner cluster

[For security]<br/>
6. SSH server must not listen on VPN tunnel (20.8.0.\*) and access node interface (192.168.101.\*), change `ListenAddress 0.0.0.0` in `/etc/ssh/sshd\_config`

## Troubleshoot
- If GDM desktop environment failed ot launch, you see a black screen, then probably you have transferred the account over by copying `/etc/passwd` over. You cannot do this because all other packages' users id might be different. You have to manually transfer all actual users in `passwd`, `shadow`, and `groups` in `/etc`.
- If GDM desktop environment stucks at login screen with frozen mouse, keyboard, and shutdown button, you might be missing firmware/drivers. So try to copy `/lib/firmware` and `lib/modules` folder from live image into `./nfs/lib/`.
- If any particular user cannot enter desktop after successful login, but instead goes back to the login page, maybe that user's home folder has not been created yet.
- The access node cannot wake up after screen turn off after long period of inactivity. The access node must never enter sleep/suspend (you can disable by `systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target`) because the system will unmount and remount NFS due to network connectivity change. This is not possible because umounting NFS will lose root directory so the machine will hang.

