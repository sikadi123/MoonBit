# moonbit-csv

`moonbit-csv` 是一个面向 MoonBit 生态的轻量级 CSV 解析与生成库，目标是提供一套简单、稳定、可测试、易集成的表格文本处理能力。

本项目优先解决以下问题：

- 在 MoonBit 中缺少一个工程化可用的 CSV 基础库
- 业务项目需要稳定处理带引号、逗号、换行和表头的 CSV 数据
- 参赛项目需要具备清晰边界、完整文档、测试和示例，便于快速验收

## 项目目标

- 提供 RFC 4180 风格的核心 CSV 解析能力
- 提供 CSV 写出能力，保证常见字段能够正确转义
- 提供易于理解的 API，优先满足基础使用场景
- 提供可运行示例、系统化测试和后续可扩展的实现结构

## 计划功能

- 读取字符串形式的 CSV 文本
- 输出二维字符串数组
- 支持可选表头读取
- 支持自定义分隔符、换行风格和是否包含表头
- 支持双引号转义、逗号、空字段、行尾空列
- 提供将记录写回 CSV 文本的能力
- 对非法输入返回明确错误

## 当前文档

- [需求分析](C:\Users\sikad\Desktop\MoonBit\docs\requirements-analysis.md)
- [设计分析](C:\Users\sikad\Desktop\MoonBit\docs\design-analysis.md)
- [比赛交付清单](C:\Users\sikad\Desktop\MoonBit\docs\competition-checklist.md)

## 当前代码骨架

目前仓库已经补齐第一版工程骨架，核心目录如下：

```text
.
├─ .github/workflows/ci.yml
├─ moon.mod
├─ README.mbt.md
├─ src/
│  ├─ moon.pkg
│  ├─ csv.mbt
│  ├─ csv_test.mbt
│  ├─ parser/
│  │  ├─ moon.pkg
│  │  └─ parser.mbt
│  ├─ writer/
│  │  ├─ moon.pkg
│  │  └─ writer.mbt
│  ├─ types/
│  │  ├─ moon.pkg
│  │  └─ types.mbt
│  └─ cmd/demo/
│     ├─ moon.pkg
│     └─ main.mbt
└─ docs/
```

这个骨架的目的不是“先把代码写满”，而是先把后续开发所依赖的几件事搭好：

- MoonBit 模块配置
- 对外 API 入口
- parser / writer / types 的包边界
- 最小 smoke test
- GitHub Actions CI

## 推荐开发顺序

建议你接下来按这个顺序编码：

1. 先实现 `src/parser/parser.mbt` 的状态机骨架
2. 再让 `src/csv.mbt` 接到真实 `parse` 能力
3. 然后实现 `src/writer/writer.mbt`
4. 最后补 `src/types/types.mbt` 中的配置和错误类型

这样做的好处是：解析器最难、风险最高，先把最核心的地方打通，后面的 API 和测试才会稳定下来。

## CI 目标

当前 CI workflow 设计为三步：

- `moon fmt --check`
- `moon check`
- `moon test`

这正好对应比赛要求里最关键的“格式、构建、测试”三条主线。

## GitHub CI/CD

仓库现在包含两条 GitHub Actions workflow：

- [ci.yml](C:\Users\sikad\Desktop\MoonBit\.github\workflows\ci.yml)
  用于每次 `push` / `pull_request` 自动执行格式检查、构建检查和测试
- [release.yml](C:\Users\sikad\Desktop\MoonBit\.github\workflows\release.yml)
  用于在推送 `v*` 版本标签时自动打包，并把生成的 zip 作为 GitHub Release 附件上传

推荐使用方式：

1. 平时开发时走 `push` 和 `pull request`，让 CI 持续守住质量
2. 需要发版本时创建标签，例如 `v0.1.0`
3. 推送标签后，release workflow 会自动：
   - 安装 MoonBit
   - 执行 `moon fmt --check`
   - 执行 `moon check`
   - 执行 `moon test`
   - 执行 `moon package`
   - 上传 `_build/publish/*.zip` 到 GitHub Release

如果后面你准备把包正式发布到 `mooncakes.io`，可以在 release workflow 基础上再接一层“带 secret 的 publish 步骤”。

## 项目定位

这个项目不是大而全的数据框架，而是一个：

- 小而完整的基础库
- 适合 MoonBit 生态早期使用的通用组件
- 比赛周期内可高质量完成、可验收、可发布的开源项目

## 里程碑

1. 完成文档与 API 草案
2. 完成核心解析器实现
3. 完成写出器实现
4. 完成测试、示例与边界用例补充
5. 完成 README、CI 与发布准备

## 开源与交付原则

- 使用 MoonBit 作为主要实现语言
- 代码、文档、示例和测试保持同步演进
- 设计优先简单清晰，避免为了“功能多”牺牲稳定性
- 以比赛验收要求为下限，以生态可复用性为目标
