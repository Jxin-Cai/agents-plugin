# 性能分析原则

本文档定义了性能分析（Profiling）阶段必须遵循的原则。基于 Brendan Gregg 的 USE 方法论、Intel TMA（Top-Down Microarchitecture Analysis）框架和行业最佳实践。

---

## 1. USE 方法论

对每个系统资源系统化检查三个维度，确保不遗漏瓶颈：

### 利用率（Utilization）
- 资源在采样时间窗口内的忙碌比例
- CPU：用户态 + 内核态占比
- 内存：已用内存 / 总内存
- 磁盘：I/O 带宽利用率、IOPS 利用率
- 网络：带宽利用率

### 饱和度（Saturation）
- 资源的过载程度——排队等待的工作量
- CPU：运行队列长度（Run Queue）、负载均值（Load Average）
- 内存：换页频率（Swap In/Out）、OOM Kill 事件
- 磁盘：I/O 等待队列长度、await 时间
- 网络：丢包率、重传率、TCP 连接排队

### 错误（Errors）
- 资源相关的错误事件
- CPU：Machine Check Exceptions
- 内存：ECC 错误、分配失败
- 磁盘：读写错误、坏块
- 网络：CRC 错误、帧错误

**执行顺序**：先检查错误（最快定位问题），再检查利用率（最直观），最后检查饱和度（最深层）。

---

## 2. 瓶颈分类与定位

### CPU-bound（计算密集型）
**症状**：CPU 利用率持续 > 80%，I/O 等待低
**定位工具**：
- CPU Profiler（采样型）：perf、async-profiler、py-spy
- 火焰图（Flame Graph）：将 CPU 时间分布可视化
- 热点函数分析：Top N 耗时函数

**常见根因**：
- 低效算法（O(n^2) 可优化为 O(n log n)）
- 过度序列化/反序列化
- 正则表达式灾难性回溯
- 锁竞争导致的自旋等待
- GC 频繁导致的 STW（Stop The World）

### Memory-bound（内存密集型）
**症状**：内存使用持续增长、GC 频率升高、出现 OOM
**定位工具**：
- 堆分析：jmap、heapdump、memory_profiler
- GC 日志分析：GC Viewer、GCeasy
- 泄漏检测：Valgrind/Memcheck、LeakCanary

**常见根因**：
- 内存泄漏（未关闭的连接、缓存无上限、事件监听未移除）
- 大对象频繁分配（导致 Full GC）
- 缓存数据结构膨胀
- 线程局部变量（ThreadLocal）未清理

### I/O-bound（I/O 密集型）
**症状**：CPU 利用率低但响应慢、I/O 等待高
**定位工具**：
- 磁盘 I/O：iostat、blktrace、fio
- 网络 I/O：tcpdump、ss、netstat
- 数据库：慢查询日志、执行计划分析

**常见根因**：
- 数据库慢查询（缺索引、全表扫描、N+1 查询）
- 同步 I/O 阻塞线程池
- 连接池配置不当（过小导致排队，过大导致数据库压力）
- 网络延迟（跨区域调用、DNS 解析）

### 锁竞争（Lock Contention）
**症状**：CPU 利用率不高但吞吐上不去，线程大量 BLOCKED/WAITING
**定位工具**：
- 线程转储分析：jstack、Thread Dump Analyzer
- 锁分析：perf lock、async-profiler lock mode
- 死锁检测：jcmd Thread.print

**常见根因**：
- 粗粒度锁（整个方法或对象加锁）
- 数据库行锁/表锁冲突
- 分布式锁超时配置不当
- 线程池饱和导致任务排队

---

## 3. 火焰图分析方法

### 阅读火焰图
- **X 轴**：采样中出现的函数（按字母排序，非时间轴）
- **Y 轴**：调用栈深度（越高越深）
- **宽度**：函数在采样中出现的频率（越宽 = 占 CPU 时间越多）
- **颜色**：通常无语义，仅用于视觉区分

### 分析步骤
1. 从最宽的"平台"开始看——这是占 CPU 最多的函数
2. 向下追踪——谁调用了它？
3. 向上追踪——它调用了什么？
4. 关注"尖塔"——深而窄的调用栈可能是递归或低效调用
5. 比较优化前后的火焰图——diff 火焰图

### 常见模式识别
- **宽平台在 GC 函数**：内存压力大，需优化内存分配
- **宽平台在序列化函数**：JSON/XML 解析成瓶颈，考虑换格式或缓存
- **宽平台在锁相关函数**：锁竞争严重
- **大量采样在内核态**：系统调用开销大，可能是 I/O 问题

---

## 4. 分布式系统追踪

### 分布式追踪原则
- 使用 OpenTelemetry 标准采集 Trace/Span 数据
- 关注跨服务调用的延迟分解：网络延迟 vs 处理延迟
- 识别关键路径（Critical Path）——优化非关键路径不会提升端到端延迟
- Trace 采样策略：全量采集 → 头部采样 → 尾部采样（优先采集慢请求）

### 微服务性能分析要点
- 服务扇出度（Fan-out）：一个请求触发多少下游调用？
- 串行 vs 并行调用：能并行的调用是否做了并行？
- 重试风暴：重试策略是否配置了退避和上限？
- 级联超时：上游超时应大于下游超时之和

---

## 5. 数据库性能分析

### 慢查询分析
- 开启慢查询日志（MySQL: slow_query_log, PG: log_min_duration_statement）
- 用 EXPLAIN/EXPLAIN ANALYZE 分析执行计划
- 关注：全表扫描、文件排序、临时表、嵌套循环连接

### 连接池分析
- 监控活跃连接数 vs 最大连接数
- 连接等待时间（获取连接的排队延迟）
- 连接泄漏检测（长时间持有未释放的连接）

### 索引分析
- 未命中索引的查询（Index Miss）
- 冗余索引（浪费写入性能和存储）
- 索引碎片化程度

---

## 6. Profiling 工具速查表

### JVM 生态
| 工具 | 用途 | 开销 |
|------|------|------|
| async-profiler | CPU/内存/锁分析 | 极低（< 2%） |
| JFR (Flight Recorder) | 全方位事件采集 | 低（< 1%） |
| jstack | 线程转储快照 | 瞬时 |
| jmap + MAT | 堆内存分析 | 高（STW） |
| Arthas | 在线诊断，方法级追踪 | 中 |

### 通用 Linux
| 工具 | 用途 | 命令示例 |
|------|------|---------|
| perf | CPU 采样分析 | `perf record -g -p PID` |
| top/htop | 实时资源概览 | `htop -p PID` |
| vmstat | 系统级内存/CPU/IO | `vmstat 1` |
| iostat | 磁盘 I/O 分析 | `iostat -xz 1` |
| ss/netstat | 网络连接状态 | `ss -tnp` |
| strace | 系统调用追踪 | `strace -c -p PID` |

### Python 生态
| 工具 | 用途 |
|------|------|
| py-spy | CPU 采样（不侵入进程） |
| memory_profiler | 逐行内存分析 |
| cProfile | 内置函数级 CPU 分析 |
| scalene | CPU + 内存 + GPU 综合分析 |
