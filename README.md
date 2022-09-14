## Build and run

```sh
./secure-boot/genkeys.sh
mkosi build
mkosi qemu
```

## Manual secure boot enrollment (inside booted VM in setup mode)

### Arch Linux

Consult [the archlinux wiki](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_sbkeysync) for more information.

```sh
sbkeysync --verbose
sbkeysync --verbose --pk
chattr -i /sys/firmware/efi/efivars/{PK,KEK,db}*
efi-updatevar -f /etc/secureboot/keys/PK/PK.auth PK
reboot
```

### Fedora

```sh
# check if kernel is signed properly
sbverify --list /boot/722d47d2636d4f79bc290e8cfd14cd31/5.19.8-200.fc36.x86_64/linux
# sign if needed
sbsign --key /tmp/db.key --cert /tmp/db.crt --output /boot/722d47d2636d4f79bc290e8cfd14cd31/5.19.8-200.fc36.x86_64/linux /boot/722d47d2636d4f79bc290e8cfd14cd31/5.19.8-200.fc36.x86_64/linux
systemctl reboot --firmware-setup
# load keys from firmware menu and reboot
```

## Check secure boot status

```shell-session
# bootctl
System:
     Firmware: UEFI 2.70 (EDK II 1.00)
  Secure Boot: enabled (user)
[…]

# mokutil --sb-state
SecureBoot enabled
```


## Use Microsoft signed shim

```sh
# run after mkosi build
sudo ./secure-boot/signed-shim.sh
```
