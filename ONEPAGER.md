# SIFT Self-Correction Agent

An autonomous digital forensics agent that double-checks its own work.

## The Problem

AI agents make mistakes — they hallucinate, jump to conclusions, and miss evidence. In digital forensics, an undetected error means an innocent person accused or a guilty one walking free. Existing AI-DFIR tools don't systematically verify their own findings before reporting them.

## Our Solution

A three-phase workflow — **Investigate → Self-Correct → Report** — that forces the agent to audit every finding before it enters the final report. Mandatory authenticity checks catch hallucinations (like a false "obfuscation" claim), consistency checks resolve timeline conflicts, and completeness checks flag what's still missing. The result: verified findings are clearly separated from inferences, and every gap is honestly documented.

## Key Findings (ROCBA-001)

- **Data stolen** from 8+ classified SRL projects (Vibranium Alloy, GunStar, KITT AI, Airwolf, Blue Thunder, Megaforce, and others)
- **Intruder covered their tracks** in a 20-minute cleanup window (13:42–14:01 UTC) using SDelete, Dropbox uninstall, NETSH, and DLL registration
- **Exfiltration confirmed** via external drive (`F:\`) and cloud sync (`G:\`), recovered from Registry hive data
- **18 verified findings**, 4 corroborated across multiple sources, 3 clearly labeled inferences — **89% accuracy confidence**
- **Evidence gaps honestly documented**: Event Logs (NTFS corruption), memory analysis (missing Volatility symbols), YARA (time budget)

## Self-Correction in Action

The agent initially flagged Prefetch `.pf` files as "obfuscated by the attacker" because they started with `MAM` instead of the expected `SCCA` header. Before filing the finding, it cross-checked multiple files, researched Windows 10 behavior, and discovered that `MAM` is Microsoft's compressed Prefetch format (standard since 1809). The "obfuscation" inference was retracted. The error never reached the final report.

## Architecture

The agent runs on OpenClaw and issues read-only SSH commands to a SIFT Workstation. A custom agent prompt enforces mandatory self-correction checks at each phase. *(See `architecture.png` for the component diagram.)*

## Why This Matters

AI makes DFIR faster, but speed without accuracy is dangerous. The self-correction loop turns an unreliable "first draft" agent into one that catches its own mistakes — and honestly reports what it still can't verify. Honest AI is more trustworthy than perfect AI that never admits uncertainty.

---

**Full reports**: [github.com/cheng-lin-max/sift-self-correction-agent](https://github.com/cheng-lin-max/sift-self-correction-agent)  
**FIND EVIL! 2026** • Solo participant: Cheng Lin • 5-minute demo video (link in README)
