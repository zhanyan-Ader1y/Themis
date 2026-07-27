<p align="center">
  <h1 align="center">Themis</h1>
  <p align="center">
    <strong>面向团队的自进化 repo-local AI Coding Harness</strong>
  </p>
  <p align="center">
    <a href="docs/design/">设计规范</a> ·
    <a href="docs/">文档</a> ·
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

Themis 是一个能够自我沉淀知识的规范驱动开发框架。它将 Themis 管理的能力层与项目持有的内容和运行数据分离，并通过明确的工件、证据和门禁管理开发生命周期。

完整设计与模块合同以 [Themis 设计规范](docs/design/) 为准。

## 安装

从 Themis 源仓库运行 `bash bin/themis-init.sh <project-root>`，由 Init 校验环境和模板、写入项目 Manifest，并安装受管 Guidance。环境要求和生命周期边界见 [Init 设计](docs/design/runtime-environment.md) 与 [完整工作流程](docs/design/workflow.md#initupgrade-与-migration)。
