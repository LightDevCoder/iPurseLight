import SwiftUI
import Combine

enum Language: String {
    case zhHans = "zh-Hans"
    case en = "en"
}

class LocalizationManager: ObservableObject {
    @Published var language: Language {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "appLanguage") }
    }
    
    init() {
        if let savedString = UserDefaults.standard.string(forKey: "appLanguage"),
           let savedLanguage = Language(rawValue: savedString) {
            self.language = savedLanguage
        } else {
            self.language = .zhHans
        }
    }
    
    func t(_ key: String) -> String {
        return language == .zhHans ? key : (translations[key] ?? key)
    }
    
    // MARK: - ✨ 新增：日期格式化专用函数
    
    // 1. 月份格式化: 1 -> "1月" (中) / "Jan." (英)
    func formatMonth(_ month: Int) -> String {
        if language == .zhHans { return "\(month)月" }
        let enMonths = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sep.", "Oct.", "Nov.", "Dec."]
        if month >= 1 && month <= 12 { return enMonths[month - 1] }
        return "\(month)"
    }
    
    // 2. 年份格式化: 2025 -> "2025年" (中) / "2025" (英)
    func formatYear(_ year: Int) -> String {
        return language == .zhHans ? "\(year)年" : "\(year)"
    }
    
    // 3. 月度报表标题: "2025年11月 报表" (中) / "2025 Nov. Report" (英)
    func formatMonthlyReportTitle(year: Int, month: Int) -> String {
        if language == .zhHans {
            return "\(year)年\(month)月 报表"
        } else {
            return "\(year) \(formatMonth(month)) Report"
        }
    }
    
    // 4. 年度报表标题: "2025年 汇总报表" (中) / "2025 Annual Report" (英)
    func formatYearlyReportTitle(year: Int) -> String {
        if language == .zhHans {
            return "\(year)全年 汇总报表"
        } else {
            return "\(year) Annual Report"
        }
    }
    
    // MARK: - 翻译字典
    private let translations: [String: String] = [
        // --- Tab Bar ---
        "资产": "Assets",
        "账单": "Bills",
        
        // --- AssetView ---
        "我的资产": "My Assets",
        "总资产 (小金库)": "Total Net Worth",
        "生成 AI 理财建议": "Generate AI Advisor",
        "AI 理财建议": "AI Financial Advisor",
        "AI 正在分析...": "AI analyzing...",
        "分析失败": "Analysis failed",
        "资产明细": "Asset Details",
        "暂无资产": "No assets yet",
        "删除该汇总": "Delete portfolio",
        "新建资产 (如:招商银行)": "New Asset (e.g., Chase Bank)",
        "新建汇总 (如: 汇总渠道)": "New Portfolio (e.g., Summary Channel)",
        "新建资产": "New Asset",
        "编辑资产": "Edit Asset",
        "保存": "Save",
        "基础信息": "Basic Info",
        "名称 (如: 招商银行)": "Name (e.g., Chase Bank)",
        "本金": "Principal",
        "收益设置 (可选)": "Yield Settings (Optional)",
        "年化收益率 (%)": "APY (%)",
        "设置后，资产金额将根据时间自动每日增加。": "Value increases daily based on time.",
        "删除": "Delete",
        "新建汇总": "New Portfolio",
        "汇总名称": "Portfolio Name",
        "勾选包含的资产": "Select Assets",
        "创建": "Create",
        "含收益": "Gain",
        "年化": "APY",
        "天": "day",
        "无数据": "No Data",
        
        // --- BillView ---
        "账单流水": "Transactions",
        "年度汇总": "Annual Report", // ✨ 改成了 Annual Report
        "年份": "Year", // 选择器标题保留 Year
        // "年", "月" 的翻译在 format 函数里处理了，这里可以删掉或留着备用
        "月 无数据": " Month - No Data",
        "全选": "Select All",
        "本月统计": "Monthly Stats",
        "完成": "Done",
        "选择": "Select",
        "记一笔": "Add Transaction",
        "导入表格": "Import CSV",
        
        // --- TransactionFormView ---
        "编辑记录": "Edit Transaction",
        "取消": "Cancel",
        "例如：刚才打车花了30元": "e.g., Taxi $30 just now",
        "使用 DeepSeek 自动识别": "Powered by DeepSeek AI",
        "使用 OpenAI 自动识别": "Powered by OpenAI",
        "使用 Gemini 自动识别": "Powered by Gemini",
        "自动识别": "AI Recognize",
        "识别失败": "Failed",
        "日期": "Date",
        "类型": "Type",
        "金额": "Amount",
        "分类": "Category",
        "例如：餐饮、交通": "e.g., Food, Travel",
        "渠道": "Channel",
        "备注": "Note",
        "选填": "Optional",
        
        // --- AnalysisView ---
        "总收入": "Total Income",
        "总支出": "Total Expense",
        "AI 财务分析": "AI Financial Analysis",
        "开始分析": "Start Analysis",
        "点击按钮，生成收支结构评价与省钱建议。": "Tap to generate analysis.",
        "支出构成": "Expense Structure",
        "收入构成": "Income Structure",
        "无支出": "No expenses",
        
        // --- Settings / Debug ---
        "AI 设置": "AI Settings",
        "AI 模型选择": "AI Model Selection",
        "服务商": "Provider",
        "API Key 配置 (仅本地保存)": "API Key (Local Only)",
        "获取 DeepSeek Key (推荐)": "Get DeepSeek Key",
        "说明": "Note",
        "配置 API Key 后，您可以使用自然语言记账（如'打车20元'）以及获取智能财务分析建议。": "Enable AI features by configuring API Key.",
        "语言设置": "Language",
        "应用语言": "App Language",
        "中文简体": "简体中文",
        "英文": "English",
        "进入网络诊断实验室": "Enter Network Diagnostic Lab",
        "网络诊断实验室": "Network Diagnostic Lab",
        "准备就绪，请点击下方按钮测试...": "Ready. Tap buttons below to test...",
        "测试": "Test",
        "❌ 错误: Gemini Key 为空": "❌ Error: Gemini Key is empty",
        "❌ 错误: DeepSeek Key 为空": "❌ Error: DeepSeek Key is empty",
        "❌ 错误: OpenAI Key 为空": "❌ Error: OpenAI Key is empty",
        "⏳ 正在请求 Gemini...": "⏳ Requesting Gemini...",
        "⏳ 正在请求 DeepSeek...": "⏳ Requesting DeepSeek...",
        "⏳ 正在请求 ChatGPT...": "⏳ Requesting ChatGPT...",
        "❌ URL 构造失败": "❌ URL Construction Failed",
        "无法解析内容": "Unable to parse content",
        "响应结果": "Response",
        "状态码": "Status Code",
        "❌ 请求错误": "❌ Request Error",
        
        // --- Models ---
        "收入": "Income",
        "支出": "Expense",
        "银行存款": "Bank Deposit",
        "现金": "Cash",
        "公积金": "Provident Fund",
        "理财产品": "Wealth Product",
        "外币": "Foreign Currency",
        "其他": "Other",
        "资金账户": "Fund Account",
        "投资理财": "Investment",
        "固定资产": "Fixed Assets",
        "负债/借出": "Debt/Loan"
    ]
}
