# LBP3 Bonsai Patch Installer

A one-click installer and auto-updater for the **Bonsai online patch** on
[littlebigplanet3-pc](https://github.com/sethlikepie/littlebigplanet3-pc) — the native Windows port of
LittleBigPlanet 3 PS4 (CUSA00473 v1.28).

The port ships with online support off by default and **no server patch**. This tool installs sgdc3's
`LBP3 online v01.28: custom server (lbp.lbpbonsai.com)` patch into an existing installation.

## Features

- Detects the **Online** vs **Standard** build and refuses to patch a Standard install.
- Finds your lbp3-pc folder automatically, or you can drag it onto the `.bat` file.
- Downloads the patch from this repository and verifies it targets CUSA00473 v1.28 / `eboot.bin`.
- Sets `lbp3_online=1` and asks for your Bonsai username (`online_id`), including the option to change an existing one.
- Enables the patch in `data\patches.json` and writes BOM-free JSON (a BOM makes the launcher crash on Play).
- **Auto-update:** every run compares SHA-256 hashes and only reinstalls when the patch changes.
- Bundled offline fallback if GitHub is unreachable.

## Download

Get `LBP3-Bonsai-Installer.zip` from the [latest release](../../releases/latest) and extract it. Keep
these files together in one folder:

- `Install-LBP3-Bonsai-Patch.bat` — double-click this
- `Install-LBP3-Bonsai-Patch.ps1` — installer logic
- `lbp3-128-online.zip` — offline fallback copy of the patch

## Requirements

- Windows 10/11 and an existing **Online** build of littlebigplanet3-pc (not Standard).
- LittleBigPlanet 3 US, CUSA00473, with update 1.28.
- A [Bonsai account](https://lbp.lbpbonsai.com/register) whose username matches your `online_id`.

## Quick start

1. Double-click **`Install-LBP3-Bonsai-Patch.bat`**.
2. If the game folder is not found, drag the folder containing `LittleBigPlanet 3.exe` onto the `.bat`.
3. Press **Enter** to use the GitHub-hosted patch, or type `L` to supply a different URL/local file.
4. Enter your Bonsai username when asked (or press Enter to keep the current one).
5. Start LittleBigPlanet 3 and press **Play**.

## Custom server selection

At startup the installer offers three choices:

1. **Bonsai** — the bundled, verified patch (default).
2. **Custom server address** — enter an IP or hostname; the installer adds a marked, reversible line to
   `C:\Windows\System32\drivers\etc\hosts` mapping `lbp.lbpbonsai.com` to it. This redirects the game to
   your server without changing any patch bytes. It needs **Run as administrator**, and choosing option 1
   again removes the override.
3. **Custom patch** — paste a URL or local ZIP path for a patch built for another server.

Option 2 only changes where the Bonsai-patched client connects; the server still has to speak the PS4
LBP3 protocol and accept the client's login.

## Join key (playing together with Dive In disabled)

The patch already contains a shared join key, `PatchworkLBP3 1.0`, so everyone using this installer can
play together even though Bonsai has Dive In disabled. The installer can also write a **custom join
key**: choose it at the "Join key" prompt. It must be exactly **17 printable ASCII characters** —
a hard limit, because the key is written into a fixed-size slot in `eboot.bin` (vaddr `0x124b1f0`)
and a longer value would corrupt the data after it. Everyone who should be able to join must use the
same key. Type `D` at the prompt to return to the default key.

## Patch source and auto-update

The patch lives at `patch/lbp3-128-online.zip` in this repository and is downloaded from
`https://raw.githubusercontent.com/Eyeffect/lbp3-bonsai-patch-installer/refs/heads/main/patch/lbp3-128-online.zip`.

Each run downloads it and compares its SHA-256 with the installed copy. If nothing changed, nothing is
touched; if it changed, the old patch is backed up (and its `files.json` disabled so it is never
applied twice) and the new one is installed. No external expiring download link is involved.

## Build check

The Standard build has all networking code compiled out, so the patch cannot work. The installer
checks for online-code markers in `bin\lbp3-probe.exe`. If a Standard build is detected, it tells you
to install `lbp3-pc-online-<version>.zip` and lets you cancel or continue anyway.

## What it changes

- Copies the patch and `files.json` into `<port>\data\patches\bonsai-online\`.
- Adds it to `<port>\data\patches.json` as enabled, preserving other entries.
- Writes `lbp3_online=1` and `online_id=<your username>` into `<port>\data\lbp3.ini`.
- Writes JSON as UTF-8 **without** a BOM.

## Getting a 403 in game

On the [Bonsai website](https://lbp.lbpbonsai.com/): **View Profile → Edit Profile**, enable
**Allow IP Authentication**, then **View IP Authentication Requests** and approve the pending request.
You may need to approve again when your IP changes.

## Caveat

The native port has no shadNet client. Login to Bonsai can work, but friend lists and co-op that depend
on shadNet may still fail. For fully working Bonsai online, use the Project Imaginari shadPS4 guide.

## Troubleshooting

If Play closes immediately, send the newest `game-*.log` from `<port>\data\logs\` with your report.

## License

MIT — see [LICENSE](LICENSE).
