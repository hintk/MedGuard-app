# MedGuard 用药安全系统 - 设计规范

## 1. Concept & Vision

MedGuard 是一款专注于用药安全的 iOS 原生应用，采用 Apple Health 的设计语言，传递专业、可信赖、医疗科技感的视觉体验。通过清晰的卡片布局、充足留白和简洁图标，帮助用户安全管理日常用药，实时监控药物冲突风险。

设计理念：**"清晰即安全"** —— 信息结构化呈现，降低误服风险。

## 2. Design Language

### 2.1 Aesthetic Direction
参考 Apple Health / Apple Reminders / Apple Fitness 的设计风格：
- 大量留白，内容密度低
- 圆角卡片，柔和阴影
- SF Symbols 图标系统
- 渐变色彩突出状态
- 深色/浅色模式适配

### 2.2 Color Palette

```
Primary Colors:
- Safe Green:     #34C759 (系统安全色)
- Warning Yellow: #FF9500 (中风险)
- Danger Red:     #FF3B30 (高风险/警示)
- Low Risk Blue:  #007AFF (低风险/信息)

Background Colors:
- Light Mode:
  - Background:   #F2F2F7 (系统灰背景)
  - Card:         #FFFFFF
  - Secondary:    #E5E5EA
  
- Dark Mode:
  - Background:    #000000
  - Card:          #1C1C1E
  - Secondary:     #2C2C2E

Text Colors:
- Primary:        #000000 / #FFFFFF
- Secondary:       #3C3C43 (60% opacity) / #EBEBF5 (60% opacity)
- Tertiary:       #3C3C43 (30% opacity) / #EBEBF5 (30% opacity)
```

### 2.3 Typography

```
Font Family: SF Pro (system)

Titles:
- Large Title:    34pt, Bold
- Title 1:        28pt, Bold
- Title 2:        22pt, Bold
- Title 3:        20pt, Semibold

Body:
- Body:           17pt, Regular
- Callout:        16pt, Regular
- Subheadline:    15pt, Regular
- Footnote:       13pt, Regular
- Caption 1:     12pt, Regular
- Caption 2:     11pt, Regular
```

### 2.4 Spacing System (8pt Grid)

```
- xs:   4pt
- sm:   8pt
- md:   16pt
- lg:   24pt
- xl:   32pt
- xxl:  48pt

Safe Area:
- Top: Dynamic (notch aware)
- Bottom: 34pt (home indicator)
```

### 2.5 Motion & Transitions

- **Tab Switch**: 250ms ease-in-out
- **Card Press**: scale(0.98), 150ms
- **Modal Present**: iOS default sheet presentation
- **Status Change**: 300ms spring animation
- **List Appearance**: 200ms staggered fade-in

### 2.6 Icons (SF Symbols)

```
Home:     house.fill
Scan:     barcode.viewfinder
Timeline: clock.fill
Risk:     exclamationmark.shield.fill
Add:      plus.circle.fill
Camera:   camera.fill
Check:    checkmark.circle.fill
Warning:  exclamationmark.triangle.fill
Pill:     pills.fill
```

## 3. Layout & Structure

### 3.1 Navigation Architecture

```
UITabBarController
├── Tab 1: Home (HomeView)
├── Tab 2: Scan (ScanView)
├── Tab 3: Timeline (TimelineView)
└── Tab 4: Risk (RiskView)
```

### 3.2 Page Layouts

#### Home Page
```
┌─────────────────────────┐
│ Safe Area               │
├─────────────────────────┤
│ 用药状态          [Edit] │  ← Large Title
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │   今日用药安全状态   │ │  ← 状态卡片 (绿色/红色)
│ │   ✓ 安全           │ │
│ │   8/8 药物已服用    │ │
│ └─────────────────────┘ │
├─────────────────────────┤
│ 正在服用               │  ← Section Header
│ ┌─────────────────────┐ │
│ │ 💊 阿司匹林    08:00│ │  ← 药物卡片
│ │    心血管        ✓  │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ 💊 二甲双胍    12:00│ │
│ │    糖尿病      待服用│ │
│ └─────────────────────┘ │
│         ...             │
└─────────────────────────┘
```

#### Scan Page
```
┌─────────────────────────┐
│ Safe Area               │
├─────────────────────────┤
│         扫描             │  ← Large Title
├─────────────────────────┤
│                         │
│    ┌───────────────┐    │
│    │               │    │
│    │  [Scan Icon]  │    │  ← 扫描框
│    │               │    │
│    └───────────────┘    │
│                         │
│    ┌───────────────┐    │
│    │  📷 扫描药盒  │    │  ← 主按钮
│    └───────────────┘    │
│                         │
│    ┌───────────────┐    │
│    │  手动添加药物  │    │  ← 次按钮
│    └───────────────┘    │
│                         │
└─────────────────────────┘
```

