# iPurseLight 💰✨

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-LifeCycle-success) ![SwiftData](https://img.shields.io/badge/Database-SwiftData-green)

**iPurseLight** 是一款基于 SwiftUI 和 SwiftData 构建的极简个人理财 App。它摒弃了繁琐的记账流程，利用 AI 技术实现自然语言记账，提供专业的资产复利计算，并支持本地数据的完整备份与迁移。

> **Update Log (2026-01-05):**
> * 🗣️ **New Feature:** Added **Siri Shortcuts & Action Button** support for hands-free voice logging.
> * 🧠 **AI Upgrade:** Enhanced prompt engineering with **strict category/channel mapping** (e.g., Credit Card -> Bank Card).
> * ✨ **UX Improvement:** Auto-navigation to Bill tab when triggering shortcuts.

## ✨ 核心功能 (Features)

* **🤖 AI 智能记账 (AI-Powered Tracking)**
    * 接入 **DeepSeek** (推荐)、**Gemini 2.5**、**OpenAI GPT-5.2**。
    * **自然语言输入**：*"刚才打车花了30元"* -> 自动识别金额、分类、渠道。
    * **智能归类映射**：自动将“花呗/余额宝”归类为支付宝，“信用卡”归类为银行卡，确保数据规范。

* **⚡️ 快捷指令与语音 (Shortcuts & Voice)**
    * **Action Button 支持**：一键唤起 Siri 听写，自动打开 App 并预填充记账内容。
    * **系统级集成**：支持 iOS "Shortcuts" App，可自定义自动化流程。

* **💾 数据安全与备份 (Data Backup & Restore)**
    * **本地优先**：数据完全存储于设备本地 (SwiftData)。
    * **JSON 导出/恢复**：支持一键导出所有资产与账单数据为 JSON 文件，轻松迁移至新设备。

* **📈 资产驾驶舱 (Asset Dashboard)**
    * **自动复利计算**：基于本金与年化率 (APY)，实时秒级计算收益。
    * **收益分离**：区分“已产出收益” (历史落袋) 与“动态利息” (当前产生)。
    
* **🌍 极致本地化 (Localization)**
    * **应用内双语切换**：独立于系统语言，一键切换 中文/English。
    * **智能日期格式**：中文显示 "1月/2025年"，英文显示 "Jan./2025"。
    
* **🌗 完美深色模式 (Dark Mode)**
    * 全线 UI 适配 iOS 深色模式，使用语义化色彩，夜晚使用不刺眼。

## 🚀 快速开始 (Getting Started)

### 1. 环境要求
* Xcode 15.0+
* iOS 17.0+

### 2. AI 配置指南 (AI Configuration Tips)

* **DeepSeek (强烈推荐)**
    * 表现最稳定，中文理解能力极强，已适配最新的严格分类 Prompt。
* **Google Gemini**
    * 本项目已升级至 **`gemini-2.5-flash`** 模型，修复了旧版 404 问题。
    
### 3. 快捷指令设置 (How to Setup Shortcuts)
1. 编译并运行 App 到真机。
2. 打开系统 **“快捷指令 (Shortcuts)”** App。
3. 创建新指令：添加 **“听写文本 (Dictate Text)”** -> 添加 **“Note a Bill (iPurseLight)”**。
4. 将听写的结果作为参数传入 `Note a Bill`。
5. (可选) 将此快捷指令绑定到 Action Button。

## 📂 项目结构 (Project Structure)

```text
/iPurseLight
 ├─ App/                          # 应用入口与全局注入层
 │   ├─ iPurseLightApp.swift      # 应用入口：注入 ModelContainer / LocalizationManager
 │   ├─ LocalizationManager.swift # 本地化核心：双语字典、日期格式化（Month /Year） 
 │   ├─ QuickActionManager.swift  # ✨ 新增：单例状态管理 (连接 Intent 与 View) 
 │   ├─ AppIntents.swift          # ✨ 新增：定义快捷指令意图 (AddTransactionIntent)
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
欢迎提交 PR！

📄 License
MIT License
