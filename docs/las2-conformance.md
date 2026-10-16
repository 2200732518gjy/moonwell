# LAS 2.0 标准处理、已实施规则与验收证据

更新时间：2026-10-16；实现版本：0.3.0。这是公开工程说明，不是申报书或认证证书。

## 基线与声明范围

本版本冻结 **CWLS LAS Committee《LAS Version 2.0: A Digital Standard for Logs》，January 2014 update**，不声称它是最新修订，也不声称取得 CWLS Certify 或主办方认证。作者原规范的可验证镜像位于 lasio 仓库 `standards/LAS_20_Update_Jan2014.pdf`；原文件 SHA256 为 `48c9bc54c782f374ef4e43d8a8bb10152b487217f099ff729897a6c89a1d7fda`。规范没有随包复制。未取得可校验的 2017 修订正文，因此不宣称已完成两版本差异比对。

规范 §4 明确打印文档优先于验证程序。其最后一个时间示例用 ETIM，而 §5.5 正文仅列 DEPT/DEPTH/TIME；这里按规范性正文接受 TIME，不以示例冲突扩大规则。DATE 的 yyyy mm dd 是建议格式，不强制非空或编造日期。文件扩展名 .LAS 属于文件交付约定；接收 String 的 API 不检查未知文件名。

## 四条显式处理路径

1. **原文档接收**：`read_las_document` / `document_text` 保存输入 String 的全部内容，不重建、不丢重复项、注释、空行、节顺序、CRLF、数值拼写。接收本身不是合法性判定，也允许保存待修复的非法文件；非文本原始字节及编码探测不在此 API 内。
2. **严格验证**：`check_las2` 返回 `LasDiagnostic {kind,clause,section,line,field,message}`；`las2_report` 返回 JSON。空诊断代表指定基线和公开预算内通过，不代表数据的地质真实性。缺失字段的 line=0 表示没有可定位的原文行。
3. **数值分析转换**：`document_to_log` / `parse_strict` 先严格验证，再转为唯一列名、有限 Double 的 `Log`。合法重复曲线/参数、超范围数、非零下溢、索引折叠或假 NULL 碰撞等转换问题以 `model:` 明确拒绝；原文仍可保存。这些不是把合法文档判成格式非法。`document_entries` 提供按原序包含重复项的头字段，坏头不会静默丢失。
4. **严格写出**：`write_las_strict` 无指数十进制输出，重新精确计算 STEP，随后再次严格验证。缺少井头、非整除网格或 WRAP 行放不下数值时拒绝，不编造井名/公司/位置，不四舍五入观测、不自动挪动 STRT。原有 `parse` / `write_las` 保持兼容用途；兼容成功从不等于严格通过。

## 条款—实现—正反例矩阵

全部合成案例在 `fixtures/las2-conformance.json`，每例包含名称、原文、预期、条款和模型可转换性。生成器 `tools/make-conformance-corpus.py` 确保可复现；严格实现位于 `strict.mbt`、`decimal.mbt`、`document.mbt`、`lex.mbt`、`writer.mbt`。

| 条款 | 已实施行为 | 正例 / 反例名称（示例） |
|---|---|---|
| §3/5.1 编码与标志 | ASCII 32..126、CRLF，最后行允许无终止符；# 只在 A 前；节标志大小写按正文 | no-final-terminator / encoding-tab、lf-not-crlf、data-comment |
| §3/5.3 节约束 | V 首节、A 末节；V/W/C/A 必须存在；保留节各最多一次；客户节自由保存 | extra-version-lines、optional-other-unstructured / missing-section-*、duplicate-section-*、section-after-ascii |
| §5.2 头字段 | 首点、点后首空格、末冒号；名称标点、前置空格、任意长度值、带点单位、值内冒号 | legal-mnemonic-punctuation、spaces-before-dot、units-may-contain-dots / header-delimiter-* |
| §5.3 版本 | VERS=2.0；WRAP=YES/NO；必需字段无单位、无歧义重复 | wrapped、complete-empty-metadata-values / invalid-version、invalid-wrap、duplicate-required-VERS |
| §5.4 井头完整性 | STRT/STOP/STEP/NULL/COMP/WELL/FLD/LOC/SRVC/DATE；PROV 或 CNTY+STAT+CTRY；UWI 或 API；空文本合法 | regional-identifiers、api-instead-of-uwi / missing-header-*、regional-alternative-missing、identifier-missing |
| §5.4 索引 | 深度 M/F/FT、可升可降；TIME 声明单位且递增；四处网格单位相同 | depth-unit-F、descending-depth、increasing-time / invalid-depth-unit、descending-time、mismatched-grid-unit |
| §5.4 精确数值 | BigInt 十进制比较端点、间隔及整除；非零 STEP 无容差；STEP=0 允许不规则单调索引 | equivalent-decimal-scales、irregular-zero-step / off-grid-integer-quotient、step-rounding、endpoint-rounding |
| §5.5 曲线 | 首列 DEPT/DEPTH/TIME，列顺序和宽度；API 代码为含空格/前导零的不透明字符串；重复名文档合法，Log 转换拒绝 | opaque-codes-spaces-leading-zero、duplicate-curve-document / invalid-depth-name、ragged-row |
| §5.6/5.7 可选信息 | 参数按头格式；Other/客户文本不解释；重复参数按原序存档 | optional-parameter-values-with-colons、customer-and-duplicate-parameter-document / 坏参数头走 header-delimiter 规则 |
| §5.8 ASCII | 数值十进制、无指数/NaN/逗号；索引非 NULL 严格单调；不允许空白/注释数据行 | missing-optional-api-code / invalid-number-*、index-null、data-blank、repeated-index |
| §5.3/5.8 WRAP | 索引独占一行、记录不串行、含前后填充和 CRLF 的物理行≤80；未终止末行按实际宽度 | wrapped-exact80、wrapped-exact80-unterminated / wrapped-too-wide-padding、wrapped-index-not-alone、wrapped-incomplete-record |
| 标准与模型隔离 | 合法极大/极小数保持原文，转换报 model；不把合法重复名删掉 | large-decimal-model-limit、underflow-model-limit、false-null-model-limit |