#### Timeline Page
```
┌─────────────────────────┐
│ Safe Area               │
├─────────────────────────┤
│         时间线           │
├─────────────────────────┤
│ 今天                    │
│ ├─ 08:00 阿司匹林  ✓   │
│ ├─ 12:00 二甲双胍  ✓   │
│ └─ 20:00 维生素D   ○   │
├─────────────────────────┤
│ 昨天                    │
│ ├─ 08:00 阿司匹林  ✓   │
│ └─ 12:00 二甲双胍  ✓   │
├─────────────────────────┤
│ 更早                    │
│ ├─ 05-20 08:00 阿司匹林✓│
│ └─ 05-20 12:00 二甲双胍✓│
└─────────────────────────┘
```

#### Risk Page
```
┌─────────────────────────┐
│ Safe Area               │
├─────────────────────────┤
│         风险评估         │
├─────────────────────────┤
│ ┌─────────────────────┐ │
│ │ ⚠️ 高风险           │ │  ← 红色强调
│ │ 阿司匹林 + 华法林   │ │
│ │ 出血风险增加        │ │
│ │ 建议咨询医生        │ │
│ └─────────────────────┘ │
│ ┌─────────────────────┐ │
│ │ ⚡ 中风险           │ │  ← 橙色
│ │ 布洛芬 + ACE抑制剂  │ │
│ │ 可能影响肾功能      │ │
│ └─────────────────────┘ │
│         ...             │
└─────────────────────────┘
```

## 4. Features & Interactions

### 4.1 Home Tab

**状态卡片交互**:
- 点击展开详细服药时间表
- 状态变化时有 spring 动画
- 绿色/红色渐变背景表示安全/风险

**药物列表**:
- 左右滑动标记服用状态
- 点击进入药物详情
- 支持编辑/删除操作

### 4.2 Scan Tab

**扫描按钮**:
- 点击进入相机界面
- 扫描动画：边框脉冲效果
- 识别成功：震动反馈 + 成功动画

**手动添加**:
- 点击展开表单 sheet
- 支持扫码/搜索/手动输入

### 4.3 Timeline Tab

**分组逻辑**:
- 今天 / 昨天 / 更早（三天前起）
- Section Header 固定在顶部
- 支持按日期筛选

**记录操作**:
- 点击展开详情
- 长按标记/修改状态

### 4.4 Risk Tab

**风险卡片**:
- 高风险：红色边框 + 红色背景渐变
- 中风险：橙色边框
- 低风险：蓝色边框
- 点击展开完整说明

## 5. Component Inventory

### 5.1 StatusCard (安全状态卡片)
- States: Safe (green), Warning (yellow), Danger (red)
- Corner Radius: 20pt
- Shadow: 0, 4, 20, 0.1 opacity
- Padding: 20pt

### 5.2 MedicationCard (药物卡片)
- States: Default, Taken, Pending, Skipped
- Icon: SF Symbol (pills.fill)
- Corner Radius: 16pt
- Leading: 药物图标
- Trailing: 状态指示器

### 5.3 RiskCard (风险卡片)
- States: High, Medium, Low
- Header: 风险等级标签
- Body: 药物组合 + 说明
- Corner Radius: 16pt
- Left Border: 4pt colored

### 5.4 TimelineRow (时间线行)
- Time: 左侧时间
- Icon: 状态图标 (checkmark/circle)
- Content: 药物名称
- Corner Radius: 12pt

### 5.5 PrimaryButton (主按钮)
- Height: 56pt
- Corner Radius: 14pt
- Background: Primary color
- Font: 17pt Semibold

### 5.6 SecondaryButton (次按钮)
- Height: 48pt
- Corner Radius: 12pt
- Background: Secondary fill
- Font: 17pt Regular

## 6. Technical Approach

### 6.1 Framework
- **SwiftUI** (iOS 16.0+)
- **Combine** for reactive data flow
- **SF Symbols** for icons

### 6.2 Architecture
- **MVVM** pattern
- Shared Components in `Components/`
- Theme system in `Theme/`
- Mock data in `Models/`

### 6.3 File Structure
```
MedGuard/
├── App/
│   ├── MedGuardApp.swift
│   └── ContentView.swift
├── Theme/
│   └── Theme.swift
├── Components/
│   ├── StatusCard.swift
│   ├── MedicationCard.swift
│   ├── RiskCard.swift
│   └── PrimaryButton.swift
├── Views/
│   ├── Home/
│   │   └── HomeView.swift
│   ├── Scan/
│   │   └── ScanView.swift
│   ├── Timeline/
│   │   └── TimelineView.swift
│   └── Risk/
│       └── RiskView.swift
├── Models/
│   ├── Medication.swift
│   ├── RiskInfo.swift
│   └── MockData.swift
└── Assets.xcassets/
```

### 6.4 Assets Requirements
- App Icon: 1024x1024 (生成各尺寸)
- SF Symbols: 无需额外资源
- 启动画面: 系统默认
