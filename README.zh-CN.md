# MoonWell

[简体中文](README.zh-CN.md) | [English](README.md)

**面向 LAS 2.0 测井数据完整性和多测次整合的纯 MoonBit 工具库。** 本版本模块为 `2200732518gjy/moonwell@0.3.2`，MIT 许可。

适用于采集质检、研究预处理和归档整合系统。区别于单纯格式转换，MoonWell 把明确的单位转换、受限深度对齐、冲突策略和**逐单元来源**串成可复用工作流；不替代地质解释或安全决策。

## 已实现功能

- LAS 分节、有限数值解析、曲线 API 代码、可选参数与不透明客户节保存；双向严格单调的深度、矩形可空数值表及输入快照。
- 冻结到 **CWLS January 2014 LAS 2.0** 的严格文档验证：完整必需井头、区域替代、ASCII/CRLF、精确十进制端点/间隔/整除、TIME 和 WRAP；结构化区分标准错误、资源限制和数值模型限制。
- 原文档 String 精确保留注释、重复项、顺序及十进制拼写；严格转换和写出单独检查，绝不通过伪造井头或修改观测值来“修好”数据。
- 缺失段识别、显式常量/线性填补、二分查找相邻端点插值、升序/窗口/选列、有限网格；不外推、不跨空端点或超出最大间隔。
- 长度、电压、密度、温度和声波时差的显式维度转换；未知单位仅允许原单位同名通过，不猜测或暗中改标签。
- 忽略空值的总体矩、type-7 分位数、带覆盖率的裁剪梯形区间积分；范围/梯度/常量段/空值/深度间隙质检；中值滤波、梯度、掩码和派生列。
- 多测次曲线并集、单位和网格对齐、拒绝/先到优先/后到优先冲突策略、绝对容差、单元来源与插值标志、策略应用前的冲突记录。
- 规范化 LAS、数值 CSV、版本化 QA/区间/组装 JSON 报告，以及核心完全用 MoonBit 实现的无状态 JSON 协议。

## 环境与后端

已验证工具链为 `moonc v0.10.14+7d59c7ec9-dev`、`moon 0.1.20260920`。复现实验应记录实际 `moon version --all`，不要把 standalone moon 版本当作编译器安装包版本。

支持 `wasm-gc`、`wasm`、`js`、`native`。前三者可在当前 Windows 环境执行；native 需要系统 C 编译器 gcc/clang。发布流水线在公开 Linux CI 上执行四目标的严格检查、测试、构建和示例；请核对所用版本对应的实际 CI 记录。本机缺少 C 编译器时，只能声明 native 严格检查，不能声明本机 native 测试通过。文件 CLI 使用 Node.js 24；Python 与 lasio/NumPy 仅为可选测试工具，不是生产依赖。

## 精确安装与可运行快速开始

在**仓库外的新目录**执行：

```sh
moon new consumer --user local --name consumer
cd consumer
moon add 2200732518gjy/moonwell@0.3.2
```

把消费者根 `moon.pkg` 内容设为：

```moonbit
import { "2200732518gjy/moonwell" @well }
pkgtype(kind: "executable")
```

把消费者根 `main.mbt` 内容设为下列完整程序：

```moonbit
///|
fn main {
  try {
    let log = @well.make_log(
      [
        { name: "DEPT", unit: "M", api_code: "", description: "depth" },
        { name: "GR", unit: "GAPI", api_code: "45 310 01 00", description: "gamma ray" },
      ],
      [[Some(0.0), Some(10.0)], [Some(2.0), Some(30.0)]],
    )
    let grid = @well.depth_grid(0.0, 2.0, 1.0)
    let sampled = @well.resample(log, grid, 2.0)
    let result = @well.assemble(
      [log, sampled], ["original", "resampled"], grid, 2.0, Reject,
    )
    if result.log.rows[1][1] != Some(20.0) {
      abort("unexpected interpolation")
    }
    println(@well.write_csv(result.log))
    println(@well.report_text(@well.assembly_report(result)))
  } catch {
    @well.WellError(message) => abort(message)
  }
}
```

```sh
moon check --target wasm-gc --deny-warn
moon run . --target wasm-gc --deny-warn
```

预期 CSV 有深度 0、1、2，对应 GR 为 10、20、30；JSON 带逐单元来源。快速开始只构造分析模型，不伪造严格 LAS 所要求的井场元数据。

## 核心 API 与严格文档路径

完整公共接口见 [pkg.generated.mbti](pkg.generated.mbti)。三类下游流程的可执行代码见 [examples/main.mbt](examples/main.mbt)；[标准元数据示例](examples/compliance/main.mbt)验证合法 API 代码和客户节；[严格文档示例](examples/strict/main.mbt)验证标准诊断、两种 WRAP 写出及重复名称的归档/模型边界。

| 用途 | 公共入口与契约 |
|---|---|
| 读取和校验分析表 | `parse`、`make_log`、`validate`；有限 Double、唯一列名、非空单调索引 |
| 归档与标准检查 | `read_las_document` → `check_las2` / `las2_report`；`document_text` 返回接收的原始 String，接收成功本身不代表合法 |
| 严格数值转换 | `parse_strict` / `document_to_log`；合法但无法进入有限 Double/唯一列名模型的文档报 `model:`，不判成标准非法 |
| 严格写出 | `write_las_strict`；展开指数、精确检查十进制网格、重新验证输出，缺少井头或 WRAP 超宽时拒绝 |
| 对齐与缺失处理 | `depth_grid`、`resample`、`missing_spans`、`fill_linear`；必须显式最大间隔 |
| 单位/统计/区间 | `convert_curve`、`summarize`、`quantile`、`summarize_interval` |
| 整合与输出 | `assemble`、`assembly_report`、`provenance_csv`、`write_las`、`write_csv` |

