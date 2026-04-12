# 性能分析原则

基于 Brendan Gregg USE 方法论、Intel TMA 框架和行业最佳实践。

---

## 1. USE 方法论

对每个资源检查三个维度（执行顺序：错误→利用率→饱和度）：

| 资源 | 利用率(U) | 饱和度(S) | 错误(E) |
|------|----------|----------|---------|
| CPU | 用户态+内核态占比 | 运行队列长度/负载均值 | Machine Check Exceptions |
| 内存 | 已用/总内存 | 换页频率/OOM Kill | ECC 错误/分配失败 |
| 磁盘 | I/O 带宽/IOPS | 等待队列/await | 读写错误/坏块 |
| 网络 | 带宽利用率 | 丢包率/重传/TCP 排队 | CRC/帧错误 |

## 2. 瓶颈分类

| 类型 | 症状 | 工具 | 常见根因 |
|------|------|------|---------|
| CPU-bound | CPU>80%, I/O 等待低 | perf/async-profiler/py-spy + 火焰图 | 低效算法、过度序列化、正则回溯、锁自旋、GC STW |
| Memory-bound | 内存持续增长/GC 频繁/OOM | jmap/heapdump/memory_profiler | 泄漏(未关闭连接/缓存无上限)、大对象频繁分配、ThreadLocal 未清理 |
| I/O-bound | CPU 低但响应慢/I/O 等待高 | iostat/tcpdump/慢查询日志 | 缺索引/全表扫描/N+1、同步 I/O 阻塞、连接池配置不当 |
| Lock Contention | CPU 不高吞吐上不去 | jstack/perf lock/async-profiler lock | 粗粒度锁、DB 行锁/表锁、分布式锁超时、线程池饱和 |

## 3. 火焰图分析

- X 轴=函数（字母序，非时间），Y 轴=调用深度，宽度=CPU 占比
- 分析步骤：最宽平台→向下追踪调用者→向上追踪被调用→关注窄尖塔→diff 对比
- 模式识别：GC 函数宽平台=内存压力 | 序列化函数宽=换格式/缓存 | 锁函数宽=竞争 | 大量内核态=I/O

## 4. 分布式追踪

- 使用 OpenTelemetry 采集 Trace/Span，关注跨服务延迟分解（网络 vs 处理）
- 识别关键路径——优化非关键路径不提升端到端延迟
- 采样策略：全量→头部采样→尾部采样（优先慢请求）
- 微服务要点：扇出度、串行→并行、重试退避+上限、级联超时（上游 > 下游之和）

## 5. 数据库分析

- **慢查询**：开启日志（MySQL: slow_query_log, PG: log_min_duration_statement），EXPLAIN ANALYZE 分析
- **关注**：全表扫描、文件排序、临时表、嵌套循环连接
- **连接池**：活跃数 vs 最大数、等待延迟、泄漏检测
- **索引**：未命中查询、冗余索引、碎片化

## 6. 工具速查

**JVM**：async-profiler(CPU/内存/锁,<2%) | JFR(全方位,<1%) | jstack(线程快照) | jmap+MAT(堆分析,STW) | Arthas(在线诊断)

**Linux**：perf(CPU采样) | htop(资源概览) | vmstat(系统级) | iostat(磁盘I/O) | ss(网络连接) | strace(系统调用)

**Python**：py-spy(CPU,不侵入) | memory_profiler(逐行内存) | cProfile(函数级CPU) | scalene(CPU+内存+GPU)
