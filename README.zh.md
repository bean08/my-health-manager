# My Health Manager

[English README](README.md) · 许可证：[Apache-2.0](LICENSE)

`My Health Manager` 是一个原生 macOS 健康助手，用来管理轻量但持续性的健康提醒。它常驻菜单栏，提醒数据保存在可编辑的 JSON 文件中，并支持多条互相独立的自定义提醒。

## 功能特性

- 基于 SwiftUI + AppKit 的原生 macOS 应用
- 菜单栏常驻，主窗口关闭后应用继续运行
- 主窗口包含“健康提醒”和“全局设置”两个模块
- 支持多条提醒，每条提醒都可单独设置名称、提醒间隔、稍后提醒、声音和内容
- 提醒内容支持 Markdown 实时预览与插入图片
- 提醒弹窗固定显示在屏幕右上角，内容原生渲染并自动适配高度
- 每条提醒支持单独选择声音并试听
- 可指定一条提醒接入菜单栏快捷操作
- 菜单栏下拉菜单中的剩余时间会实时更新
- 支持在投屏或会议软件前台时暂缓提醒
- 外部 `settings.json` 配置文件，支持自定义存储路径
- 支持打包为同时兼容 Apple Silicon 和 Intel 的通用 macOS 应用

## 环境要求

- macOS 13.0 或更高版本
- Xcode / Swift 5.9 及以上工具链

## 开发运行

```bash
cd my-health-manager
swift run MyHealthManager
```

## 打包

```bash
cd my-health-manager
./scripts/package-macos.sh
```

输出文件：

- `dist/MyHealthManager.app`
- `dist/MyHealthManager.dmg`

该脚本会分别构建 `arm64` 和 `x86_64` 的 release 二进制，再合并成一个通用应用包，并嵌入生成的应用图标。

## 存储

默认配置文件：

- `~/Documents/my-health-manager/settings.json`

你也可以在 `全局设置 -> 配置文件路径` 中改成任意 `settings.json` 完整路径，支持 `~`。

当前提醒配置字段：

- `title`
- `intervalMinutes`
- `snoozeMinutes`
- `soundEnabled`
- `soundName`
- `message`

## 发布

- 当前版本：`0.0.3`
- 推荐 Git tag：`0.0.3`
- `0.0.3` 最新变更：
  - 阻止提醒 Markdown 里的远程图片链接，预览和弹窗都只保留本地图片
  - 将提醒图片限制为配置目录内的受控相对路径
  - 插入图片时自动复制到本地 `attachments/` 目录，并保存为相对路径
- 变更记录见：[CHANGELOG.md](CHANGELOG.md)

## 许可证

本项目采用 Apache License 2.0，详见 [LICENSE](LICENSE)。
