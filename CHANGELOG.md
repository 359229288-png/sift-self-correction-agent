# SIFT - Self-Correction Agent 项目日志

## 2026-05-28 项目立项

### 初始状态
- 比赛平台：Devpost - FIND EVIL!
- 剩余时间：约19天（截止 ~2026-06-16）
- 参赛形式：单人

### 已完成准备
- ✅ SIFT Workstation 虚拟机已安装运行（192.168.192.129）
- ✅ Protocol SIFT 核心组件已安装（技能包×5、分析脚本、案例模板）
- ✅ 5个技能包已复制到 OpenClaw：`~/protocol-sift-skills/`
  1. memory-analysis（内存取证，Volatility 3）
  2. plaso-timeline（时间线生成，Plaso）
  3. sleuthkit（磁盘分析，Sleuth Kit）
  4. windows-artifacts（Windows 取证，EZ Tools / 事件日志）
  5. yara-hunting（恶意软件扫描，YARA）
- ✅ 两台虚拟机网络互通（桥接模式）
- ✅ SSH 免密登录配置完成

### 注意
- `~/self_correction_agent_prompt.md` 不存在，需要创建
- `~/projects/` 目录不存在，已创建 `projects/sift/`

## 2026-05-31 22:36 — Registry Hives Analysis (NTUSER.DAT)

**新增Registry分析补充** — 根据用户要求，补充之前跳过的NTUSER.DAT分析

### 执行过程
1. 挂载E01磁盘镜像 (`ewfmount rocba-cdrive.e01 /mnt/ewf2/`)
2. 定位NTUSER.DAT（fredr用户 inode=154911）
3. 使用python-registry解析（部分结构损坏）
4. 用二进制utf-16le字符串提取方式获取全部用户活动数据

### 关键发现
- **外部驱动器F:和G:包含SRL项目文件副本** 🔴

## 2026-06-02 13:52 — 全量报告推送 GitHub

**操作**：将 ROCBA-001 完整取证分析结果推送到 GitHub

### 推送内容
- **远程已有**（英文版）：
  - README.md — 项目主页
  - ONEPAGER.md — 项目一览
  - analysis_report.md — 英文分析报告
  - analysis_report.cn.md — 中文分析报告
  - accuracy_report.md — 英文准确性报告
  - execution_log.md — 执行日志
  - reproduce_findings.sh — 可重现性脚本
  - self_correction_agent_prompt.md — Agent Prompt
  - dataset_documentation.md — 数据集文档
  - LICENSE
  - skills/ — 5个技能包
  - architecture.png, attack_timeline.png — 架构图
- **本次新提交**：
  - CHANGELOG.md — 项目日志
  - notes/registry-analysis.md — Registry 补充分析

### 仓库
- `git@github.com:cheng-lin-max/sift-self-correction-agent.git`
- 分支: main
- Commit: 2185893
  - `F:\Files from SRL system\The Future of KITT.pptx`
  - `F:\Files of interest\...` (Megaforce, Recovered Documents)
  - `G:\My Drive\STARK-RESEARCH-LABS FOLDER\` (Google Drive同步)
- **PST邮件导出文件**: `SRL-EMAIL-EXPORT.pst` 和 `backup.pst`
- **3个邮箱配置**: fred.rocba@outlook.com, frocba@stark-research-labs.com, fred.rocba@gmail.com
- **Azure AD租户**: starkresearchlabs.onmicrosoft.com (Tenant ID: f91eb2ca-e46d-44b6-814b-d4bbacdc5a48)
- **SharePoint同步**: 4个SRL项目站点 (Airwolf, Blue Thunder, Gunstar, Megaforce)
- **用户命令行工具使用**: cmd.exe, powershell.exe, regedit.exe, msconfig.exe, mstsc.exe, iscsicpl.exe
- **云同步全开**: OneDrive, Google Drive, Dropbox, iCloud全部登录
