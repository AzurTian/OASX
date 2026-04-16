# OASX

OASX 是面向 OAS 的 Flutter GUI 客户端，负责提供连接配置、本地服务部署入口、脚本工作台、任务参数编辑、日志查看、主题与语言切换等能力。

本仓库聚焦前端与桌面端交互体验，不包含 OAS 服务端本体；你可以把它理解为 OAS 的跨平台图形控制台。

## 项目概览

- 基于 Flutter + Dart 构建，采用 GetX 进行路由、依赖注入和状态管理
- 提供首页工作台、设置页、本地服务部署页三类主入口
- 支持脚本配置联动、任务参数编辑、日志查看、统计展示和应用内更新
- 桌面端支持窗口管理、系统托盘、开机自启等系统级能力
- Web 和窄屏场景使用主导航壳承载页面切换

## 主要能力

- 连接 OAS 服务并管理脚本工作台
- 管理服务地址、账号密码、自动部署、自动登录等设置
- 在桌面端读取并编辑 `deploy.yaml`，执行本地 OAS 部署流程
- 查看脚本运行日志、统计信息和任务状态
- 管理多语言、主题、应用更新与本地缓存目录

## 技术栈

- Flutter
- Dart
- GetX
- GetStorage
- Dio / SSE / WebSocket
- Windows 桌面能力集成（`window_manager`、`system_tray` 等）

## 运行环境

### 开发环境

| 组件 | 最低要求 | 推荐版本 | 说明 |
| --- | --- | --- | --- |
| Flutter | `>= 3.35.0` | `3.35.1` | 与当前 CI 配置保持一致 |
| Dart SDK | `>= 3.9.0 < 4.0.0` | `3.9.0` | 由 `pubspec.yaml` 与 CI 共同约束 |
| Java | 可选 | `17` | Android 构建需要 |
| Python | 可选 | `3.12` | 发布脚本与部分自动化流程使用 |

### 目标平台

仓库已包含以下 Flutter 平台目录：

- Windows
- Android
- Web
- Linux
- macOS
- iOS

当前仓库内置的 GitHub Actions 发布链路明确覆盖：

- Windows
- Android
- Web

## 快速开始

### 1. 安装依赖

```powershell
flutter pub get
```

### 2. 启动应用

Windows 桌面开发：

```powershell
flutter run -d windows
```

Web 调试：

```powershell
flutter run -d chrome
```

Android 调试：

```powershell
flutter run -d android
```

### 3. 首次使用

1. 启动后默认进入 `/home`
2. 在设置页配置 OAS 服务地址、账号密码等连接信息
3. 如果你在本机准备了完整的 OAS 根目录，可以进入 `/server` 页面执行本地部署与启动
4. 成功连接后，首页会加载脚本列表、任务状态、日志和统计信息

## 本地部署 OAS 服务

`/server` 页面用于桌面端本地部署与恢复 OAS 服务连接。当前实现会校验 OAS 根目录中是否存在以下关键文件：

- `toolkit/python.exe`
- `toolkit/Git/cmd/git.exe`
- `deploy/installer.py`
- `config/deploy.yaml`

这意味着当前仓库内置的“一键部署”流程主要面向带有 Windows 工具链的 OAS 根目录。

建议同时遵守以下约束：

- 不要把 OASX 与 OAS 放在同一个目录
- OAS 路径尽量不要包含空格
- OAS 路径尽量不要包含中文字符
- 避免使用过长路径

## 常用开发命令

安装依赖：

```powershell
flutter pub get
```

运行测试：

```powershell
flutter test
```

静态检查：

```powershell
dart analyze
flutter analyze
```

构建产物：

```powershell
flutter build windows --release
flutter build apk --release
flutter build web --release
```

## 项目架构

### 启动层

- 入口文件是 `lib/main.dart`
- `main()` 会先执行 `WidgetsFlutterBinding.ensureInitialized()` 和 `initService()`
- `initService()` 负责初始化 `GetStorage`，注册设置、语言、主题、脚本、窗口、更新、系统托盘等长生命周期服务

