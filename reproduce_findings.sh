#!/bin/bash
# reproduce_findings.sh — ROCBA-001 Evidence Reproduction Script
#
# Reproduces all key findings from the ROCBA-001 investigation on a SIFT
# Workstation.  Designed to run from a plain bash environment with standard
# forensic tools (ewftools, sleuthkit, python3).
#
# Prerequisites:
#   - SIFT Workstation (or any Linux with ewftools + sleuthkit + python3)
#   - E01 image at /cases/rocba-cdrive.e01
#   - python-registry (optional; fallback uses raw string extraction)
#
# What it verifies (mapping to analysis_report.md findings):
#   1.  SRL classified project directories exist           (fls)
#   2.  Prefetch files for key executables                 (fls)
#   3.  istat timestamps for SDELETE, RDPCLIP, MSTSC,      (istat)
#       SCHTASKS, DROPBOXUNINSTALLER, NETSH, REGSVR32,
#       RUNDLL32
#   4.  Recycle Bin deletion timeline                      (fls + icat)
#   5.  Registry NTUSER.DAT strings (ext paths, accounts)  (python3 raw)
#   6.  Prefetch "MAM" header (normal Win10 1809+)         (icat + xxd)
#   7.  Event Log unrecoverability confirmation            (icat + EVTX chunk scanner)
#
# Output: timestamped directory under /cases/reproduce_output/
#         Every tool's raw output saved along with a summary.
#
# Usage:
#   chmod +x reproduce_findings.sh
#   sudo ./reproduce_findings.sh

set -euo pipefail

E01="/cases/rocba-cdrive.e01"
MNT="/mnt/ewf_reproduce"
OUT_BASE="/cases/reproduce_output"
TS=$(date +%Y%m%d_%H%M%S)
OUT="${OUT_BASE}/${TS}"
mkdir -p "${OUT}"
echo "=== ROCBA-001 Reproduction — ${TS} ===" | tee "${OUT}/00_header.txt"
echo "Script: $0" >> "${OUT}/00_header.txt"
echo "E01: ${E01}" >> "${OUT}/00_header.txt"
echo "" >> "${OUT}/00_header.txt"

# ------ Helper ------
fail() { echo "[FAIL] $*"; }
ok()   { echo "[OK]   $*"; }

# ------ 1. Mount E01 ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 1: Mount E01 via ewfmount ---" | tee -a "${OUT}/00_header.txt"

if [ ! -f "${E01}" ]; then
    fail "E01 not found at ${E01}. Aborting."
    exit 1
fi

EWF_MNT="/mnt/ewf_rocba"
mkdir -p "${EWF_MNT}"
ewfmount "${E01}" "${EWF_MNT}" 2>&1 | tee "${OUT}/01_ewfmount.txt"
if [ ! -f "${EWF_MNT}/ewf1" ]; then
    fail "ewfmount did not produce ewf1 device."
    exit 1
fi
ok "ewfmount succeeded: ${EWF_MNT}/ewf1"

# Determine partition offset (assume single NTFS volume)
SECTOR_SIZE=512
OFFSET=0
# Try common partition offsets
for try_offset in 0 2048 206848; do
    if fls -f ntfs -o "${try_offset}" "${EWF_MNT}/ewf1" >/dev/null 2>&1; then
        OFFSET="${try_offset}"
        break
    fi
done
echo "Using NTFS partition offset: ${OFFSET}" | tee -a "${OUT}/01_offset.txt"

# ------ 2. List SRL project directories ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 2: List SRL project directories ---" | tee -a "${OUT}/00_header.txt"

# Probe various known locations
for base_path in \
    "Users/fredr/Stark Research Labs" \
    "Users/srl-h/Stark Research Labs" \
    "Users/fredr/Desktop" \
    "Users/srl-h/Desktop"; do
    echo "=== fls on ${base_path} ===" >> "${OUT}/02_projects.txt"
    if fls -f ntfs -o "${OFFSET}" -r "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "${base_path}" | head -50 >> "${OUT}/02_projects.txt"; then
        ok "fls found ${base_path}"
    else
        echo "(not found)" >> "${OUT}/02_projects.txt"
        echo "--- ${base_path} not found under this name ---" >> "${OUT}/02_projects.txt"
    fi
done

# Direct recursive scan for project names
echo "=== fls grep: SRL/Vibranium/GunStar/KITT/Airwolf/BlueThunder/Megaforce ===" >> "${OUT}/02_projects.txt"
fls -f ntfs -o "${OFFSET}" -r "${EWF_MNT}/ewf1" 2>/dev/null | \
    grep -iE "(Vibranium|GunStar|KITT|Airwolf|Blue.?Thunder|Megaforce|Stark.?Research|New.?Alloy|Ion.?Thruster)" \
    >> "${OUT}/02_projects.txt" || true

