#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASE_DIR=$(realpath "${SCRIPT_DIR}/..")
PKI=${BASE_DIR}/pki
MKOSI_EXTRA=${BASE_DIR}/mkosi.extra

gen_pki () {
    count=`ls -1 ${PKI}/*.{key,crt,cer,esl,auth} 2>/dev/null | wc -l`
    if [ $count != 0 ]
    then
        return
    fi
    mkdir -p "${PKI}"
    pushd "${PKI}"

    uuid=$(systemd-id128 new --uuid)
    for key in PK KEK db; do
        openssl req -new -x509 -subj "/CN=${key}/" -keyout "${key}.key" -out "${key}.crt" -nodes
        openssl x509 -outform DER -in "${key}.crt" -out "${key}.cer"
        cert-to-efi-sig-list -g "${uuid}" "${key}.crt" "${key}.esl"
    done

    for key in MicWinProPCA2011_2011-10-19.crt MicCorUEFCA2011_2011-06-27.crt MicCorKEKCA2011_2011-06-24.crt; do
        curl "https://www.microsoft.com/pkiops/certs/${key}" --output "${key}"
        sbsiglist --owner 77fa9abd-0359-4d32-bd60-28f4e78f784b --type x509 --output "${key%crt}esl" "${key}"
    done

    # Optionally add Microsoft Windows Production CA 2011 (needed to boot into Windows).
    cat MicWinProPCA2011_2011-10-19.esl >> db.esl

    # Optionally add Microsoft Corporation UEFI CA 2011 (for firmware drivers / option ROMs
    # and third-party boot loaders (including shim). This is highly recommended on real
    # hardware as not including this may soft-brick your device (see next paragraph).
    cat MicCorUEFCA2011_2011-06-27.esl >> db.esl

    # Optionally add Microsoft Corporation KEK CA 2011. Recommended if either of the
    # Microsoft keys is used as the official UEFI revocation database is signed with this
    # key. The revocation database can be updated with [fwupdmgr(1)](https://www.freedesktop.org/software/systemd/man/fwupdmgr.html#).
    cat MicCorKEKCA2011_2011-06-24.esl >> KEK.esl

    sign-efi-sig-list -c PK.crt -k PK.key PK PK.esl PK.auth
    sign-efi-sig-list -c PK.crt -k PK.key KEK KEK.esl KEK.auth
    sign-efi-sig-list -c KEK.crt -k KEK.key db db.esl db.auth

    popd
}

insert_keys () {
    # for auto enrollment using systemd-boot (not working yet)
    mkdir -p "${MKOSI_EXTRA}/boot/loader/keys/auto"
    cp ${PKI}/{PK,KEK,db}.cer "${MKOSI_EXTRA}/boot/loader/keys/auto"
    cp ${PKI}/{MicWinProPCA2011_2011-10-19,MicCorUEFCA2011_2011-06-27,MicCorKEKCA2011_2011-06-24}.crt "${MKOSI_EXTRA}/boot/loader/keys/auto"
    cp ${PKI}/{PK,KEK,db}.esl "${MKOSI_EXTRA}/boot/loader/keys/auto"
    cp ${PKI}/{PK,KEK,db}.auth "${MKOSI_EXTRA}/boot/loader/keys/auto"

    # for manual enrollment using sbkeysync
    mkdir -p ${MKOSI_EXTRA}/etc/secureboot/keys/{db,dbx,KEK,PK}
    cp ${PKI}/db.auth "${MKOSI_EXTRA}/etc/secureboot/keys/db/"
    cp ${PKI}/KEK.auth "${MKOSI_EXTRA}/etc/secureboot/keys/KEK/"
    cp ${PKI}/PK.auth "${MKOSI_EXTRA}/etc/secureboot/keys/PK/"
}

gen_pki
insert_keys
