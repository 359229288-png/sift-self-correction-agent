cat > /home/moom/sift-self-correction-agent/dataset_documentation.md << 'EOF'
# Dataset Documentation — SIFT Self-Correction Agent

## 1. Data Source

All case data was obtained from the official FIND EVIL! hackathon starter resources:

- **Download Link**: https://sansorg.egnyte.com/fl/HhH7crTYT4JK
- **Folder Path**: HACKATHON-2026/Standard Forensic Case
- **Case Name**: ROCBA — The Fred Rocba Case

This is a standard digital forensic case provided by SANS Institute for the FOR500 Windows Forensic Analysis course, repurposed for the FIND EVIL! hackathon.

---

## 2. Evidence Inventory

| File | Type | Size | Description |
| :--- | :--- | :--- | :--- |
| `rocba-cdrive.e01` | Disk Image (E01 format) | 23 GB | Full disk image of Fred Rocba's Microsoft Surface system (Windows 10) |
| `Rocba-Memory.zip` | Memory Dump (compressed) | 5.3 GB (19 GB uncompressed) | RAM capture from the compromised system |
| `ROCBA-BACKGROUND.pptx` | Case Briefing | 39 MB | Official case background presentation detailing the incident, timeline, and investigation objectives |

### Note on Memory Dump
The memory dump file was partially corrupted during extraction (17 GB recovered out of 19 GB expected). The Agent detected this issue during analysis and recorded it as a limitation. Volatility3 analysis was attempted but skipped per stop-loss rules due to missing Windows ISF symbol files (symbol server returned HTTP 204).

---

## 3. Case Background

**Victim**: Fred Rocba, a relatively new engineering hire at Stark Research Labs (SRL), hired on October 24, 2020. He worked remotely from home on a Microsoft Surface system provided by SRL.

**Incident**: On November 13, 2020, while Fred was on a planned vacation at Disney World (departed November 10), his home was broken into. The intruder specifically targeted his SRL Surface system, which was left powered on and logged in.

**Investigation Objectives** (from case briefing):
1. What key projects did Fred Rocba have access to?
2. What data was stolen?
3. Where was the data transferred to?
4. How was it stolen?
5. When did the activity occur?

**System Information**:
- OS: Windows 10, fully patched
- User: Single user (fredr), with an additional IT admin account (srl-h)
- Timezone: EST5EDT (Eastern Time)
- Email: frocba@stark-research-labs.com (Office 365)
- Cloud Services Installed: OneDrive, OneDrive for Business, Dropbox, Google Drive, iCloud
- Browsers: Edge, Firefox, Chrome

---

## 4. Agent Findings Summary

The Agent analyzed the disk image using the self-correction workflow defined in `self_correction_agent_prompt.md`. All findings were validated against the mandatory self-review process (authenticity, consistency, completeness checks).

### 4.1 Confirmed Findings

| # | Finding | Source Tool |
| :--- | :--- | :--- |
| 1 | Two user profiles: `fredr` (Fred Rocba) and `srl-h` (SRL IT Administrator) | `fls` |
| 2 | Seven (7+) confidential SRL project directories under `Stark Research Labs/`, all with OneDrive `:SyncRootIdentity` streams indicating active cloud sync | `fls` |
| 3 | Core IP identified: **SUCCESS-TEST-PLAN-VIBRANIUM-ALLOY-RESULTS.docx** (created 2020-10-27, last modified 2020-11-02) | `fls` |
| 4 | Additional project files: GunStar Death Blossom Data, KITT hydrogen hybrid technology, Airwolf, Blue Thunder, Megaforce, New Alloy Research | `fls` |
| 5 | Data Testing Results directory with 15 "New World" subdirectories | `fls` |
| 6 | SDelete.zip present in Downloads (Microsoft Sysinternals secure deletion tool) with Zone.Identifier indicating web download origin | `fls` |
| 7 | Firefox recovery key file: `fred.rocba@outlook.com Firefox Recovery Key.txt` containing key `A25H VDR0 4ZK5 MKCY TZXN 4K5D 627S K1XF` | `icat` |
| 8 | WorkingFiles.zip containing confidential research papers (Chord_Spacetime.pdf, German-KITT-Specs.docx, RareEarthDeposits_Confidential.jpg, Heisenberg research PDF) | `icat` |
| 9 | Prefetch files confirm execution of: SDELETE.EXE (2 pf files → executed at least twice), RDPCLIP.EXE, MSTSC.EXE, NETSH.EXE, SCHTASKS.EXE, DROPBOXUNINSTALLER.EXE | `fls` |
| 10 | Recycle Bin deletion timeline: November 14, 2020 (04:49–14:07 UTC) — batch deletions including 100MB+ PST mail archive, multiple EXEs, PDFs, and documents | `icat` ($I metadata) |
| 11 | OneDrive and iCloud configuration strings found in partial memory dump | `strings` |

### 4.2 Inferences (Marked "To Be Verified")

| # | Inference | Supporting Evidence | Confidence |
| :--- | :--- | :--- | :--- |
| 1 | Data was exfiltrated via RDP clipboard mapping | RDPCLIP.pf + MSTSC.pf present | 🟡 High |
| 2 | Attacker used SDelete to securely erase traces | 2 SDELETE.pf files present | 🟡 High |
| 3 | Dropbox was uninstalled by the attacker to remove competing sync | DROPBOXUNINSTALLER.EXE prefetch created Nov 14 13:50 | 🟡 High |
| 4 | SCHTASKS used to establish persistence | SCHTASKS.pf present | 🟠 Medium |
| 5 | NETSH used to modify network/firewall configuration | NETSH.pf present | 🟠 Medium |
| 6 | aria2 downloader used for data exfiltration | aria-debug-6664.log present | 🟠 Medium |

### 4.3 Self-Correction Record

One misjudgment was identified and corrected during analysis:

- **Initial Finding**: All Prefetch files begin with `MAM` header instead of the expected `SCCA` signature.
- **Initial Judgment**: Prefetch files may have been obfuscated by the attacker as an anti-forensic measure.
- **Correction**: After cross-referencing multiple Prefetch files and Windows 10 documentation, confirmed that `MAM` is the standard compressed Prefetch header format in Windows 10 version 1809+. This is normal system behavior, not an attack artifact.
- **Action**: Retracted the obfuscation inference from the final report.

### 4.4 Skipped Analyses (Per Stop-Loss Rules)

| Analysis | Attempts | Reason |
| :--- | :--- | :--- |
| Volatility3 Memory Analysis | 2 | Windows ISF symbol file unavailable; symbol server returned HTTP 204 No Content |
| Registry Hives (NTUSER.DAT) | 1 | Time constraints; prioritized MFT/Prefetch/Recycle Bin analysis |
| Event Logs (Security.evtx, System.evtx) | 1 | Time constraints |
| Prefetch Execution Timestamps | 2 | MFT record number vs. inode number mismatch |

---

## 5. Data Access

All evidence files are stored in `/cases/` on the SIFT Workstation:

/cases/
├── rocba-cdrive.e01 # Disk image (23 GB, E01 format)
├── Rocba-Memory/ # Extracted memory dump directory
├── Rocba-Memory.zip # Memory dump archive (5.3 GB)
├── ROCBA-BACKGROUND.pptx # Case briefing presentation
└── memory/ # Additional memory analysis artifacts

The disk image was mounted read-only using `ewfmount` to prevent evidence spoliation. All forensic tools (`fls`, `icat`, `strings`) operate in read-only mode.
EOF
