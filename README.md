## Build and run

```sh
./secure-boot/genkeys.sh
mkosi build
mkosi qemu
```

## Manual secure boot enrollment (inside booted VM in setup mode)

Consult [the archlinux wiki](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Using_sbkeysync) for more information.

```sh
sbkeysync --verbose
sbkeysync --verbose --pk
chattr -i /sys/firmware/efi/efivars/{PK,KEK,db}*
efi-updatevar -f /etc/secureboot/keys/PK/PK.auth PK
reboot
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
