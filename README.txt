LBP3 Bonsai online patch - installer / updater
==============================================

For: littlebigplanet3-pc (the native Windows port), CUSA00473 v1.28.

WHAT IT DOES
- Finds your lbp3-pc installation (or you can drag the folder onto the .bat).
- Checks that you have the ONLINE build; the Standard build cannot use the patch.
- Downloads the Bonsai patch from this GitHub repo and checks it really targets
  CUSA00473 1.28 / eboot.bin.
- Installs it into data\patches and enables it in data\patches.json.
- Makes sure lbp3_online=1 and asks for your Bonsai username (online_id).
- Every run compares the SHA-256 hash and only reinstalls if the patch changed.

HOW TO USE
1. Keep these files together in one folder:
     Install-LBP3-Bonsai-Patch.bat
     Install-LBP3-Bonsai-Patch.ps1
     lbp3-128-online.zip   (offline fallback; optional)
2. Double-click the .bat file.
3. If it cannot find the game, drag the folder containing
   "LittleBigPlanet 3.exe" onto the .bat file.
4. Press Enter to use the GitHub-hosted patch. Type L only if you want to use a
   different URL or local zip.
5. At the Join key prompt, press Enter to use the shared default key. Everyone
   using this installer shares it, so friends can play together even with
   Bonsai's Dive In disabled. For a private key, type exactly 17 printable
   characters; all players must use the same key. Type D to reset to default.
6. Start LittleBigPlanet 3 and press Play.

No Discord link is needed. The patch is hosted in the GitHub repo, so updates are
found automatically. If GitHub is unreachable, the bundled lbp3-128-online.zip
is used instead.

GETTING A 403 IN GAME
On the Bonsai website: Edit Profile > enable "Allow IP Authentication", then
"View IP Authentication Requests" > approve the pending request. You may need
to approve again if your IP changes.

NOTE
This patch needs a Bonsai account whose username matches your online_id.
The native port does not include a shadNet client, so friend/co-op features
that depend on shadNet may not work even after login succeeds.

If Play closes immediately, send the newest file in:
  <your lbp3-pc folder>\data\logs\game-*.log
