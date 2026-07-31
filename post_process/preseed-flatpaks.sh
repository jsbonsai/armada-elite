#!/bin/bash
set -euxo pipefail

RAW_IMAGE="${1:-output/image/disk.raw}"
REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
REFS_FILE="${REFS_FILE:-${REPO_ROOT}/flatpak/defaults.refs}"
FEDORA_IMAGE="${FEDORA_IMAGE:-quay.io/fedora/fedora:44}"

[[ -f "${RAW_IMAGE}" ]] || { echo "ERROR: raw image not found: ${RAW_IMAGE}" >&2; exit 1; }
[[ -s "${REFS_FILE}" ]] || { echo "No Flatpak refs to preseed: ${REFS_FILE}"; exit 0; }

WORK=$(mktemp -d)
LOOP=""
trap 'sudo umount "${WORK}/root" 2>/dev/null || true; if [[ -n "${LOOP}" ]]; then sudo losetup -d "${LOOP}" 2>/dev/null || true; fi; rm -rf "${WORK}"' EXIT

mkdir -p "${WORK}/out"
podman run \
    --rm \
    --privileged \
    --pull=newer \
    --net=host \
    --platform linux/arm64 \
    -e FLATPAK_SYSTEM_DIR=/flatpak \
    -e FLATPAK_TRIGGERSDIR=/triggers \
    -v "${REFS_FILE}:/refs/defaults.refs:ro" \
    -v "${WORK}/out:/out" \
    "${FEDORA_IMAGE}" \
    bash -euxo pipefail -c '
        dnf5 -y install --setopt=install_weak_deps=False flatpak
        mkdir -p /flatpak /triggers /var/tmp
        chmod 1777 /var/tmp
        flatpak config --system --set languages "*"
        flatpak remote-add --system flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        xargs -r -a /refs/defaults.refs flatpak install --system -y --noninteractive
        if grep -qx "app/org.mozilla.firefox/aarch64/stable" /refs/defaults.refs; then
            flatpak override --system --env=MOZ_USE_XINPUT2=1 org.mozilla.firefox
        fi
        mkdir -p /out/flatpak
        cp -a /flatpak/. /out/flatpak/
    '

LOOP=$(sudo losetup -fP --show "${RAW_IMAGE}")
sleep 1

ROOT_PART=""
for part in "${LOOP}"p*; do
    if sudo blkid -s TYPE -o value "${part}" 2>/dev/null | grep -qx btrfs; then
        ROOT_PART="${part}"
        break
    fi
done
[[ -n "${ROOT_PART}" ]] || { echo "ERROR: btrfs root partition not found in ${RAW_IMAGE}" >&2; exit 1; }

mkdir -p "${WORK}/root"
sudo mount -o subvol=root "${ROOT_PART}" "${WORK}/root"

stateroot_var="${WORK}/root/ostree/deploy/default/var"
[[ -d "${stateroot_var}" ]] || { echo "ERROR: ostree stateroot var not found in ${ROOT_PART}" >&2; exit 1; }

sudo mkdir -p "${stateroot_var}/lib"
sudo rsync -aAXH "${WORK}/out/flatpak" "${stateroot_var}/lib/"
sudo chown -R root:root "${stateroot_var}/lib/flatpak"
sudo sync "${stateroot_var}/lib/flatpak"

echo "Preseeded system Flatpaks into ${RAW_IMAGE}:"
sed 's/^/  /' "${REFS_FILE}"
