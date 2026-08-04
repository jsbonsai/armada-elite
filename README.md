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

## How it works (why the Elite is selectable)

Armada boots through the **ROCKNIX ABL** — the Android bootloader that ROCKNIX
uses in place of the stock one. Two independent pieces have to line up, and this
fork only supplies the second:

- **The selector (ROCKNIX's side).** ROCKNIX added the Pocket FIT Elite to its
  SM8750 device support, so the ROCKNIX ABL you flash already lists
  **KONKR Pocket FIT Elite** in its on-device model menu, and knows the board-id
  to match it.
- **What it points at (this fork's side).** The Elite's **device tree (DTB)** and
  kernel drivers are baked into the image's boot partition. When you pick
  "KONKR Pocket FIT Elite" in the ABL menu, the ABL hands that matching Elite DTB
  to Armada's kernel, and it comes up with the correct panel, touch, audio, and
  so on.

So: ROCKNIX provides the selector, the image provides the thing it selects. The
same ABL is used by ROCKNIX and Armada — it's distro-agnostic, which is why you
can even swap SD cards between the two.

## Download

The image (~7.9 GB) is hosted on **Google Drive** — it's larger than GitHub's 2 GB
release-file limit:

**[Download armada-elite-20260801.img.gz (Google Drive)](https://drive.google.com/drive/folders/1nX-a18R8ybhpo-YB--X8hQcGCQlXjJ2U)**

The folder holds the image and its `.sha256`. After downloading, verify it's the real
thing:

```bash
shasum -a 256 armada-elite-20260801.img.gz
# must equal:
# f401a672da19841dee65e4f10237e292f14c76fb0fd7b693e231b0ce92f388f1
```

If the hash matches, it's the correct image. The [latest release](../../releases/latest)
always shows the current version and checksum.

## Flash & boot

> [!WARNING]
> Booting Armada requires replacing the device's **ABL** bootloader. Flashing the
> wrong SoC's ABL, or a bad flash, can **brick the device or corrupt your Android
> partition**. Do this at your own risk, and keep the ABL backup the script makes.

The Elite is an **SM8750** device — you'll use the `SM8750` ABL. The ABL flashing
tools ship *inside this image*, so there's nothing extra to download.

### 1. Flash the image to a microSD

Write the **verified** `armada-elite-20260801.img.gz` to a **64 GB+ (A2)** card with
**Balena Etcher**, **Raspberry Pi Imager**, or `dd`. Etcher takes the `.gz` directly.

> [!NOTE]
> Only flash a file whose sha256 matches the one above. If a flasher complains the
> image "isn't bootable" or has "no partition table," your **download is corrupt or
> truncated** — re-download and re-check the sha256. A verified image flashes and
> boots cleanly.

### 2. Flash the ROCKNIX ABL (once, from Android)

1. Put the flashed card in the Elite and boot its stock **Android**. The card's
   data volume shows up labeled **`ARMADA`**.
2. Copy the **`rocknix_abl`** folder from that volume to the root of internal
   storage, then open **`rocknix_abl/SM8750`** (the Elite is listed there as
   *KONKR Pocket FIT (8 Elite)*).
3. Using the device's built-in **"run script as root"** tool, run **`backup_abl.sh`**.
   It writes `abl_a.img` and `abl_b.img` into that folder — **copy those to a PC
   and keep them.** That's your one-command path back to stock.
4. Run **`flash_abl.sh`** the same way to install the ROCKNIX ABL.

### 3. Boot into the ABL menu and select the Elite

1. Reboot **holding VOL-** to enter the ROCKNIX ABL menu.
2. Navigate with **VOL- / VOL+**, select with **POWER**:
   - **Set device model → KONKR Pocket FIT (8 Elite)**
   - **Toggle boot mode → Linux**
   - **Start**
3. This is a one-time setup — the choices persist, and the device then boots
   straight into Armada from the card.

### 4. First boot

After the intro animation the screen can be **black for up to ~60 seconds** before
Steam's first-run setup appears (language, timezone, Wi-Fi). Steam then restarts
once more — another short black screen — and you're in.

> [!NOTE]
> The image ships with user `armada` / password `armada`, SSH off by default.
> Change the password before enabling SSH on an untrusted network.

## Daily use: sleep & storage

### Sleep drains the battery — consider powering off instead

Like mainline Armada, this build uses **"fake sleep"** rather than true suspend:
pressing the power button freezes the session and blanks the screen, but the SoC
stays powered, so **idle battery drain during sleep is noticeable**. Real
suspend-to-idle (`s2idle`) isn't implemented yet. Until it is, if you're setting
the device down for a while, **power it off** rather than sleeping — the ROCKNIX
ABL autoboots straight into Linux, so cold-booting back into Armada is painless.

### Keep the OS on the SD card; put games on an internal partition

You *can* install Armada to internal storage (Desktop Mode → **Armada Installer**),
and it's technically supported — but I'd hold off. The setup I actually run, and
recommend:

- **Run the OS from the microSD card**, and
- **Carve out a partition on internal storage for your Steam library** — games
  install to fast internal UFS while the OS stays on the card.

The point is to keep your games **decoupled from the OS**. When mainline Armada
adds KPF Elite support, you just switch to the mainline image on the card and
**keep your entire Steam library** — no re-download, no wiping internal.
Installing the OS itself to internal ties it all together and means redoing
everything on the next switch. (Carving the partition is a manual, somewhat
advanced step — you repartition internal yourself and point Steam at the mounted
drive.)

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
