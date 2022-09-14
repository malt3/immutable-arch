#!/bin/bash
set -euxo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$(realpath "${SCRIPT_DIR}/..")
MKOSI_EXTRA=${BASE_DIR}/mkosi.extra
TMPDIR=$(mktemp -d)
pushd "${TMPDIR}"

SOURCE=https://kojipkgs.fedoraproject.org/packages/shim/15.6/2/x86_64/shim-x64-15.6-2.x86_64.rpm
EXPECTED_SHA512=971978bddee95a6a134ef05c4d88cf5df41926e631de863b74ef772307f3e106c82c8f6889c18280d47187986abd774d8671c5be4b85b1b0bb3d1858b65d02cf
curl -L -o shim.rpm "${SOURCE}"
echo "Checking SHA512 checksum of signed shim..."
sha512sum -c <<< "${EXPECTED_SHA512}  shim.rpm"
rpm2cpio shim.rpm | cpio -idmv
echo $TMPDIR

popd

MOUNTPOINT=$(mktemp -d)
sectoroffset=$(sfdisk -J "${BASE_DIR}/image.raw" | jq -r '.partitiontable.partitions[0].start')
byteoffset=$((sectoroffset * 512))
mount -o offset="${byteoffset}" "${BASE_DIR}/image.raw" "${MOUNTPOINT}"

mkdir -p "${MOUNTPOINT}/EFI/BOOT/"
cp "${TMPDIR}/boot/efi/EFI/BOOT/BOOTX64.EFI" "${MOUNTPOINT}/EFI/BOOT/"
cp "${TMPDIR}/boot/efi/EFI/fedora/mmx64.efi" "${MOUNTPOINT}/EFI/BOOT/"
cp "${MOUNTPOINT}/EFI/systemd/systemd-bootx64.efi" "${MOUNTPOINT}/EFI/BOOT/grubx64.efi"
sha512sum "${MOUNTPOINT}/EFI/BOOT/BOOTX64.EFI"
sha512sum "${MOUNTPOINT}/EFI/BOOT/grubx64.efi"

umount "${MOUNTPOINT}"
rm -rf ${MOUNTPOINT}
rm -rf "${TMPDIR}"