在项目仓库中可直接运行完整流程：

```sh
moon run examples --target wasm-gc --deny-warn
moon run examples/compliance --target wasm-gc --deny-warn
moon run examples/strict --target wasm-gc --deny-warn
```

`parse` / `write_las` 是兼容分析接口，**不是标准合规声明**；canonical 写出不是原文归档。严格标准矩阵、处理案例、预算和独立复检终点见 [docs/las2-conformance.md](docs/las2-conformance.md)。基线不是最新修订或 CWLS 认证；后续规范未核验。正文 TIME 与附例 ETIM 的冲突按 2014 正文处理，不擅自扩大标准。

## IO-only Node CLI

在项目仓库内执行：

```sh
moon build --target js --release --deny-warn
node tools/moonwell.mjs fixtures/qa.json
node tools/moonwell.mjs fixtures/assemble.json result.json
node tools/moonwell.mjs fixtures/las2-api-codes.json
node tools/test-cli.mjs
```

CLI 只负责文件 IO，不自行解析 LAS 或计算统计。一个请求得到一个 JSON 信封：`{"ok":true,"result":...}` 或 `{"ok":false,"error":"..."}`。可选输出文件使用独占创建，**绝不覆盖已有文件**；再次使用同一路径会拒绝。退出码 0 为成功，1 为领域错误，2 为 IO/适配错误。请求必须是最多 16 MB 的普通文件。

命令有 `qa`、`normalize`、`csv`、`resample`、`interval`、`assemble`、`validate-las2`、`archive-las2`、`strict-normalize`。严格命令请求分别形如 `{"command":"validate-las2","las":"..."}`；省略号应替换为真实 LAS 字符串，不能作为有效数据。精确字段、返回 schema 和错误行为见 [docs/protocol.md](docs/protocol.md)，完整合成请求见 [fixtures/qa.json](fixtures/qa.json) 与 [fixtures/assemble.json](fixtures/assemble.json)。

## 检查、测试与构建

在项目仓库执行，最后更新接口并检查 diff：

```sh
moon info
moon fmt
moon fmt --check
moon check --target wasm-gc --deny-warn
moon test --target wasm-gc --deny-warn
moon build --target wasm-gc --release --deny-warn
python tools/audit.py
```

对 `wasm`、`js`、`native` 重复相应 check/test/build 和三个示例；native 执行需要 C 编译器。审阅 `moon info` 生成的 `.mbti` 差异，不能只看命令退出码。

独立交叉检查：

```sh
moon build --target js --release --deny-warn
python tools/make-conformance-corpus.py
python tools/verify-conformance.py
python -m pip install lasio==0.32 numpy==2.3.5
python tools/differential.py
python tools/verify-las2.py
```

105 个确定性严格正反例由 Python 结构/Decimal 检查器与 MoonBit 交叉判断，另有 32 个数值和 6 个元数据 lasio 案例。客户节只在 lasio 的参考副本中移除，不把该部分说成通过第三方检查。这些是有限样本证据，不证明不存在缺陷；当前完整测试数和核心行数以实际运行及 `tools/audit.py` 输出为准，不沿用历史数值冒充本轮结果。

## 限制与数据安全

- 不支持 LAS3、DLIS/LIS、逗号小数和厂商私有方言；不猜曲线别名、不自动深度平移，不提供储层解释、钻井建议或安全决策。质检阈值由调用方决定，无虚构性能优势。
- 源文档最多 16,000,000 String 代码单元、1,000,000 物理行、65,536 头条目、4,096 曲线、1,024 字符数值 token、256 条诊断。超预算是资源限制，不等于格式非法。分析表另限 512 列、1,000,000 行、10,000,000 单元；网格和各算法另有工作量预算。
- 原文可保留任意精度十进制；分析仍为有限 Double。空表可存在于内存，但不能写 LAS；写出拒绝 NULL 标记碰撞。应保留原文作为权威档案。
- 数组可读且可变：构造时深拷贝输入，变换重新验证并构造副本，报告出口重新验证；不支持并发变更。客户节内嵌深度不随单位转换更新；组装只保留首测次的井头/参数/客户文本，不能当成多份源文档的无损合并。
- 同容差内相等值保留较早来源，即使策略为 PreferLast；真实冲突记录先前/传入值，生成的深度单元没有测次主人。不同非空曲线 API 代码冲突必须显式解决。
- CSV 引号是结构转义，**不是电子表格公式防注入**。不可信测次名优先留在 JSON，或由表格消费者另行清洗；不得上传真实商业井数据、联系人、凭据或申报材料。主机还应限制恶意输入的进程时间与内存。

## 许可、来源与 AI 披露

本项目为原创实现，使用 [MIT 许可证](LICENSE)。生产仅依赖官方 `moonbitlang/core`；未复制 lasio 实现。lasio 0.32（MIT）和 NumPy 2.3.5（BSD）仅为可选测试 oracle，源码不打包。测试均为手写或确定性生成的合成数据，无商业井数据。CWLS 2014 原始标准来自 lasio 标准镜像，仅引用，不重新分发 PDF。完整来源与 SHA-256 见 [SOURCE_ATTRIBUTION.md](SOURCE_ATTRIBUTION.md)。

Codex 辅助选题研究、原创代码、测试、文档及交付自动化；参与者负责理解与维护。AI 辅助、全绿测试与交叉验证都不是行业正确性、安全或官方验收保证。

相关说明：[架构](docs/architecture.md)、[安全边界](SECURITY.md)、[有界语义查重](docs/competition/duplicate-check.md)、[变更记录](CHANGELOG.md)。申报书仅保存在仓库外本地，不属于源码包，也不自动报名。
