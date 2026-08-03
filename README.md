# Armada — KONKR Pocket FIT Elite (SM8750)

A fork of [**ArmadaOS**](https://github.com/armada-os/armada) that adds support for the
**KONKR / AYANEO Pocket FIT Elite** (Snapdragon 8 Elite, SM8750). Armada is a
SteamOS-like Linux distribution for ARM handhelds, built on Fedora bootc using
device support from [ROCKNIX](https://github.com/ROCKNIX/distribution).

> [!IMPORTANT]
> **This is a working proof-of-concept, not a product.** I built it to run
> ArmadaOS on my Elite, tested it, and everything I could find works (see below).
> But it's a personal fork maintained by one person — if you're not comfortable
> flashing an ABL and reassembling a split image, **wait for official Elite
> support in mainline Armada**, which shouldn't be far off. I'll retire this fork
> and switch to mainline once that lands.

## What works

Tested on my own Elite over a weekend of real use — no notable bugs or
performance issues:

- Display (1080×1920 @ 144 Hz), touchscreen
- Audio: speaker **and** headphone jack, mic
- Battery / charging, USB-C (host + charging)
- Wi-Fi, Bluetooth
- Joystick, D-pad, **all** face/shoulder buttons
- Steam Deck controller profile via InputPlumber: **KONKR button → Guide**,
  **front-top-right → Steam Quick Access (QAM)**, extra shoulders → back paddles

## Get the image

Grab the latest split image from **[Releases](../../releases/latest)**. GitHub
caps release files at 2 GB, so the ~7.5 GB image is split into parts. Reassemble:

```bash
cat armada-elite-*.img.gz.part-* > armada-elite.img.gz
# optional: verify against the SHA256 in the release notes
sha256sum armada-elite.img.gz
```

## Flash & boot

> [!WARNING]
> Booting Armada requires flashing the **ROCKNIX ABL**, which can brick your
> device or corrupt your Android partition. Do this at your own risk.

1. **Flash the ROCKNIX ABL** for the SM8750 (from within Android, using ROCKNIX's
   `backup_abl.sh` / `flash_abl.sh`). This ABL is distro-agnostic — the same one
   boots ROCKNIX and Armada. It only has to be done once.
2. **Flash the image to an SD card** (64 GB+, A2) with Balena Etcher — it accepts
   the reassembled `armada-elite.img.gz` directly.
3. **Boot from the card.** The ABL selects the Elite DTB by board-id. Expect a
   ~60 s black screen on first boot before Steam's first-run setup.

Armada can later install itself to internal storage alongside Android, but on the
Elite I'd keep it on SD for now.

> [!NOTE]
> The image ships with user `armada` / password `armada`, SSH off by default.
> Change the password before enabling SSH on an untrusted network.

## Build it yourself

The image is built by native-arm64 CI. From the Actions tab, run the
**Build Elite disk image** workflow (`build-elite.yml`), or:

```bash
gh workflow run build-elite.yml --repo <your-fork>/armada-elite
```

It wraps a prebuilt Elite kernel (7.0.11 + ROCKNIX/Elite patches, in
`elite-kernel/`) and builds the bootc disk image with bootc-image-builder.

## Credits

All the hard device work is upstream — this fork just wires the Elite into it:

- [**ArmadaOS**](https://github.com/armada-os/armada) — the distribution
- [**ROCKNIX**](https://github.com/ROCKNIX/distribution) — device support + the ABL,
  including the SM8750 KONKR Pocket FIT Elite bring-up (slaide's PR #3074)
