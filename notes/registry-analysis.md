# ROCBA-001 Registry Hive Analysis Supplement

## NTUSER.DAT - Fred Rocba (fredr) - Key Findings

### 1. Recently Accessed Files (from Shell Bags / ComDlg32 MRU)

Extracted from `Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU`:

**File extensions in Open/Save MRU:** (docx, pdf, pptx, xlsx, zip, txt, ...)

**Key document paths recovered from binary strings:**

**C:\ drive (local):**
- `C:\Users\fredr\Stark Research Labs\GunStar Death Blossom Data.docx`
- `C:\Users\fredr\OneDrive\Documents\SRL\SRL VPN Setup.pdf`
- `C:\Users\fredr\Google Drive\Firedam.xls`
- `C:\Users\fredr\Google Drive\BetterWidgets Business Plan\BusinessPlan.docx`
- `C:\Users\fredr\Google Drive\NETFLIX SEC Filings\NETFLIX_10-K_20130201.xls`
- `C:\Users\fredr\AppData\Local\Microsoft\Office\16.0\TapCache\POWERPNT\DocPreviews\...`

**E:\ drive (external/USB):**
- `E:\New Homework\Homework Grade 3.docx`

**F:\ drive (external):**
- `F:\Files from SRL system\The Future of KITT.pptx`
- `F:\Files of interest\SRL-Projects - Megaforce\Megaforce\Megaforce Specs & Research.docx`
- `F:\Files of interest\Recovered Documents\Wolves_Lair_Tech_Specs.pptx`

**G:\ drive (Google Drive mapped):**
- `G:\My Drive\STARK-RESEARCH-LABS FOLDER\Research to Weaponize the Ion Thruster.docx`
- `G:\My Drive\STARK-RESEARCH-LABS FOLDER\Research\Vibrainium(1).doc`
- `G:\My Drive\STARK-RESEARCH-LABS FOLDER\Airwolf-SRL\Wolf Air\Wolf AIr Financials.xlsx`
- `G:\My Drive\STARK-RESEARCH-LABS FOLDER\SRL-Projects - Gunstar\GunStar Death Blossom Data.docx`

**Document names found (shell MRU):**
- `GunStar Death Blossom Data.docx` (weapon system)
- `Research to Weaponize the Ion Thruster.docx`
- `The Future of KITT.pptx` + older version
- `TIVO Research.docx`
- `Vibrainium(1).doc` / `Vibrainium - SRL.docx`
- `Wolf AIr Financials.xlsx`
- `Wolves_Lair_Tech_Specs.pptx`
- `Superalloys_2010_13_50.pdf`
- `Starfighter 5200 Manual.pdf`
- `StarFury.zip`
- `SA-23E Mitchell-Hyundyne Starfury.docx`
- `Quantum Particles Affected by Other Dimensions.pdf`
- `SRL VPN Setup.pdf`
- `SRL-EMAIL-EXPORT.pst` (email export! 🔴)
- `USA HOCKEY Confirmation Page.pdf`
- `Trademarks on Base-Metal Tableware.pdf`

### 2. Run Commands / Programs Executed (from UserAssist shell GUIDs)

**Programs pinned to taskbar / recently launched:**
- `cmd.exe` ✅
- `powershell.exe` ✅
- `regedit.exe` ✅
- `mstsc.exe` ✅ (Remote Desktop)
- `Zoom.exe` ✅
- `Teams.exe` ✅
- `Slack.exe` ✅
- `Chrome.exe` ✅
- `Firefox.exe` ✅
- `Notepad.exe`
- `WordPad`
- `SnippingTool.exe`
- `PowerShell_ISE.exe`
- `mspaint.exe`
- `GoogleDriveSync.exe` / `GoogleDriveFS.exe` ✅
- `Dropbox.exe` ✅
- `AppleInc.iCloud_*` services ✅ (multiple: iCloudDrive, iCloudPhotos, iCloudServices, iCloudChrome, iCloudFirefox, iCloudIE)
- `Microsoft Office`: Word, Excel, PowerPoint, OneNote, Outlook, Publisher, Access
- `MdSched.exe` (memory diagnostics scheduler)
- `RecoveryDrive.exe`
- `cleanmgr.exe` (disk cleanup)
- `msconfig.exe`
- `msinfo32.exe`
- `dfrgui.exe` (disk defragmenter)
- `iscsicpl.exe` (iSCSI initiator)
- `magnify.exe`
- `charmap.exe`
- `osk.exe` (on-screen keyboard)
- `narrator.exe`
- `quickassist.exe`
- `odbcad32.exe`

**Cloud storage programs confirmed running:**
- Google Drive (both classic sync and Drive File Stream)
- Dropbox Desktop Client
- iCloud (Drive, Photos, Chrome extension, Firefox extension, IE extension)
- Microsoft OneDrive / SkyDrive
- SharePoint sync

**Communication tools:**
- Teams (Microsoft teams)
- Slack
- Zoom

### 3. Network Drive Mappings & External Volumes