### 路由层

路由入口位于 `lib/routes.dart`，当前主路由包括：

- `/home`：首页工作台
- `/settings`：设置页
- `/server`：本地服务部署页

桌面端和 Web 端优先使用主工作台布局；窄屏场景通过 `PrimaryNavigationShell` 承载路由切换。

### 服务层

`lib/service/*` 负责全局生命周期能力，主要包括：

- `LocaleService`：语言切换与翻译刷新
- `ThemeService`：主题状态管理
- `ScriptService`：脚本数据加载与同步
- `WebSocketService`：实时连接能力
- `WindowService`：窗口初始化与桌面行为
- `SystemTrayService`：系统托盘
- `AutoStartService`：开机自启
- `AppUpdateService`：应用更新检查与安装

### 模块层

| 模块 | 位置 | 说明 |
| --- | --- | --- |
| 首页工作台 | `lib/modules/home` | 脚本面板、任务列表、统计面板、布局控制、启动连接检查 |
| 设置模块 | `lib/modules/settings` | 地址、账号密码、自动部署、自动登录、缓存目录等持久化设置 |
| 服务部署模块 | `lib/modules/server` | OAS 根路径校验、`deploy.yaml` 读写、部署执行、自动登录恢复 |
| 参数编辑模块 | `lib/modules/args` | 动态参数表单、参数分组、时间选择器、草稿提交 |
| 日志模块 | `lib/modules/log` | 日志过滤、滚动、顶部操作区、日志内容显示 |
| 公共模块 | `lib/modules/common` | 共享组件、对话框、桌面栏、标题栏、通用模型与 Snackbar 控制器 |

## 目录结构

```text
.
├─ lib/
│  ├─ main.dart
│  ├─ routes.dart
│  ├─ api/
│  ├─ config/
│  ├─ modules/
│  ├─ service/
│  ├─ translation/
│  └─ utils/
├─ assets/
├─ script/
├─ test/
├─ .github/workflows/
├─ android/
├─ windows/
├─ web/
└─ pubspec.yaml
```

## 国际化

国际化资源位于 `lib/translation/`：

- `lib/translation/i18n.dart`：翻译入口
- `lib/translation/cn_parts/*.dart`：中文拆分资源
- `lib/translation/i18n_us.dart`：英文覆盖

UI 文案应优先通过 `I18n` key + `.tr` 接入，不建议直接写死展示文本。

## 发布与版本流程

仓库中已经包含本地脚本与 GitHub Actions 发布流程：

- `script/sync_version.py`：同步版本号
- `script/extract_changelog.py`：提取最新变更日志
- `script/release_windows.py`：执行 Windows 构建
- `script/release_windows_package.py`：打包 Windows 发布产物
- `.github/workflows/release.yml`：基于 tag 的 Windows / Android / Web 发布工作流

发布工作流的关键行为包括：

- 解析 tag 生成构建版本
- 提取最新变更日志并创建 GitHub Release
- 构建 Windows 压缩包
- 构建 Android 通用包与分 ABI APK
- 构建 Web 并发布到 GitHub Pages 分支

## 与 OAS 的关系

- OASX 是 OAS 的 GUI 客户端，不是 OAS 服务端本体
- OASX 负责提供图形化交互、连接配置和本地部署入口
- OAS 相关文档可参考：
  - 主仓库：<https://github.com/AzurTian/OnmyojiAutoScript>
  - 文档站点：<>

## 参与开发

如果你准备继续扩展本项目，建议优先阅读以下入口：

- `lib/main.dart`
- `lib/routes.dart`
- `lib/modules/home`
- `lib/modules/settings`
- `lib/modules/server`
- `.github/workflows/release.yml`

提交代码前，建议至少执行：

```powershell
flutter test
dart analyze
flutter analyze
```

## License

本项目采用 [GNU General Public License v3.0](LICENSE) 许可证。

## Changelog

版本变更记录见 [CHANGELOG.md](CHANGELOG.md)。
