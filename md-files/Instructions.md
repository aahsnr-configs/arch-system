Write a python 3.13 script that does the following tasks sequentially:

The script must have the following features:

1. best practices for the python script itself
2. colored unicode support
3. best practices for running the commands
4. all prompts that are initiated by the individual commands must be shown by the python script

Most importantly sets up an arch linux system using arch-chroot.

Keep in mind that after entering arch chroot, all the commands are executed in chroot, even when executing 'su - $USER'. Also keep in mind that the script is being performed a different arch linux system and not a live USB. But this arch linux systen is in a different drive than the drive where this script installs into.

First make sure the script shows what is being performed at each step.

Check if the host user is in root. If not, enter the user into root by executing `sudo -i` and asking for sudo password. Then check if the user's host arch linux system has the following packages install: `btrfs-progs` and `lvm2`. If not, then install them Then execute the one block of commands below. Make sure the prompts that available via the following command is available by the python code as well.

```bash
cfdisk /dev/nvme0n1 &&
  mkfs.vfat -F 32 /dev/nvme0n1p1 &&
  cryptsetup --cipher aes-xts-plain64 --hash sha512 --use-random --verify-passphrase luksFormat /dev/nvme0n1p2 &&
  cryptsetup luksOpen /dev/nvme0n1p2 cryptlvm &&
  pvcreate /dev/mapper/cryptlvm &&
  vgcreate vg0 /dev/mapper/cryptlvm &&
  lvcreate -L 16G vg0 -n swap &&
  lvcreate -l 100%FREE vg0 -n root &&
  mkfs.btrfs -f /dev/vg0/root &&
  mkswap /dev/vg0/swap &&
  mount /dev/vg0/root /mnt &&
  swapon /dev/vg0/swap
```

Once the above block this done execute the one block of commands from below. This sets up btrfs subvolumes.

```bash
btrfs su cr /mnt/@ &&
  btrfs su cr /mnt/@home &&
  btrfs su cr /mnt/@opt &&
  btrfs su cr /mnt/@tmp &&
  btrfs su cr /mnt/@root &&
  btrfs su cr /mnt/@srv &&
  btrfs su cr /mnt/@nix &&
  btrfs su cr /mnt/@usr@local &&
  btrfs su cr /mnt/@var &&
  btrfs su cr /mnt/@var@cache &&
  btrfs su cr /mnt/@pkg &&
  btrfs su cr /mnt/@var@crash &&
  btrfs su cr /mnt/@var@tmp &&
  btrfs su cr /mnt/@var@spool &&
  btrfs su cr /mnt/@var@log &&
  btrfs su cr /mnt/@var@log@audit &&
  btrfs su cr /mnt/@snapshots &&
  umount /mnt
```

Next execute the following set of commands that setup mount the necessary directories.

```bash
mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@ /dev/vg0/root /mnt &&
  mkdir /mnt/home &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@home /dev/vg0/root /mnt/home &&
  mkdir /mnt/opt &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@opt /dev/vg0/root /mnt/opt &&
  mkdir /mnt/tmp &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@tmp /dev/vg0/root /mnt/tmp
  mkdir /mnt/root &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@root /dev/vg0/root /mnt/root &&
  mkdir /mnt/srv &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@srv /dev/vg0/root /mnt/srv &&
  mkdir /mnt/nix &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@nix /dev/vg0/root /mnt/nix &&
  mkdir -p /mnt/usr/local &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@usr@local /dev/vg0/root /mnt/usr/local &&
  mkdir /mnt/var &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var /dev/vg0/root /mnt/var &&
  mkdir /mnt/var/cache &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var@cache /dev/vg0/root /mnt/var/cache &&
  mkdir -p /mnt/var/cache/pacman/pkg &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@pkg /dev/vg0/root /mnt/var/cache/pacman/pkg
  mkdir /mnt/var/crash &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var@crash /dev/vg0/root /mnt/var/crash &&
  mkdir /mnt/var/tmp &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var@tmp /dev/vg0/root /mnt/var/tmp &&
  mkdir /mnt/var/spool &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var@spool /dev/vg0/root /mnt/var/spool &&
  mkdir /mnt/var/log &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var@log /dev/vg0/root /mnt/var/log &&
  mkdir /mnt/var/log/audit &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@var@log@audit /dev/vg0/root /mnt/var/log/audit &&
  mkdir /mnt/.snapshots &&
  mount -o noatime,compress=zstd:3,space_cache=v2,discard=async,subvol=@snapshots /dev/vg0/root /mnt/.snapshots &&
  mkdir /mnt/boot &&
  mount /dev/nvme0n1p1 /mnt/boot
```

