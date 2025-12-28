# iPurseLight 💰✨

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![SwiftUI](https://img.shields.io/badge/SwiftUI-LifeCycle-success) ![SwiftData](https://img.shields.io/badge/Database-SwiftData-green)

**iPurseLight** 是一款基于 SwiftUI 和 SwiftData 构建的极简个人理财 App。它摒弃了繁琐的记账流程，利用 AI 技术实现自然语言记账，并提供专业的资产复利计算与多维度财务分析。

> **Update Log (2025-12-27):** > * Integrated DeepSeek & Gemini 2.5 Flash.
> * Full Dark Mode support.
> * English/Chinese dual language support with advanced date formatting.

## ✨ 核心功能 (Features)

* **🤖 AI 智能记账 (AI-Powered Tracking)**
    * 接入 **DeepSeek** (推荐)、**Gemini 2.5**、**OpenAI GPT-5.2**。
    * 支持自然语言输入：*"刚才打车花了30元"* -> 自动识别金额、分类、渠道。
    
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
iPurseLight/
├── App/
│   ├── LocalizationManager.swift  // 核心：双语字典与日期格式化逻辑
│   └── ...
├── Models/
│   └── Models.swift               // SwiftData 模型 (含复利计算逻辑)
├── Services/
│   └── AIService.swift            // AI 接口封装 (DeepSeek/Gemini/OpenAI)
├── Views/
│   ├── Debug/
│   │   └── DebugView.swift        // 网络诊断工具
│   ├── Asset/                     // 资产管理模块
│   ├── Bill/                      // 账单流水模块
│   └── ...
🤝 贡献 (Contribution)
欢迎提交 PR！ 特别感谢 DeepSeek 提供的高性价比 AI 服务，以及 Google Gemini 的免费额度支持。

📄 License
MIT License
