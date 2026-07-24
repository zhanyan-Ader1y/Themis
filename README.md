<p align="center">
  <h1 align="center">Themis</h1>
  <p align="center">
    <strong>面向团队的自进化repo-local AI Coding Harness</strong>
  </p>
  <p align="center">
    <a href="docs/">Wiki</a> ·
    <a href="docs/plan/">实施计划</a> ·
    <a href="CHANGES.md">更新日志</a>
  </p>
  <p align="center">
    <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-blue.svg">
    <img alt="Platform" src="https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey.svg">
    <img alt="Runtime" src="https://img.shields.io/badge/runtime-Bash%203.2%2B-informational.svg">
  </p>
</p>

---


## 介绍

Themis 是一个能够自我沉淀知识的规范驱动开发框架。

## 核心设计原则

```
Core 定义能力，不保存项目内容
Workspace 保存内容，不实现控制逻辑
Core 可以升级，Workspace 不被覆盖
Workspace 可以演进，Core 通过协议解释
```

## 安装

将 `templates/.themis/` 复制到目标项目的 `<project-root>/.themis/`。