Now, first check if the user's host archlinux system has arch-install-scripts installed or not. If not, install it. Now you must execute the following pacstrap command, followed by genfstab, and then enter chroot.

Now next comes the most crucial part for the python script. Once the script enter the chroot environment, it must also be able to execute the commands that follow after entering chroot. Furthermore, the user must have sudo access. I also want to disable the root account. The command for that is not available in the next block. You must search the web and find out best practices on how to achieve that.

```bash
pacstrap /mnt base base-devel devtools git neovim arch-install-scripts reflector dracut  wget btrfs-progs lvm2

genfstab -U /mnt >>/mnt/etc/fstab

arch-chroot /mnt

reflector --verbose -l 25 --country BD,IN,SG --sort rate --save /etc/pacman.d/mirrorlist

ln -sf /usr/share/zoneinfo/Asia/Dhaka /etc/localtime && hwclock --systohc && nvim /etc/locale.gen && locale-gen && echo "LANG=en_US.UTF-8" >>/etc/locale.conf

useradd -m -G users,wheel,audio,video -s /bin/bash ahsan && passwd ahsan
```

Next, change to user account by executing su - $USER. Now all commands must use sudo priviledges. It is crucial that script can execute commands after changing to user. This is set of commands aim to setup the cachyos repositories. Luckily this automatically enabled. So you just need to the following 3 commands sequentially. These 3 commands must be executed from /tmp

## Setup CachyOS repositories

```sh
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz && cd cachyos-repo
sudo ./cachyos-repo.sh
```

After the above commands are executed, execute the following command: sudo pacman -Syyuu

The next block of commands is an example of the output of the command `lsblk -o name,uuid`

```sh
nvme0n1
├─nvme0n1p1    B918-8549
└─nvme0n1p2    {nvme0n1p2}
  └─cryptlvm   TQ8t2M-PwaT-liwO-fPT8-v178-218Y-QhZGbw
    ├─vg0-swap {vg0-swap}
    └─vg0-root {vg0-root}
```

You must execute the command 'lsblk -o name,uuid' and the corresponding UUIDs for {nvme0n1p2}, {vg0-root}, and {vg0-swap} respectively

Then you must create a file called custom.conf /etc/dracut.conf.d/ directory and fill it with the following contents where you must replace all {} with the respective UUIDS from the last command

vg0-swap = c74f12c3-9cfe-4469-9b7f-2270bf704879
vg0-root = 11289bd2-113e-495a-9265-4a9ae7ed2340

```sh
hostonly="yes"
compress="zstd"
add_dracutmodules+=" crypt dm rootfs-block resume lvm "
omit_dracutmodules+=" network cifs nfs nbd brltty "
force_drivers+=" btrfs "
kernel_cmdline+=" rd.luks.uuid=luks-9687319d-3f60-4daf-8dcd-7e0ae6c6bf38 root=UUID=11289bd2-113e-495a-9265-4a9ae7ed2340 resume=UUID=c74f12c3-9cfe-4469-9b7f-2270bf704879 rd.lvm.lv=vg0/swap rd.lvm.lv=vg0/root "
```

The next part is to start setting up grub. You will need to install the following packages: grub, efibootmgr. And then update the /etc/default/grub file with the contents from the next block with {} being used placeholders for UUID

```sh
nvim /etc/default/grub
GRUB_CMDLINE_LINUX_DEFAULT="rootfstype=btrfs quiet loglevel=0 rw rd.vconsole.keymap=us rd.luks.uuid=luks-9687319d-3f60-4daf-8dcd-7e0ae6c6bf38 root=UUID=11289bd2-113e-495a-9265-4a9ae7ed2340 resume=UUID=c74f12c3-9cfe-4469-9b7f-2270bf704879 rd.lvm.lv=vg0/swap rd.lvm.lv=vg0/root"
GRUB_CMDLINE_LINUX=""
```

Now, this part involves setting the Endeavoros repository. While in /tmp, download the latest keyring and mirrorlist. Then install these packages. Check the /etc/pacman.conf to make sure the Endeavoros repository is after the cachyos repositories. Then execute the following two commands:

```sh
sudo pacman -S eos-dracut
sudo dracut-rebuild
```

sudo grub-install --target=x86_64-efi --efi-directory=/boot && sudo grub-install --target=x86_64-efi --efi-directory=/boot --removable && sudo grub-mkconfig -o /boot/grub/grub.cfg
