# MedGuard 用药安全系统

一款基于 Apple Human Interface Guidelines 设计的 iOS 原生用药安全管理应用。

![Platform](https://img.shields.io/badge/Platform-iOS%2016%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green)

## 功能特性

### 四个主要 Tab 页

| Tab | 功能描述 |
|-----|----------|
| **首页 (Home)** | 展示今日用药安全状态卡片，正在服用的药物列表，支持快速标记服用状态 |
| **扫描 (Scan)** | 扫描药盒条形码添加药物，支持手动输入药物信息 |
| **时间线 (Timeline)** | 按"今天/昨天/更早"分组展示用药记录，时间轴形式呈现 |
| **风险 (Risk)** | 卡片式展示药物冲突风险信息，高/中/低风险分级 |

## 设计亮点

- **Apple 原生风格**：参考 Apple Health / Apple Reminders 设计语言
- **卡片式布局**：信息结构化，层次分明
- **大量留白**：降低视觉负担，提升可读性
- **SF Symbols 图标**：简洁、一致的图标系统
- **安全色系统**：绿色安全、橙色注意、红色风险
- **深色/浅色模式**：自动适配系统主题

## 项目结构

```
MedGuard/
├── App/
│   ├── MedGuardApp.swift      # App 入口
│   └── ContentView.swift      # TabView 主视图
├── Theme/
│   └── Theme.swift            # 设计系统（颜色、字体、间距）
├── Components/
│   ├── StatusCard.swift       # 安全状态卡片
│   ├── MedicationCard.swift   # 药物卡片
│   ├── RiskCard.swift         # 风险卡片
│   └── PrimaryButton.swift    # 按钮组件
├── Views/
│   ├── Home/
│   │   └── HomeView.swift     # 首页视图
│   ├── Scan/
│   │   └── ScanView.swift     # 扫描页视图
│   ├── Timeline/
│   │   └── TimelineView.swift # 时间线视图
│   └── Risk/
│       └── RiskView.swift     # 风险页视图
├── Models/
│   ├── Medication.swift      # 药物数据模型
│   ├── RiskInfo.swift         # 风险数据模型
│   └── MockData.swift        # 示例数据
└── Assets.xcassets/          # 资源目录
```

## 快速开始

### 环境要求

- Xcode 15.0+
- iOS 16.0+ 模拟器或真机

### 运行步骤

1. **打开项目**
   ```bash
   open MedGuard.xcodeproj
   ```

2. **选择模拟器**
   - 打开 Xcode 后，在顶部工具栏选择目标设备（如 iPhone 15 Pro）

3. **运行项目**
   - 按 `Cmd + R` 或点击运行按钮

### 使用 XcodeGen（可选）

如果已安装 XcodeGen，可以直接运行：

```bash
xcodegen generate
open MedGuard.xcodeproj
```

## 技术栈

- **SwiftUI**：声明式 UI 框架
- **MVVM 架构**：清晰的数据流分离
- **SF Symbols**：原生图标库
- **Combine**：响应式编程（预留扩展）

## 预览截图

> 项目使用模拟数据展示界面效果

### 首页
- 顶部安全状态卡片（绿色渐变）
- 药物列表卡片，支持点击切换状态

### 扫描页
- 居中扫描框设计
- 主次按钮清晰区分

### 时间线页
- 分组标题固定
- 时间轴节点动画

### 风险页
- 风险等级彩色标签
- 可展开的风险详情页

## 扩展方向

- [ ] 集成 CameraX 扫描真实条形码
- [ ] 添加 CoreData 本地数据持久化
- [ ] 实现用药提醒通知
- [ ] 药物冲突数据库接入
- [ ] Apple Health 数据同步

## 许可证

MIT License