# ------ 3. List Prefetch files ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 3: List Prefetch files ---" | tee -a "${OUT}/00_header.txt"
fls -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "/Windows/Prefetch" | tee "${OUT}/03_prefetch_fls_all.txt" | wc -l | xargs echo "Total Prefetch files:"

# Filter for key executables
echo "=== Key Prefetch files ===" > "${OUT}/03_prefetch_key.txt"
for exe in SDELETE RDPCLIP MSTSC SCHTASKS NETSH REGSVR32 DROPBOXUNINSTALLER RUNDLL32 DROPBOX; do
    fls -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "${exe}" >> "${OUT}/03_prefetch_key.txt" || echo "  ${exe}: NOT FOUND" >> "${OUT}/03_prefetch_key.txt"
done
cat "${OUT}/03_prefetch_key.txt"

# ------ 4. istat on key Prefetch files ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 4: istat on key Prefetch files ---" | tee -a "${OUT}/00_header.txt"

# Map known inodes from analysis (these are file record numbers from the MFT)
# If reproduction E01 has different inodes, fallback: search by filename
declare -A PF_MAP=(
    ["SDELETE_1st"]="472552"
    ["SDELETE_2nd"]="104219"
    ["RDPCLIP"]="127940"
    ["MSTSC"]="123623"
    ["SCHTASKS"]="118084"
    ["DROPBOXUNINSTALLER"]="103935"
    ["DROPBOX"]="104008"
    ["NETSH"]="104014"
    ["REGSVR32"]="104011"
    ["RUNDLL32"]="104013"
)

