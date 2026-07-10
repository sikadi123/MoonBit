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
- [使用与发布指南](C:\Users\sikad\Desktop\MoonBit\docs\usage-and-release.md)

## 当前实现状态

目前仓库已经不是“只有骨架”，而是已经完成了第一版可用实现。核心目录如下：

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

当前已经落地的能力包括：

- `parse` / `parse_result`
- `stringify` / `stringify_with`
- 引号字段解析
- `""` 双引号转义
- 空字段和尾部分隔符
- `\n` 与 `\r\n` 换行
- 自定义分隔符
- 严格列数校验
- 可运行 demo
- GitHub CI / Release workflow
- 浏览器 Playground 与 CLI
- Mooncakes 发布元信息

本地已经验证通过：

- `moon fmt --check`
- `moon check`
- `moon test`
- `node --test web/app.test.mjs`
- `moon run src/cmd/demo`
- `moon package`

前端与浏览器侧 smoke test 的推荐命令：

- `moon build --target js src/cmd/webbridge`
- 在仓库根目录启动静态文件服务后访问 `web/index.html`
- `node --test web/app.test.mjs`

CLI 推荐命令：

- `moon run --target js src/cmd/cli -- --input sample.csv`
- `moon run --target js src/cmd/cli -- --input sample.csv --require name,lang --select name,quote --output selected.csv`

## 推荐开发顺序

第一版核心功能已经完成。接下来更值得做的顺序是：

1. 增加表头辅助 API
2. 增加更多非法输入测试和回归样例
3. 细化 `CsvError` 种类与定位信息
4. 补充发布元数据并发布到 `mooncakes.io`

这样做的好处是：不会破坏现在已经稳定的解析/写出主路径，同时能继续提高比赛验收和生态复用价值。

## CI 目标

当前 CI workflow 设计为三步：

- `moon fmt --check`
- `moon check`
- `moon test`
- `node --test web/app.test.mjs`

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

## 发布到 Mooncakes

当前仓库已经满足发布所需的基础元信息：

- `moon whoami` 已显示登录用户 `sikadi123`
- `moon.mod` 包名已经使用 `sikadi123/moonbit-csv`
- `moon.mod` 已补充 `repository`、`license`、`description` 等字段
- `moon publish --dry-run` 在本地包校验阶段可以通过；如果失败，优先排查网络连通性

正式发布前建议按下面顺序执行：

1. 执行 `moon check`
2. 执行 `moon test`
3. 执行 `node --test web/app.test.mjs`
4. 执行 `moon package`
5. 执行 `moon publish`

当前 `moon.mod` 使用的发布坐标是：

- 包名：`sikadi123/moonbit-csv`
- 仓库：`https://github.com/sikadi123/MoonBit`
- 版本：`0.1.0`

如果 `moon publish` 报网络类错误，通常不是包内容问题，而是当前环境无法访问 `https://mooncakes.io/api/v0/publish`。

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
