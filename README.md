# LBP3 Bonsai Patch Installer

A one-click installer / auto-updater for the **Bonsai online patch** on
[littlebigplanet3-pc](https://github.com/sethlikepie/littlebigplanet3-pc) (the native Windows port of
LittleBigPlanet 3 PS4, CUSA00473 v1.28).

The port ships with online support disabled by default and **no server patch**. This tool installs
sgdc3's `LBP3 online v01.28: custom server (lbp.lbpbonsai.com)` patch into an existing installation.

## Download

Grab `LBP3-Bonsai-Installer.zip` from the [latest release](../../releases/latest), extract it, and keep
these two files together:

- `Install-LBP3-Bonsai-Patch.bat`
- `Install-LBP3-Bonsai-Patch.ps1`

## Usage

1. Double-click **`Install-LBP3-Bonsai-Patch.bat`**.
2. If the game folder is not found automatically, drag the folder containing
   `LittleBigPlanet 3.exe` onto the `.bat` file.
3. Press **Enter** when asked about the download link.
4. Start LittleBigPlanet 3 and press **Play**.

### Auto-update

Run the installer any time. It downloads the patch and compares its SHA-256 with the installed copy.
If nothing changed, it leaves the installation alone; if the patch changed, it backs up the old patch
and installs the new one.

### Patch source / auto-update

The patch itself is hosted at `patch/lbp3-128-online.zip` in this repository (downloaded via the
`refs/heads/main` raw URL), so there is no expiring
Discord link. Every run downloads it from GitHub and compares its SHA-256 with the installed copy; it
only reinstalls when the file changed. A copy of the patch is also included in the release ZIP as an
offline fallback. If you want to use a different source, type **L** at the prompt and paste a URL or
local path.

## Build check

The installer first checks whether the detected installation is the **Online** build. The Standard
build has all networking code compiled out, so the patch cannot work there. If a Standard build is
found, the installer warns you to install `lbp3-pc-online-<version>.zip` and lets you cancel or
continue anyway.

## What it changes

- Copies the patch and `files.json` into `<port>\data\patches\bonsai-online\`.
- Adds the patch to `<port>\data\patches.json` as enabled (preserving other entries).
- Writes `lbp3_online=1` and your `online_id` (Bonsai username) into `<port>\data\lbp3.ini`.
- Writes JSON as UTF-8 **without** a BOM (a BOM makes the port's Python launcher crash on Play).

## Getting a 403 in game

On the [Bonsai website](https://lbp.lbpbonsai.com/): **View Profile → Edit Profile**, enable
**Allow IP Authentication**, then **View IP Authentication Requests** and approve the pending request.
You may need to approve again when your IP changes.

## Caveat

The native port does not include a shadNet client. Login to Bonsai can work, but friend lists and
co-op that depend on shadNet may still fail. For fully working Bonsai online, follow the Project
Imaginari shadPS4 guide instead.

## Troubleshooting

If Play closes immediately, send the newest `game-*.log` from `<port>\data\logs\` along with your
report.
