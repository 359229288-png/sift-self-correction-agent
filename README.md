# SIFT Self-Correction Agent

A Protocol SIFT extension that teaches the AI analyst to double-check its own work — reducing hallucinations and making automated DFIR results more trustworthy.

**FIND EVIL! Hackathon 2026 Submission**

## Architecture

![Architecture Diagram](architecture.png)
This project uses **Direct Agent Extension** architecture:
 
┌─────────────────┐   SSH   ┌────────────────────┐
│ OpenClaw (Agent)│ ◄─────► │ SIFT Workstation   │
│ (Reasoning +    │         │ (Forensic Tools)   │
│ Self-Correction)│         │ IP: 192.168.192.129│
└─────────────────┘         └────────────────────┘


- **Prompt-based guardrails**: Agent instructions enforce read-only tool usage and mandatory self-correction.
- See `architecture.png` for detailed component diagram.

## Project Structure
├── self_correction_agent_prompt.md # Core agent system instructions
├── skills/ # Protocol SIFT skill packs (5 skills)
├── analysis_report.md # Full investigative report (ROCBA-001)
├── accuracy_report.md # Accuracy self-assessment
├── execution_log.md # Structured tool execution log
├── architecture.png # Architecture diagram
├── README.md
└── LICENSE # MIT License

## Setup & Try-It-Out Instructions

### Prerequisites
- SIFT Workstation VM (download from https://www.sans.org/tools/sift-workstation/)
- OpenClaw or another agentic framework
- Two VMs networked together (bridged mode recommended)
- Case data in `/cases/` on SIFT

### Step-by-Step
1. **Start SIFT Workstation VM**  
   Login: `sansforensics` / `forensics`

2. **Install Protocol SIFT core components**  
   ```bash
   curl -fsSL https://raw.githubusercontent.com/teamdfir/protocol-sift/main/install.sh | bash
3. Configure SSH access from OpenClaw to SIFT

    bash
    ssh-keygen -t ed25519
    ssh-copy-id sansforensics@<SIFT_IP>
4. Copy skill packs to your agent machine

    bash
    scp -r sansforensics@<SIFT_IP>:/home/sansforensics/.claude/skills ~/protocol-sift-skills/
5. Place case data in SIFT's /cases/
    Download Standard Forensic Case from the FIND EVIL! resources page.

6. Load the agent prompt
    Use self_correction_agent_prompt.md as the system instruction for your agent.

7. Run analysis
    Instruct your agent to SSH to SIFT and analyze the case data in /cases/.

## Key Features
 ·Self-Correction Loop: Agent checks its own findings for hallucinations, inconsistencies, and missed artifacts before finalizing a report.
 ·Honest Uncertainty: Confirmed findings are clearly distinguished from inferences; skipped analyses are honestly recorded.
 ·Experimental Methodology: Inspired by data science competition workflows — control variables, baseline comparison, iterative testing.

## Built With
 ·OpenClaw (Agent Framework)
 ·SIFT Workstation (Forensic Platform)
 ·Protocol SIFT (AI-DFIR Integration)
 ·Sleuth Kit (fls, icat)
 ·Python (pptx parsing, data extraction)
 ·Bash

## Author
  Cheng Lin — Solo Participant, FIND EVIL! 2026

## License
  MIT — see LICENSE file

## Limitations & Future Work

### Known Limitations

1. **Prompt-Level Guardrails**: The current architecture uses prompt-based restrictions to enforce read-only tool usage. While the Agent confirmed no write commands were executed during testing, a maliciously crafted prompt could theoretically bypass these restrictions. This is honestly documented in the accuracy report.

2. **Single-Agent Architecture**: The current implementation uses a single Agent for both analysis and self-review. A multi-agent architecture — where one agent analyzes and a second independently verifies — could provide stronger separation of concerns.

3. **Skipped Analyses**: Three analysis dimensions (Event Logs, memory analysis via Volatility, and Prefetch timestamps) were skipped per stop-loss rules. Memory analysis was blocked by missing Windows ISF symbol files (symbol server returned HTTP 204). Registry hive analysis was completed in a supplementary update (2026-05-31). These gaps are honestly recorded.

4. **Manual SSH Setup**: The current workflow requires manual SSH configuration. Future versions could automate the connection setup through MCP-based agent-to-workstation integration.

### Planned Improvements

1. **Custom MCP Server Architecture**: Migrate from Direct Agent Extension to a Custom MCP Server. This would expose only type-safe, read-only forensic functions — making evidence spoliation architecturally impossible rather than prompt-dependent.

2. **Multi-Agent Decomposition**: Implement a two-agent system: Analyzer Agent + Verifier Agent. The Verifier independently checks the Analyzer's findings, providing stronger self-correction guarantees.

3. **Expanded Analysis Coverage**: Complete Event Log parsing, Volatility memory analysis (once symbol files are available), and Prefetch timestamp extraction.

4. **Automated Evidence Integrity Verification**: Add cryptographic hashing of evidence files before and after analysis to provide tamper-proof chain of custody documentation.

## Demo Video
🎥 [Watch the 5-minute demo](https://youtube.com/placeholder) *(link coming soon)*
