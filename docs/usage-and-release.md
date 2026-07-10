# moonbit-csv 使用与发布指南

## 1. 适合什么场景

`moonbit-csv` 适合这几类项目：

- 读取配置型 CSV 数据
- 做轻量的数据导入、导出和字段校验
- 在后端服务中把表头数据转成按列名访问的结构
- 做课程作业、工具脚本、比赛项目中的 CSV 处理模块
- 给前端 Playground 或 CLI 提供统一的解析核心

它当前不追求“大数据处理”或“流式超大文件导入”，而是优先保证：

- API 简单
- 错误可解释
- 行为可预测
- 测试和发布流程完整

## 2. 核心 API 用法

### 2.1 直接解析 CSV 文本

```mbt
let rows = @csv.parse("name,lang\nMoonBit,mbt\nRust,rs")
```

返回结果是二维数组：

```text
[
  ["name", "lang"],
  ["MoonBit", "mbt"],
  ["Rust", "rs"],
]
```

### 2.2 需要结构化错误时

```mbt
match @csv.parse_result("name,lang\nMoonBit") {
  Ok(rows) => rows
  Err(err) => println(err.to_string())
}
```

适合后端导入、表单校验、命令行工具等不能直接中断的场景。

### 2.3 按表头处理

```mbt
let table = @csv.parse_table("name,lang\nMoonBit,mbt\nRust,rs")

let first_lang = @csv.get_cell(table, 0, "lang")
let names = @csv.column_values(table, "name")
let missing = @csv.missing_headers(table, ["name", "quote"])
```

适合：

- 上传 CSV 后做必填列校验
- 读取指定列
- 转成业务记录

### 2.4 选择部分列

```mbt
match @csv.select_columns(table, ["name", "lang"]) {
  Ok(selected) => println(@csv.stringify_table(selected))
  Err(missing) => println(missing.join(", "))
}
```

### 2.5 写回 CSV

```mbt
let rows = [
  ["name", "quote"],
  ["MoonBit", "fast, simple, fun"],
]

let text = @csv.stringify(rows)
```

## 3. CLI 使用

运行方式：

```bash
moon run --target js src/cmd/cli -- --input sample.csv
```

常见参数：

- `--input <path>`：输入文件
- `--output <path>`：输出规范化后的 CSV 或选列结果
- `--delimiter <value>`：支持 `,`、`;`、`|`、`tab`
- `--strict`：严格校验列数一致
- `--require <a,b,c>`：要求表头必须存在
- `--select <a,b,c>`：只保留指定列
- `--preview <n>`：预览行数
- `--json`：输出 JSON 分析结果

示例：

```bash
moon run --target js src/cmd/cli -- --input sample.csv --require name,lang --select name,quote --output selected.csv
```

这个命令适合：

- 校验上传 CSV 的结构
- 抽取指定列
- 生成规范化后的导出文件

## 4. 浏览器 Playground

先构建浏览器桥接：

```bash
moon build --target js src/cmd/webbridge
```

然后在仓库根目录启动静态文件服务，打开：

```text
web/index.html
```

当前页面支持：

- 粘贴 CSV 文本
- 上传 CSV 文件
- 拖拽 CSV 文件
- 预览表头、数据行、记录卡片
- 校验缺失表头
- 选择列并下载结果
- 查看 JSON 输出

## 5. 本地验证命令

建议在每次提交或发布前执行：

```bash
moon fmt
moon test
node --test web/app.test.mjs
moon build --target js src/cmd/webbridge
moon package
```

如果你希望更严格一些，再补一条：

```bash
moon check
```

## 6. 发布到 Mooncakes

当前包坐标：

- 包名：`sikadi123/moonbit-csv`
- 版本：`0.1.0`
- 仓库：`https://github.com/sikadi123/MoonBit`

发布前建议顺序：

1. `moon whoami`
2. `moon fmt`
3. `moon check`
4. `moon test`
5. `node --test web/app.test.mjs`
6. `moon package`
7. `moon publish`

如果只想先做发布前模拟检查：

```bash
moon publish --dry-run
```

## 7. 常见问题

### GitHub 仓库名和 Mooncakes 包名不一致会不会有问题

一般不会。

关键是：

- `moon.mod` 的 `name` 要和你的 Mooncakes 用户名命名空间一致
- `repository` 要指向真实可访问的源码仓库

也就是说：

- GitHub 仓库可以叫 `MoonBit`
- Mooncakes 包可以叫 `sikadi123/moonbit-csv`

这是允许的，只要元信息清楚即可。

### 上传 CSV 后能做什么

当前已经支持：

- 解析 CSV 为结构化行数据
- 识别缺失表头
- 预览前几行
- 输出按字段名组织的记录
- 选择部分列并导出新的 CSV
- 下载规范化后的 CSV 文本

### 输出会得到什么

根据使用方式不同，输出包括：

- 二维字符串数组
- `CsvTable`
- `CsvRecord`
- 规范化 CSV 文本
- 选列后的 CSV 文本
- JSON 分析结果
