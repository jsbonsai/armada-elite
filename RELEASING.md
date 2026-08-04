# Releasing

How a new Elite image gets built and published.

**The sha256 is the identity of an image.** Every valid copy hashes to the same
value; that's how anyone (including future-you) verifies a download is the correct,
current image — no need to remember where a file came from, just hash it.

## 1. Build

Trigger the native-arm64 CI and download the resulting artifact (this *is* the
canonical image):

```bash
gh workflow run build-elite.yml --repo jsbonsai/armada-elite
# when it finishes:
gh run download <run-id> --repo jsbonsai/armada-elite -n armada-elite-disk-image
```

Rename it to `armada-elite-<YYYYMMDD>.img.gz` and record its checksum:

```bash
sha256sum armada-elite-<YYYYMMDD>.img.gz > armada-elite-<YYYYMMDD>.img.gz.sha256
```

## 2. Upload to Google Drive

The image is larger than GitHub's 2 GB release-asset cap, so it can't live on the
release itself. Upload **both** the `.img.gz` and the `.sha256` to the shared Google
Drive folder, set to **"Anyone with the link → Viewer."** Use the clean folder URL
(`https://drive.google.com/drive/folders/<id>`), **not** a `/u/N/` URL — those are
tied to your own signed-in account and 404 for everyone else. Confirm sharing by
opening the link in a private/incognito window.

Then verify the uploaded copy: download it back and re-hash — it must match the
`.sha256`.

## 3. Publish the GitHub release

Create/replace the release for the version tag with, in this order:

- a **Warning** callout (proof-of-concept),
- a **Download** section: the Google Drive folder link + the `sha256` shown inline in
  a code block,
- an **Install** section linking the README's flashing steps.

No image assets live on GitHub. The release is the **versioned record** (tag + sha),
Google Drive is the **single download**.

> **Do not split the image into parts.** Split files caused broken reassemblies for
> downloaders (GUI extractors like The Unarchiver mangle raw `split` pieces), and a
> corrupt file is exactly what makes a flasher report "no partition table." One
> verified single file avoids the entire class of problems.

## Verifying any copy

```bash
shasum -a 256 armada-elite-<YYYYMMDD>.img.gz   # compare to the release's sha256
```

Matches → it's the real, current image, and it flashes and boots cleanly.
Doesn't match → it's stale or corrupt; re-download.
