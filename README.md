# 農曆日曆 (Lunar Calendar App)

一款精美的 Flutter 农历日历应用，支持农历/公历事件提醒，具有传统中国风格的用户界面设计。

## ✨ 功能特点

### 📅 日历功能
- 支持农历和公历双日历显示
- 可视化日期选择，每个日期显示对应的农历日期
- **周末高亮**3. **农历计算**: 农历日期由 `tyme` 库计算，支持准确的农历月份和闰月判断。

4. **数据存储**: 数据存储在本地浏览器/设备中，不同设备间不会同步。

5. **字体**: 应用使用本地打包的 Noto Serif SC 字体，确保中文显示一致性，无需网络下载。

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

**作者**: [yongliangt](https://github.com/yongliangt)显示，区别于工作日
- 流畅的月份切换和日期导航动画
- **快速跳转** - 点击月份标题可快速选择年月进行跳转
- **返回今天** - 导航到其他月份时，显示"返回今天"按钮，一键返回当前日期

### 🔔 事件提醒
- **农历提醒**: 根据农历日期设置提醒（如生日、传统节日）
- **公历提醒**: 根据公历日期设置提醒
- **闰月支持**: 自动识别并支持闰月日期的提醒设置

### 🔄 灵活的重复选项
- 不重复 - 一次性事件
- 每天 - 每日重复
- 每星期 - 每周重复
- 每月 - 每月重复
- 每年 - 每年重复（适合生日、纪念日）
- 自定义 - 自定义间隔天数

### 📝 事件管理
- 事件标题和详细描述/备注
- 编辑和删除现有事件
- 本地通知提醒
- 便捷的关闭按钮

### 🎨 精美设计
- 传统中国红金配色主题
- 优雅的 Noto Serif SC 中文衬线字体
- 流畅的动画和过渡效果
- 周末日期红色高亮显示

## 📁 项目结构

```
lunar_calendar_app/
├── lib/
│   ├── main.dart          # 主入口点，包含所有核心代码
│   └── theme.dart         # 主题配置文件
├── assets/
│   └── fonts/
│       └── NotoSerifSC-Regular.ttf  # 中文衬线字体
├── android/
│   └── app/
│       ├── build.gradle.kts   # Android 构建配置
│       └── src/main/
│           └── AndroidManifest.xml  # Android 权限配置
├── ios/                   # iOS 平台配置
├── macos/                 # macOS 平台配置
├── web/                   # Web 平台配置
├── linux/                 # Linux 平台配置
├── windows/               # Windows 平台配置
├── pubspec.yaml           # Flutter 依赖配置
└── README.md              # 项目说明文档
```

## 🛠️ 技术栈

- **Flutter 3.38+** - 跨平台 UI 框架
- **Dart 3.10+** - 编程语言
- **Hive** - 轻量级本地数据库
- **table_calendar** - 日历组件
- **flutter_local_notifications** - 本地通知
- **tyme** - 农历日期计算库
- **intl** - 国际化和日期格式化
- **Noto Serif SC** - 中文衬线字体（本地打包）

## 🚀 快速开始

### 环境要求
- Flutter SDK 3.38.0 或更高版本
- Dart SDK 3.10.0 或更高版本

### 1. 克隆项目
```bash
git clone https://github.com/yongliangt/lunar_calendar_app.git
cd lunar_calendar_app
```

### 2. 获取依赖
```bash
flutter pub get
```

### 3. 运行应用
```bash
# 在 Chrome 上运行
flutter run -d chrome

# 在 macOS 上运行
flutter run -d macos

# 在 Android 上运行
flutter run -d android

# 在 iOS 上运行
flutter run -d ios
```

## ⚙️ Android 配置

确保以下配置已正确设置：

- `minSdkVersion`: 35 (Android 15)
- `compileSdkVersion`: 35
- `targetSdkVersion`: 35

### 必要权限 (AndroidManifest.xml)
- `POST_NOTIFICATIONS` - 通知权限
- `SCHEDULE_EXACT_ALARM` - 精确闹钟权限
- `USE_EXACT_ALARM` - 使用精确闹钟权限

## 📱 支持平台

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

## 🎯 使用指南

### 日历导航
- **左右滑动** 或点击 **箭头** 切换月份
- **点击月份标题**（如"2026年1月"）打开年月选择器快速跳转
- **点击金色"今天"按钮** 快速返回当前日期（仅在非当前月份时显示）

### 添加提醒
1. 点击右下角的 **"+"** 按钮
2. 输入事件标题和备注（可选）
3. 选择 **农历** 或 **公历**
4. 选择重复频率（不重复、每天、每星期、每月、每年、自定义）
5. 点击 **保存**

### 编辑/删除提醒
- **点击事件** 进入编辑模式
- 点击 **删除图标** 删除事件

## ⚠️ 注意事项

1. **Hive 数据库**: 首次运行时如遇到 HiveBox 未打开的错误，请完全停止应用并重新启动。

2. **通知权限**: Android 13 及以上版本需要用户手动授予通知权限。

3. **农历计算**: 农历日期由 `tyme` 库计算，支持准确的农历月份和闰月判断。

4. **数据存储**: 数据存储在本地浏览器/设备中，不同设备间不会同步。

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！