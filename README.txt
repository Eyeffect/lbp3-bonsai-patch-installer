LBP3 Bonsai online patch - installer / updater
==============================================

For: littlebigplanet3-pc (the native Windows port), CUSA00473 v1.28.

WHAT IT DOES
- Finds your lbp3-pc installation (or you can drag the folder onto the .bat).
- Downloads the Bonsai online patch and checks it really targets CUSA00473 1.28.
- Installs it into data\patches and enables it in data\patches.json.
- Makes sure lbp3_online=1 and asks for your Bonsai username (online_id).
- Every time you run it, it compares the SHA-256 hash and only reinstalls if the
  patch actually changed (auto-update).

HOW TO USE
1. Keep both files together in one folder:
     Install-LBP3-Bonsai-Patch.bat
     Install-LBP3-Bonsai-Patch.ps1
2. Double-click the .bat file.
3. If it cannot find the game, drag the folder containing
   "LittleBigPlanet 3.exe" onto the .bat file.
4. Press Enter when asked about the download link. If Discord says the link
   expired, type L, then in Discord right-click the patch zip > Copy link and
   paste it.
5. Start LittleBigPlanet 3 and press Play.

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