**Local volumes accessed:**
- `C:\Users\fredr\` (main profile)
- `D:\` (not observed in data)
- `E:\New Homework\` (external USB/volume - Homework Grade 3.docx)
- `F:\Files from SRL system\` (external - KITT.pptx)
- `F:\Files of interest\` (external - Megaforce docs, Recovered Documents)
- `F:\Files of interest\Recovered Documents\` (external - Wolves_Lair_Tech_Specs.pptx)
- `G:\My Drive\STARK-RESEARCH-LABS FOLDER\` (Google Drive mapped as drive letter G:)

**Evidence that SRL files were copied to external drives:**
- `F:\Files from SRL system\The Future of KITT.pptx` — KITT project file copied to external drive
- `F:\Files of interest\SRL-Projects - Megaforce\Megaforce Specs & Research.docx` — Megaforce copied to external
- `F:\Files of interest\Recovered Documents\Wolves_Lair_Tech_Specs.pptx` — More recovered files
- `G:\My Drive\STARK-RESEARCH-LABS FOLDER\` — Google Drive sync of SRL folder

**iSCSI initiator used** (`iscsicpl.exe`) — suggests connection to network storage

### 4. Cloud Storage & Account Identification

**Email accounts configured:**
- `fred.rocba@outlook.com` (personal Outlook/Hotmail)
- `frocba@stark-research-labs.com` (SRL corporate, Azure AD tenant: `starkresearchlabs.onmicrosoft.com`)
- `fred.rocba@gmail.com` (personal Gmail, also for Google Drive)

**SIP/VoIP:**
- `SIP:frocba@stark-research-labs.com` (Skype for Business / Teams SIP)

**SharePoint/OneDrive URLs confirmed:**
- `https://starkresearchlabs-my.sharepoint.com/personal/frocba_stark-research-labs_com/Documents/` — Fred's OneDrive
- `https://starkresearchlabs-my.sharepoint.com/personal/mhill_stark-research-labs_com/Documents/` — Maria Hill's OneDrive (shared)
- `https://starkresearchlabs-my.sharepoint.com/personal/tdungan_stark-research-labs_com/Documents/` — Timothy Dungan's OneDrive (shared)
- `https://starkresearchlabs.sharepoint.com/sites/SRL-Projects/` — SRL Projects SharePoint site
- `https://starkresearchlabs.sharepoint.com/sites/SRL-Projects/Airwolf/`
- `https://starkresearchlabs.sharepoint.com/sites/SRL-Projects/Blue Thunder/`
- `https://starkresearchlabs.sharepoint.com/sites/SRL-Projects/Gunstar/`
- `https://starkresearchlabs.sharepoint.com/sites/SRL-Projects/Megaforce/`
- `https://starkresearchlabs.sharepoint.com/sites/srl-projects/gunstar/gunstar%20upgrade%20specs.xlsx`

**Google Drive observed** via multiple sync clients and `\\.\Pipe\GoogleDriveFSPipe_fredr_shell`

### 5. Key Files & Shortcuts Found

| Filename | Note |
|----------|------|
| `ROCBA Dropbox.lnk` | Shortcut to Dropbox folder |
| `SDelete.lnk` | Shortcut to SDelete |
| `SDelete.zip` | Downloaded SDelete tool |
| `SRL-EMAIL-EXPORT.lnk` | Shortcut to PST export |
| `SRL-EMAIL-EXPORT.pst` | Outlook PST email export file 🔴 |
| `backup.pst` | Another PST backup 🔴 |
| `SRL-Projects - Airwolf.lnk` | Project shortcuts |
| `SRL-Projects - Blue Thunder.lnk` | |
| `SRL-Projects - Gunstar.lnk` | |
| `Research.lnk` | Research folder shortcut |
| `TIVO Research.lnk` | |
| `fred.rocba@outlook.com Firefox Recovery Key.lnk` | Firefox recovery key |
| `iCloud Photos.lnk` | |
| `The Future of KITT.lnk` | |
| `The Future of KITT-older-version.lnk` | |
| `Timothy Dungan - New Alloy Research.lnk` | |
| `View network status and tasks.lnk` | |
| `STARK-RESEARCH-LABS FOLDER (2).lnk` | Google Drive folder |

### 6. Summary of Key Findings

1. **Fred had access to extensive SRL IP** through OneDrive/SharePoint synchronization
2. **External drives F: and G: were used** — F: contains "Files from SRL system" and "Files of interest" directories suggesting SRL data was copied to external media
3. **Google Drive mapped as G:** — with SRL project folders synced via Google Drive
4. **Multiple cloud sync services active** — OneDrive, Google Drive, Dropbox, iCloud — all logged in
5. **SRL-EMAIL-EXPORT.pst** exists — Outlook email exported (potentially by attacker or as backup)
6. **PST files found** — both `SRL-EMAIL-EXPORT.pst` and `backup.pst` (email archives)
7. **Office 365 tenant ID** = `f91eb2ca-e46d-44b6-814b-d4bbacdc5a48` (Stark Research Labs)
8. **Fred listed 3 email accounts**: work, personal Outlook, personal Gmail
9. **Executed forensic/admin tools**: cmd, powershell, regedit, disk cleanup, iSCSI (confirmed from shell activity)
10. **Office recent documents** provide a detailed timeline of which files were being worked on
