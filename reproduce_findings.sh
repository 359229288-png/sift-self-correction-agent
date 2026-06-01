#!/bin/bash
# reproduce_findings.sh — ROCBA-001 Evidence Reproduction Script
#
# Reproduces all key findings from the ROCBA-001 investigation on a SIFT
# Workstation. Uses the simplest possible sleuthkit commands (no complex
# path probing or partition-offset guessing).
#
# Prerequisites:
#   - SIFT Workstation (or any Linux with ewftools + sleuthkit + python3)
#   - E01 image at /cases/rocba-cdrive.e01
#
# Output: timestamped directory under /cases/reproduce_output/
#         Summary printed to stdout; raw tool output saved per step.
#
# Usage:
#   sudo ./reproduce_findings.sh

set -euo pipefail

E01="/cases/rocba-cdrive.e01"
EWF_MNT="/mnt/ewf_rocba"
OUT_BASE="/cases/reproduce_output"
TS=$(date +%Y%m%d_%H%M%S)
OUT="${OUT_BASE}/${TS}"
mkdir -p "${OUT}"

echo "=== ROCBA-001 Reproduction — ${TS} ===" | tee "${OUT}/summary.txt"
echo "E01: ${E01}" | tee -a "${OUT}/summary.txt"

# ====== Step 0: Verify E01 exists ======
[ -f "${E01}" ] || { echo "FATAL: E01 not found"; exit 1; }

# ====== Step 1: Mount via ewfmount (no sudo needed for ewfmount) ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 1: Mount E01 ===" | tee -a "${OUT}/summary.txt"
mkdir -p "${EWF_MNT}"
ewfmount "${E01}" "${EWF_MNT}" 2>&1 | tee "${OUT}/01_ewfmount.txt"
DEV="${EWF_MNT}/ewf1"
[ -f "${DEV}" ] || { echo "FATAL: ewfmount failed"; exit 1; }
echo "OK: ${DEV}" | tee -a "${OUT}/summary.txt"

# ====== Step 2: Root directory listing (sanity check, no offset = no partition table needed) ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 2: Root directory ===" | tee -a "${OUT}/summary.txt"
sudo fls -f ntfs "${DEV}" 2>/dev/null > "${OUT}/02_root_dir.txt" || echo "fls root failed" >> "${OUT}/02_root_dir.txt"
ROOT_COUNT=$(wc -l < "${OUT}/02_root_dir.txt" 2>/dev/null || echo 0)
echo "Root entries: ${ROOT_COUNT}" | tee -a "${OUT}/summary.txt"

# ====== Step 3: Full recursive listing (one grep pass per pattern) ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 3: Recursive fls ===" | tee -a "${OUT}/summary.txt"
sudo fls -f ntfs -r "${DEV}" 2>/dev/null > "${OUT}/03_fls_recursive.txt" || echo "fls recursive failed" >> "${OUT}/03_fls_recursive.txt"
echo "Total file entries: $(wc -l < "${OUT}/03_fls_recursive.txt")" | tee -a "${OUT}/summary.txt"

# ====== Step 4: SRL project directories (grep the recursive output) ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 4: SRL Classified Projects ===" | tee -a "${OUT}/summary.txt"
{
    echo "--- Project directories ---"
    grep -iE "(Vibranium|GunStar|KITT|Airwolf|Blue.?Thunder|Megaforce|Stark.?Research|New.?Alloy|Ion.?Thruster)" "${OUT}/03_fls_recursive.txt" 2>/dev/null || echo "(none found)"
    echo ""
    echo "--- Download artifacts ---"
    grep -iE "(SDelete\.zip|WorkingFiles|DropboxInstaller|Firefox.*key)" "${OUT}/03_fls_recursive.txt" 2>/dev/null || echo "(none found)"
} > "${OUT}/04_projects.txt"
cat "${OUT}/04_projects.txt" | tee -a "${OUT}/summary.txt"
echo "" >> "${OUT}/summary.txt"
echo "Project count: $(grep -iE '(Vibranium|GunStar|KITT|Airwolf|Blue.?Thunder|Megaforce)' "${OUT}/04_projects.txt" | wc -l)" | tee -a "${OUT}/summary.txt"

# ====== Step 5: Prefetch files ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 5: Prefetch Files ===" | tee -a "${OUT}/summary.txt"
grep -i "\.pf$" "${OUT}/03_fls_recursive.txt" 2>/dev/null > "${OUT}/05_all_prefetch.txt" || echo "(no .pf files)" > "${OUT}/05_all_prefetch.txt"
echo "Total Prefetch files: $(wc -l < "${OUT}/05_all_prefetch.txt")" | tee -a "${OUT}/summary.txt"

# Key executables
echo "" > "${OUT}/05_key_prefetch.txt"
for exe in SDELETE RDPCLIP MSTSC SCHTASKS NETSH REGSVR32 DROPBOXUNINSTALLER RUNDLL32; do
    MATCH=$(grep -i "${exe}" "${OUT}/05_all_prefetch.txt" 2>/dev/null || true)
    if [ -n "${MATCH}" ]; then
        echo "${MATCH}" >> "${OUT}/05_key_prefetch.txt"
    fi
done
echo "Key executables with Prefetch records:" | tee -a "${OUT}/summary.txt"
awk '{print "  " $NF}' "${OUT}/05_key_prefetch.txt" 2>/dev/null | sort -u | tee -a "${OUT}/summary.txt"

