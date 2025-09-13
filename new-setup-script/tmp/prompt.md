# Modifications to task_harden

Add the following modifications sequentially:

1. Inside the harden task, install security related packages from the list in the attached security-pkgs.txt and enable the required system systemd services using the list in the attached system-services.txt.

2. Modify the harden task so that it also performs the following tasks sequentially, right after installing the above packages and enabling those services:

Make sure the kernel parameters contain the following texts:
**lsm=landlock,lockdown,yama,integrity,apparmor,bpf audit=1**

```sh
sudo groupadd -r audit
sudo gpasswd -a ahsan audit
```

Then add the following line to the beginning of `/etc/audit/auditd.conf`

```sh
log_group = audit
```

Finally create a desktop launcher for user in `~/.config/autostart/apparmor-notify.desktop` with the following content:

```sh
[Desktop Entry]
Type=Application
Name=AppArmor Notify
Comment=Receive on screen notifications of AppArmor denials
TryExec=aa-notify
Exec=aa-notify -p -s 1 -w 60 -f /var/log/audit/audit.log
StartupNotify=false
NoDisplay=true
```

3. In the final task add the following lines to `/etc/fstab`:

```sh
proc /proc proc nosuid,nodev,noexec,hidepid=2,gid=proc 0 0
```

Then create the directory/file with `/etc/systemd/system/systemd-logind.service.d/hidepid.conf` and add the following to the file

```sh
[Service]
SupplementaryGroups=proc
```
