# MedGuard 用药安全守护系统

一款基于 Apple Human Interface Guidelines 设计的 iOS 原生用药安全管理应用，**AI 大模型驱动 + 家庭双向关怀 + 多层安全体系**。

![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green)
![AI](https://img.shields.io/badge/AI-Doubao--Seed--1.6-purple)

## 功能特性

### 五个主要 Tab 页

| Tab | 功能描述 |
|-----|----------|
| **首页 (Home)** | 今日用药概览，安全状态卡片，快速标记服用/跳过，库存预警 |
| **扫描 (Scan)** | AI 拍照识别药品（豆包视觉模型）+ 条形码扫描 + 手动录入 |
| **档案 (Archive)** | 全部药品管理，搜索/分类筛选/编辑/删除，支持 JSON/CSV 导出 |
| **风险 (Risk)** | AI 药物相互作用分析（高/中/低风险分级），支持更换 AI 模型 |
| **我的 (Profile)** | 个人中心，家庭绑定，消息通知，PIN 设置，数据导出 |

### AI 智能分析

- 📷 **拍照识别药品**：调用 **Doubao-Seed-1.6-vision**（豆包视觉模型），拍照自动提取药品名称、分类、规格
- 🧬 **药物相互作用分析**：将所有药品信息发给 **Doubao-Lite**（豆包文本模型），以"资深临床药师"角色评估风险。在线优先 AI 分析，离线自动降级为本地规则引擎（10条临床规则）兜底
- ⚙️ **可替换模型**：PIN 验证后进入设置页，自行更换 API Key / Model / Endpoint，接入更高端大模型

### 家庭双向关怀

- 🔗 **6 位绑定码**：老人一键生成（5分钟有效），子女输入完成绑定
- 📬 **实时通知**：老人服药/漏服自动推送通知给子女
- 💬 **快捷回复**：老人可发送 👍🙏😊😟 表情回复子女
- 👥 **多账号支持**：一部手机可创建多个老人/子女账号

### 安全体系

- 🔢 **6 位数字 PIN**：首次注册强制设置，SHA-256 加盐哈希 → iOS Keychain
- 👤 **Face ID / Touch ID**：日常无感解锁，敏感操作 PIN 二次验证
- 🛡️ **全本地存储**：UserDefaults + Keychain，数据不上传云端

## 设计亮点

- **Apple 原生风格**：参考 Apple Health / Reminders 设计语言
- **卡片式布局**：信息结构化，层次分明，大量留白
- **SF Symbols 图标**：统一、简洁的图标系统
- **语义色系统**：绿色安全、橙色注意、红色风险
- **深色/浅色模式**：完整适配 Light/Dark Mode
- **Spring 动画**：自然流畅的交互反馈

## 项目结构

```
MedGuard/
├── App/
│   ├── MedGuardApp.swift              # @main 入口 + AppDelegate (通知代理)
│   └── MainTabView.swift              # 5-Tab 主框架
├── Stores/
│   ├── AuthStore.swift                # 多用户认证、绑定码、通知记录、快捷回复
│   ├── PinStore.swift                 # 6位PIN + Keychain + SHA-256 + 盐
│   ├── APIConfigStore.swift           # AI API 配置持久化（可替换模型）
│   └── MedicationStore.swift          # 药品 CRUD + 时间线 + 库存管理
├── Services/
│   ├── DoubaoService.swift            # 豆包大模型（视觉识别 + 文本风险分析）
│   ├── RiskEngine.swift               # 本地规则引擎（10条临床交互规则）
│   ├── DrugLookupService.swift        # 条形码查询（百度 API）
│   ├── DrugDatabase.swift             # 内置药品数据库（30+ 常用药）
│   ├── NotificationManager.swift      # UNUserNotificationCenter 通知管理
│   ├── DataExporter.swift             # JSON / CSV 数据导出
│   └── PersistenceController.swift    # UserDefaults 持久化
├── Models/
│   ├── User.swift                     # 用户 / UserRole / 通知记录 / 快捷回复
│   ├── Medication.swift               # 药品 / 时间线记录 / 用药单位
│   ├── RiskInfo.swift                 # 风险等级 / 药品状态 / 安全状态
│   └── MockData.swift                 # SwiftUI Preview 模拟数据
├── Views/
│   ├── Auth/
│   │   ├── LoginView.swift            # 登录/注册/多账号/面容解锁
│   │   ├── PinKeypadView.swift        # 可复用 6 位 PIN 键盘组件
│   │   ├── PinUnlockSheet.swift       # 解锁 PIN 弹窗
│   │   ├── PinSettingsSheet.swift     # PIN 设置/修改/禁用
│   │   └── AccountBindingView.swift   # 6 位码双向绑定
│   ├── Home/
│   │   ├── HomeView.swift             # 首页（Timeline 封装）
│   │   ├── MedicationArchiveView.swift# 药品档案（搜索/筛选/编辑/删除）
│   │   ├── MedicationEntrySheet.swift # 添加/编辑药品表单
│   │   └── ScannedDrugResultView.swift# 扫码结果展示 + 手动录入
│   ├── Scan/
│   │   └── ScanView.swift             # 拍照 AI + 扫码 + 手动录入（4步流程）
│   ├── Risk/
│   │   ├── RiskView.swift             # AI 风险分析 + 本地规则兜底
│   │   └── RiskSettingsView.swift     # PIN验证 → API 配置（模型/Key/URL）
│   ├── Profile/
│   │   ├── ProfileView.swift          # 个人中心/绑定/导出
│   │   └── MessagesView.swift         # 消息列表（滑动删除）
│   └── Timeline/
│       └── TimelineView.swift         # 时间线（今天/昨天/更早）
├── Components/                        # 可复用 UI 组件
│   ├── PrimaryButton.swift            # 主/次按钮
│   ├── MedicationCard.swift           # 药品卡片
│   ├── RiskCard.swift                 # 风险卡片
│   ├── StatusCard.swift               # 安全状态卡片
│   ├── SectionHeader.swift            # 标题+副标题头部
│   ├── DrugSearchSheet.swift          # 药品搜索/浏览
│   ├── EmptyStateView.swift           # 空状态视图
│   └── ShareSheet.swift               # 系统分享面板
└── Theme/
    └── Theme.swift                    # 设计系统（颜色/字体/间距/阴影/动画/触觉）
```

## 快速开始

### 环境要求

- Xcode 15.0+
- iOS 16.0+ 模拟器或真机

### 运行步骤

**1. 生成项目**
```bash
xcodegen generate
```

**2. 打开并运行**
```bash
open MedGuard.xcodeproj
# Cmd + R 运行
```

> 项目使用 XcodeGen 管理，所有 Swift 文件在 `MedGuard/` 目录下自动索引。

## 技术栈

| 层级 | 技术方案 |
|------|----------|
| UI 框架 | SwiftUI 4.0（iOS 16+） |
| 架构模式 | MVVM + Singleton Service Layer |
| 数据持久化 | UserDefaults (JSON Codable) + iOS Keychain |
| AI 服务 | 豆包大模型 Doubao-Seed-1.6-vision（视觉）+ Doubao-Lite（文本） |
| 生物识别 | LocalAuthentication (Face ID / Touch ID) |
| 通知系统 | UNUserNotificationCenter |
| 条形码查询 | 本地数据库 + 百度 API |

## 安全设计

- **PIN**：注册时强制设置 → SHA-256 + 16 字节随机盐 → Keychain 硬件加密
- **生物识别**：Face ID / Touch ID 本地验证，生物特征数据不离开设备
- **数据隔离**：全部数据本地存储，多用户按 `userId` 隔离
- **API Key**：可随时更换，PIN 保护设置入口

## 数据流

```
用户操作 → View (SwiftUI)
           ↓ @EnvironmentObject / @StateObject
       Store (ObservableObject)
           ↓ async/await
       Service (Singleton)
           ↓ URLSession / UserDefaults / Keychain
       外部 API / 本地存储
```

## 许可证

MIT License