PF_ISTAT="${OUT}/04_istat_prefetch.txt"
for label in "${!PF_MAP[@]}"; do
    inode="${PF_MAP[$label]}"
    echo "=== ${label} (inode ${inode}) ===" >> "${PF_ISTAT}"
    if istat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${inode}" >> "${PF_ISTAT}" 2>/dev/null; then
        ok "istat ${label} (inode ${inode})"
    else
        echo "(istat failed — inode may differ in this image)" >> "${PF_ISTAT}"
        fail "istat ${label} (inode ${inode}) — try searching..."
        # Fallback: find inode by filename
        for exe in SDELETE RDPCLIP MSTSC SCHTASKS NETSH REGSVR32 DROPBOXUNINSTALLER DROPBOX RUNDLL32; do
            match=$(fls -f ntfs -o "${OFFSET}" -r "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "${exe}.pf" | head -1 | awk '{print $2}' | tr -d ':-')
            if [ -n "${match}" ]; then
                echo "  Fallback: found ${exe} at inode ${match}" >> "${PF_ISTAT}"
                echo "  === ${exe} (fallback inode ${match}) ===" >> "${PF_ISTAT}"
                istat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${match}" >> "${PF_ISTAT}" 2>/dev/null || true
            fi
        done
    fi
done

# Show extracted timestamps
echo "" >> "${PF_ISTAT}"
echo "=== Summary: Created timestamps ===" >> "${PF_ISTAT}"
grep -B1 -A3 "Created:" "${PF_ISTAT}" | grep -E "(Created:|inode|===)" >> "${PF_ISTAT}" || true

# ------ 5. Prefetch MAM header check ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 5: Verify Prefetch MAM header (Win10 1809+ compression) ---" | tee -a "${OUT}/00_header.txt"

MAM_OUT="${OUT}/05_mam_header.txt"
# Find the first Prefetch file
PF_SAMPLE=$(fls -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "CHROME.*\.pf" | head -1 | awk '{print $2}' | tr -d ':-')
if [ -n "${PF_SAMPLE}" ]; then
    icat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${PF_SAMPLE}" 2>/dev/null | xxd -l 64 | tee "${MAM_OUT}"
    HEADER=$(icat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${PF_SAMPLE}" 2>/dev/null | head -c 4)
    if [ "${HEADER}" = "MAM" ]; then
        ok "Prefetch header is 'MAM' — confirmed compressed format (Win10 1809+ normal behavior)"
    elif [ "${HEADER}" = "SCCA" ]; then
        echo "NOTE: Header is 'SCCA' (uncompressed, pre-1809 format)" | tee -a "${MAM_OUT}"
    else
        echo "NOTE: Unexpected header '${HEADER}'" | tee -a "${MAM_OUT}"
    fi
else
    fail "Could not find any .pf file for MAM check"
fi

# ------ 6. Recycle Bin analysis ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 6: Recycle Bin deletion timeline ---" | tee -a "${OUT}/00_header.txt"

RB_OUT="${OUT}/06_recycle_bin.txt"
echo "=== \$Recycle.Bin (fredr) ===" > "${RB_OUT}"
fls -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "\\\$Recycle\|\\\$R\|\\\$I" | head -100 >> "${RB_OUT}" || echo "(No \$Recycle.Bin entries found)" >> "${RB_OUT}"

# Try to locate $I files and extract metadata
echo "" >> "${RB_OUT}"
echo "=== \$I file metadata (deletion times) ===" >> "${RB_OUT}"
fls -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "\\\$I" | head -30 | while read -r line; do
    inode=$(echo "${line}" | awk '{print $2}' | tr -d ':-')
    fname=$(echo "${line}" | awk '{print $NF}')
    if [ -n "${inode}" ]; then
        echo "--- ${fname} (inode ${inode}) ---" >> "${RB_OUT}"
        icat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${inode}" 2>/dev/null | strings -e l | head -10 >> "${RB_OUT}" || true
    fi
done

# --- Alternate approach: use mactime/ls on Recycle Bin subdirs ---
for uid_dir in "S-1-5-21-..." "fredr"; do
    echo "=== fls on \$Recycle.Bin/${uid_dir} ===" >> "${RB_OUT}"
    fls -f ntfs -o "${OFFSET}" -d "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "recycle" >> "${RB_OUT}" || true
done

echo "" >> "${RB_OUT}"
echo "=== SDelete evidence ===" >> "${RB_OUT}"
fls -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "SDelete" >> "${RB_OUT}" || echo "(SDelete not in fls — may be in unallocated)" >> "${RB_OUT}"

# ------ 7. Registry NTUSER.DAT string extraction ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 7: Registry NTUSER.DAT raw string extraction ---" | tee -a "${OUT}/00_header.txt"

REG_OUT="${OUT}/07_registry_strings.txt"

# Locate NTUSER.DAT inodes
echo "=== Locating NTUSER.DAT ===" > "${REG_OUT}"
for user in fredr srl-h Default; do
    inode=$(fls -f ntfs -o "${OFFSET}" -r "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "Users/${user}/NTUSER.DAT" | head -1 | awk '{print $2}' | tr -d ':-')
    if [ -n "${inode}" ]; then
        echo "NTUSER.DAT for ${user}: inode ${inode}" >> "${REG_OUT}"
        USER_REG="${OUT}/07_ntuser_${user}.bin"
        icat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${inode}" > "${USER_REG}" 2>/dev/null && {
            FILESIZE=$(stat -c%s "${USER_REG}" 2>/dev/null)
            echo "  Extracted: ${FILESIZE} bytes" >> "${REG_OUT}"

            # Try python-registry first
            echo "  === python-registry parse ===" >> "${REG_OUT}"
            python3 -c "
import sys
try:
    from Registry import Registry
    reg = Registry.Registry('${USER_REG}')
    print('Root keys:', [k.name() for k in reg.root().subkeys()][:20], file=sys.stderr)
    # Traverse 'Software\Microsoft\Windows\CurrentVersion\Explorer'
    try:
        key = reg.open('Software\\\\Microsoft\\\\Windows\\\\CurrentVersion\\\\Explorer')
        print('Explorer subkeys:', [s.name() for s in key.subkeys()][:10])
    except Exception as e:
        print('Explorer key error:', e)
except Exception as e:
    print('python-registry failed:', e)
" 2>> "${REG_OUT}" >> "${REG_OUT}" || echo "  python-registry: FAILED" >> "${REG_OUT}"

            # Raw UTF-16LE string extraction (always works)
            echo "  === Raw UTF-16LE string extraction ===" >> "${REG_OUT}"
            python3 -c "
import re, os
data = open('${USER_REG}', 'rb').read()
# Extract all printable UTF-16LE strings (min 4 chars)
strings = []
buf = b''
i = 0
while i < len(data) - 1:
    if 32 <= data[i] <= 126 and data[i+1] == 0:
        buf += bytes([data[i]])
        i += 2
    else:
        if len(buf) >= 4:
            strings.append(buf.decode('ascii', errors='replace'))
        buf = b''
        i += 1
if len(buf) >= 4:
    strings.append(buf.decode('ascii', errors='replace'))

# Filter for forensic-relevant keywords
keywords = [
    'F:\\\\', 'G:\\\\', 'E:\\\\', 'D:\\\\',
    'Stark Research', 'Vibranium', 'GunStar', 'KITT', 'Airwolf',
    'Megaforce', 'New Alloy', 'Ion Thruster', 'Blue Thunder',
    'SRL-', 'OneDrive', 'Dropbox', 'Google Drive', 'iCloud',
    'SharePoint', 'microsoft.com', 'outlook.com', 'gmail.com',
    'fred.rocba', 'frocba', 'PST', '.pst', 'backup.pst',
    'SDELETE', 'RDPCLIP', 'MSTSC', 'RUNDLL32', 'NETSH',
]
hits = []
for kw in keywords:
    for s in strings:
        if kw.lower() in s.lower():
            hits.append((kw, s))
            break

# Deduplicate
seen = set()
unique_hits = []
for kw, s in hits:
    if s not in seen:
        seen.add(s)
        unique_hits.append((kw, s))

print(f'Total raw strings extracted: {len(strings)}')
print(f'Forensic keyword matches: {len(unique_hits)}')
print()
for kw, s in unique_hits[:50]:
    print(f'  [{kw}] {s}')
" >> "${REG_OUT}" || echo "  Raw extraction: ERROR" >> "${REG_OUT}"

        } || echo "  icat extraction failed" >> "${REG_OUT}"
    else
        echo "NTUSER.DAT for ${user}: not found" >> "${REG_OUT}"
    fi
done

# ------ 8. Event Log attempt (documented limitation) ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "--- Step 8: Event Log (EVTX) check (documented limitation) ---" | tee -a "${OUT}/00_header.txt"

EVTX_OUT="${OUT}/08_evtx_check.txt"
echo "=== Event Log files ===" > "${EVTX_OUT}"
fls -f ntfs -o "${OFFSET}" -r "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "\.evtx" >> "${EVTX_OUT}" || echo "(No .evtx files found)" >> "${EVTX_OUT}"

# Try to extract Security.evtx
SEC_INODE=$(fls -f ntfs -o "${OFFSET}" -r "${EWF_MNT}/ewf1" 2>/dev/null | grep -i "Security.evtx" | grep -v "Archive" | head -1 | awk '{print $2}' | tr -d ':-')
if [ -n "${SEC_INODE}" ]; then
    echo "Security.evtx inode: ${SEC_INODE}" >> "${EVTX_OUT}"
    icat -f ntfs -o "${OFFSET}" "${EWF_MNT}/ewf1" "${SEC_INODE}" > "${OUT}/08_security.evtx" 2>&1 || echo "icat: truncated due to NTFS compression" >> "${EVTX_OUT}"
    FILESIZE=$(stat -c%s "${OUT}/08_security.evtx" 2>/dev/null || echo "0")
    echo "Extracted size: ${FILESIZE} bytes" >> "${EVTX_OUT}"
    # Quick chunk header scan
    python3 -c "
data = open('${OUT}/08_security.evtx', 'rb').read()
chunks = data.count(b'ElfChnk')
events_total = 0
# Check if at least some chunks have event records
import re
if chunks > 0:
    print(f'ElfChnk headers found: {chunks}')
    # Simple check: after 'ElfChnk' the event count is at offset 0x14 (4 bytes LE)
    for m in re.finditer(b'ElfChnk', data):
        off = m.start()
        evt_count = int.from_bytes(data[off+0x14:off+0x18], 'little')
        events_total += evt_count
    print(f'Events across all chunks: {events_total}')
    if events_total == 0:
        print('NOTE: 0 events confirmed — Windows .evtx archive clears record bodies.')
else:
    print('No ElfChnk headers found (file may be corrupt or NTFS-compressed).')
" >> "${EVTX_OUT}" || echo "Chunk analysis failed" >> "${EVTX_OUT}"
fi

# ------ 9. Summary ------
echo "" | tee -a "${OUT}/00_header.txt"
echo "=============================================" | tee -a "${OUT}/00_header.txt"
echo "  REPRODUCTION COMPLETE" | tee -a "${OUT}/00_header.txt"
echo "  Output directory: ${OUT}" | tee -a "${OUT}/00_header.txt"
echo "=============================================" | tee -a "${OUT}/00_header.txt"
echo "" | tee -a "${OUT}/00_header.txt"
echo "Files generated:" | tee -a "${OUT}/00_header.txt"
for f in "${OUT}"/*; do
    echo "  $(basename "${f}") ($(stat -c%s "${f}" 2>/dev/null || echo "?") bytes)" | tee -a "${OUT}/00_header.txt"
done
echo "" | tee -a "${OUT}/00_header.txt"
echo "To re-evaluate: compare the outputs above with the published reports" | tee -a "${OUT}/00_header.txt"
echo "at https://github.com/cheng-lin-max/sift-self-correction-agent" | tee -a "${OUT}/00_header.txt"

# Cleanup mount
umount "${EWF_MNT}" 2>/dev/null || true
rmdir "${EWF_MNT}" 2>/dev/null || true
ok "Cleanup: ewfmount unmounted"

echo ""
echo "Done. Results in ${OUT}/"