## 具体处理案例

- `GR.GAPI 07 010 01 00 : gamma` 的 API 代码全程原样保留，包括 select/rename/unit-convert/resample/affine/写出。两测次同名曲线不同非空码时 assemble 拒绝，即使样本策略 PreferLast，也不暗选元数据；先核实来源或显式拆列。
- `STRT=0.25, STEP=0.5` 的等间距文件：兼容 reader 可以读，严格验证报 §5.4 整除错误，严格写出拒绝，绝不挪动观测深度来伪装修复。
- 缺 COMP 等文本井头：严格报缺失；`COMP. : company` 的空值合法。该区别避免捏造个人/井场资料。
- E 指数：兼容数值读入可用；严格输入拒绝。Double 极小数及最大有限数的写出展开为往返等值的普通十进制；WRAP 超行预算则明确拒绝。
- 重复曲线、重复参数或 Double 无法表达的合法十进制：严格文档检查可通过，原文完全保留；分析转换单独报模型限制。
- `WELL. SYN:CASE : synthetic well`：值 SYN:CASE，描述 synthetic well；描述内冒号需调用方迁移到值，不能按首冒号悄悄拆错。

## 预算与无法处理时的保证

源文本最多 16,000,000 个 String 代码单元；最多 1,000,000 物理行、65,536 解析头条目、4,096 曲线；数值 token 最多 1,024 字符；最多返回 256 个诊断。超预算报 `resource`（源接收超限抛 `resource:`），**不是宣称标准禁止更大的合法文件**。未得到空诊断时不得宣称通过。String 保存仅保证其已接收文本，不承诺超过接收预算的归档服务。

分析层仍沿用有界有限 Double 和唯一名称要求，不能无损表示任意精度十进制；源文档才是审计原件。Log 的 canonical writer 不保存全部注释/布局；如需完整档案必须用 document_text。客户自由文本中的井深不会随数值单位转换改写。组装仅沿用首测次井头/参数/客户文本，不是多个源文档的无损合并。

## 可复现验收与终点

```sh
moon run examples/strict --target wasm-gc --deny-warn
moon build --target js --release --deny-warn
python tools/make-conformance-corpus.py
python tools/verify-conformance.py
python tools/differential.py
python tools/verify-las2.py
```

新增独立 Python 结构解析器和 Decimal 检查器，不复用 MoonBit 的合法性判断；在每个案例上比较预期、独立判定和 MoonBit 结果，并逐字验证原文保存。可转模型的正例严格归一化后再次交叉验证；模型受限正例必须给 model 错误。这是**本项目独立语言实现的交叉证据，不是外部认证**。既有 lasio 0.32 oracle 提供 32 个数值案例和 6 个元数据案例；lasio 对自由格式客户节不兼容，元数据 oracle 仅在它的副本中去掉客户节，完整客户节保存由源文档案例验证，不冒称 lasio 通过该部分。

终点已由“以后补完整性检查”改为可执行门禁：明确冻结的规范基线、上述条款全部落地、正反例和严格再验证、独立检查、四目标 CI、精确版本无凭据消费者。发布时必须逐项记录实际结果，不能把计划或单独 parse 成功当证明。未知解释争议、未核验的后续规范及第三方认证不包装为已完成；LAS3/DLIS/LIS、原始二进制/编码修复、地质解释不在本基线内。