# ====== Step 6: istat on key Prefetch files (find inodes from recursive listing) ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 6: Prefetch Timestamps (istat) ===" | tee -a "${OUT}/summary.txt"
echo "" > "${OUT}/06_istat_results.txt"
for exe in SDELETE RDPCLIP MSTSC SCHTASKS NETSH REGSVR32 DROPBOXUNINSTALLER RUNDLL32; do
    grep -i "${exe}" "${OUT}/05_all_prefetch.txt" | while read -r line; do
        INODE=$(echo "${line}" | awk '{print $2}' | tr -d ':-')
        FNAME=$(echo "${line}" | awk '{print $NF}')
        if [ -n "${INODE}" ]; then
            echo "=== ${FNAME} (inode ${INODE}) ===" >> "${OUT}/06_istat_results.txt"
            sudo istat -f ntfs "${DEV}" "${INODE}" >> "${OUT}/06_istat_results.txt" 2>/dev/null || echo "(istat failed)" >> "${OUT}/06_istat_results.txt"
            echo "" >> "${OUT}/06_istat_results.txt"
        fi
    done
done
# Extract just the created timestamps for the summary
echo "Created timestamps:" | tee -a "${OUT}/summary.txt"
grep -B1 "Created:" "${OUT}/06_istat_results.txt" | grep -E "(inode|Created:)" | paste - - | tee -a "${OUT}/summary.txt" || echo "(no istat results)" | tee -a "${OUT}/summary.txt"

# ====== Step 7: Prefetch MAM header check ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 7: Prefetch MAM Header ===" | tee -a "${OUT}/summary.txt"
PF_SAMPLE=$(grep -i "CHROME.*\.pf" "${OUT}/05_all_prefetch.txt" | head -1 | awk '{print $2}' | tr -d ':-')
if [ -n "${PF_SAMPLE}" ]; then
    HEADER=$(sudo icat -f ntfs "${DEV}" "${PF_SAMPLE}" 2>/dev/null | head -c 4 || true)
    echo "Header: $(echo -n "${HEADER}" | xxd | head -1)" | tee -a "${OUT}/summary.txt"
    if [ "${HEADER}" = "MAM" ]; then
        echo "→ MAM = compressed Prefetch (Win10 1809+, normal behavior)" | tee -a "${OUT}/summary.txt"
    elif [ "${HEADER}" = "SCCA" ]; then
        echo "→ SCCA = uncompressed Prefetch (pre-1809)" | tee -a "${OUT}/summary.txt"
    else
        echo "→ Unexpected header" | tee -a "${OUT}/summary.txt"
    fi
fi

# ====== Step 8: Recycle Bin ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 8: Recycle Bin ===" | tee -a "${OUT}/summary.txt"
grep -i "\\\$R\|\\\$I" "${OUT}/03_fls_recursive.txt" 2>/dev/null > "${OUT}/08_recycle_bin.txt" || echo "(none)" > "${OUT}/08_recycle_bin.txt"
echo "Recycle Bin entries: $(wc -l < "${OUT}/08_recycle_bin.txt")" | tee -a "${OUT}/summary.txt"

# Extract $I file metadata
echo "" > "${OUT}/08_recycle_metadata.txt"
grep -i "\\\$I" "${OUT}/08_recycle_bin.txt" | head -10 | while read -r line; do
    INODE=$(echo "${line}" | awk '{print $2}' | tr -d ':-')
    FNAME=$(echo "${line}" | awk '{print $NF}')
    if [ -n "${INODE}" ]; then
        echo "--- ${FNAME} (inode ${INODE}) ---" >> "${OUT}/08_recycle_metadata.txt"
        sudo icat -f ntfs "${DEV}" "${INODE}" 2>/dev/null | strings -e l | head -5 >> "${OUT}/08_recycle_metadata.txt" || true
    fi
done
echo "First $I metadata:" | tee -a "${OUT}/summary.txt"
head -10 "${OUT}/08_recycle_metadata.txt" 2>/dev/null | tee -a "${OUT}/summary.txt"

# ====== Step 9: Registry NTUSER.DAT location ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 9: NTUSER.DAT Location ===" | tee -a "${OUT}/summary.txt"
grep -i "NTUSER.DAT" "${OUT}/03_fls_recursive.txt" 2>/dev/null > "${OUT}/09_ntuser_list.txt" || echo "(none)" > "${OUT}/09_ntuser_list.txt"
cat "${OUT}/09_ntuser_list.txt" | tee -a "${OUT}/summary.txt"

# ====== Step 10: Event Log check ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=== Step 10: Event Log Check ===" | tee -a "${OUT}/summary.txt"
grep -i "\.evtx" "${OUT}/03_fls_recursive.txt" 2>/dev/null | head -10 > "${OUT}/10_evtx_list.txt"
cat "${OUT}/10_evtx_list.txt" | tee -a "${OUT}/summary.txt"

# ====== Summary ======
echo "" | tee -a "${OUT}/summary.txt"
echo "=============================================" | tee -a "${OUT}/summary.txt
echo "  REPRODUCTION COMPLETE" | tee -a "${OUT}/summary.txt
echo "  Output: ${OUT}/" | tee -a "${OUT}/summary.txt
echo "=============================================" | tee -a "${OUT}/summary.txt
