# iPurseLight 💰✨

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-LifeCycle-success) ![SwiftData](https://img.shields.io/badge/Database-SwiftData-green)

**iPurseLight** 是一款基于 SwiftUI 和 SwiftData 构建的极简个人理财 App。它摒弃了繁琐的记账流程，利用 AI 技术实现自然语言记账，提供专业的资产复利计算，并支持本地数据的完整备份与迁移。

> **Update Log (2026-01-02):**
> * ✨ **New Feature:** Added Local Data Backup & Restore (JSON format).
> * 📥 **Improvement:** Enhanced CSV import to support 'Month.Year' (e.g., Jan.2026) filenames.
> * 🐛 **Fix:** Optimized AI model connectivity (Gemini 2.5) & DeepSeek integration.

## ✨ 核心功能 (Features)

* **🤖 AI 智能记账 (AI-Powered Tracking)**
    * 接入 **DeepSeek** (推荐)、**Gemini 2.5**、**OpenAI GPT-5.2**。
    * 支持自然语言输入：*"刚才支付宝打车花了30元"* -> 自动识别金额、分类、渠道。

* **💾 数据安全与备份 (Data Backup & Restore)**
    * **本地优先**：数据完全存储于设备本地 (SwiftData)，保护隐私。
    * **JSON 导出/恢复**：支持一键导出所有资产与账单数据为 JSON 文件，轻松迁移至新设备。
    * **未来扩展**：底层架构已为 iCloud/WebDAV 同步做好准备。

* **📈 资产驾驶舱 (Asset Dashboard)**
    * **自动复利计算**：基于本金与年化率 (APY)，实时秒级计算收益。
    * **收益分离**：区分“已产出收益” (历史落袋) 与“动态利息” (当前产生)。
    * **多维度汇总**：支持创建自定义资产包 (Portfolios)，如“流动资金”、“养老储备”。
    
* **🌍 极致本地化 (Localization)**
    * **应用内双语切换**：独立于系统语言，一键切换 中文/English。
    * **智能日期格式**：中文显示 "1月/2025年"，英文显示 "Jan./2025"。
    
* **🌗 完美深色模式 (Dark Mode)**
    * 全线 UI 适配 iOS 深色模式，使用语义化色彩，夜晚使用不刺眼。

* **🛠️ 网络诊断实验室 (Network Lab)**
    * 内置 API 连接测试工具，快速排查 Key 权限与网络环境问题。

## 🚀 快速开始 (Getting Started)

### 1. 环境要求
* Xcode 15.0+
* iOS 17.0+

### 2. AI 配置指南 (AI Configuration Tips)

为了确保 AI 功能正常使用，请参考以下配置建议：

* **DeepSeek (强烈推荐 / Recommended)**
    * 表现最稳定，中文理解能力极强。
    * 无需特殊网络配置，直接使用。
    
* **Google Gemini**
    * 本项目已升级至 **`gemini-2.5-flash`** 模型。
    * **注意**：旧版 `1.5-flash` 可能在某些新 API Key 下报 `404 Not Found`，请务必保持使用代码中的 2.5 版本。
    * 需要非中国大陆/香港 IP 访问。
    
* **OpenAI**
    * 默认调用 **`gpt-5.2`** 或 `gpt-3.5-turbo`。
    * 请确保 API Key 有余额 (Quota)。

### 3. 安装步骤
1.  Clone 本仓库。
2.  使用 Xcode 打开 `iPurseLight.xcodeproj`。
3.  等待 Swift Package 依赖解析。
4.  运行到模拟器或真机。

## 📂 项目结构 (Project Structure)

```text
/iPurseLight
 ├─ App/                          # 应用入口与全局注入层
 │   ├─ iPurseLightApp.swift      # 应用入口：注入 ModelContainer / LocalizationManager
 │   ├─ LocalizationManager.swift # 本地化核心：双语字典、日期格式化（Month / Year）
 │   └─ Assets.xcassets           # 全局资源（颜色、图标、主题）
 │
 ├─ Models/                       # 数据模型层（SwiftData）
 │   ├─ Models.swift              # AssetItem / BillItem
 │   │                            #含复利计算、核心财务逻辑 
 │   └─ BackupModels.swift        # 备份数据模型：定义 DTO 结构 (JSON 中转层)
 │
 ├─ Services/                     # 外部服务 / AI 能力层
 │   ├─ AIService.swift           # AI 服务核心
 │   │                            # 集成 DeepSeek（默认）
 │   │                            # Gemini 2.5 / GPT-5.2 
 │   └─ BackupService.swift       # 备份服务：负责 JSON 序列化与文件 I/O
 │
 ├─ Views/                        # UI / 业务视图层
 │   ├─ ContentView.swift         # TabView主框架（全局导航）             
 │   └─ DataBackupView.swift      # 备份管理页：数据导出与文件恢复 UI
 │
 │   ├─ Debug/                    # 调试与诊断视图
 │   │   └─ DebugView.swift       # 网络诊断实验室（API 连通性测试）
 │
 │   ├─ Asset/                    # 资产模块
 │   │   ├─ AssetView.swift       # 资产主页（支持左右滑动 Portfolios）
 │   │                            # 资产录入表单（含“已产出收益”字段）
 │
 │   ├─ Bill/                     # 账单与分析模块
 │   │   ├─ BillView.swift        # 账单流水（支持 CSV 导入）
 │   │   ├─ AnalysisView.swift    # 财务分析 / AI 建议
 │   │   │                        # Chart 适配深色模式
 │   │   └─ TransactionFormView.swift
 │
 │   └─ Settings/                 # 设置模块
 │       └─ SettingsView.swift    # API Key 管理
 │                                # 语言切换
 │                                # 诊断入口
 🤝 贡献 (Contribution)
欢迎提交 PR！ 特别感谢 DeepSeek 提供的高性价比 AI 服务，以及 Google Gemini 的免费额度支持。

📄 License
MIT License
