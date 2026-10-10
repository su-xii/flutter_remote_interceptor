# remote_interceptor

基于 [dio](https://pub.dev/packages/dio) 的**远程拦截调试桌面端**。

把被调试的 Flutter App（手机端）当作「无 UI 的调试终端」，由桌面端统一完成 **响应拦截改写**、**Mock 数据下发**、**页面跳转控制**，并提供 **MCP 接口**供 AI 调用。

---

## 一、它是怎么工作的

```
┌─────────────────────────────┐                    ┌──────────────────────────────┐
│  桌面端（本仓库）             │                    │  被调试 App（手机端）          │
│                             │                    │                              │
│  WsServer   0.0.0.0:8848 ◀──┼──── WebSocket ─────┼──▶ WsClient                  │
│  DiscoveryClient  ──────────┼─▶ UDP 8488 广播 ───┼──▶ DiscoveryServer           │
│  MCPServer  127.0.0.1:8765  │                    │  dio + RemoteInterceptor     │
└─────────────────────────────┘                    └──────────────────────────────┘
```

1. **设备发现**：桌面端周期性向 `255.255.255.255:8488` 广播 `HELLO`；手机端插件收到后回复设备标识。
2. **建立连接**：桌面端选中设备后单播 `CONNECT`；手机端收到后停止发现、主动拨号 `ws://<桌面IP>:8848`。
3. **响应拦截**：手机端每个 dio 响应都会经 WS 上报给桌面端，桌面端处理后回包，手机端用回包还原 `Response`。
4. **指令下发**：桌面端可反向下发指令（如跳转页面），手机端执行后回执。

> 通道与协议由插件 [`dio_remote_interceptor`](https://gitee.com/su_xii/dio_remote_interceptor) 提供，两端共用同一份协议定义。

---

## 二、功能

### 0. 全局

- 顶部 `LinkSwitch` 在**编辑模式 / Mock 模式**间切换（`PageView` 承载两页，互不干扰）。
- 右上角：**切换设备**、**服务状态**、**客户端连接状态**三个指示。
- 仅作为本地调试工具使用，不参与业务发版。

### 1. 编辑模式

| Tab | 内容 |
|---|---|
| **当前请求** | 拦截开关 + 队列计数 + JSON 编辑器（`re_editor`，带语法高亮/行号）；命中的请求会挂起，编辑后点「放行」回包 |
| **请求记录** | 历史请求列表，右键可 **放行**（拦截中）或 **添加到 Mock**（一键把该请求的响应转成全局 Mock 规则） |

### 2. Mock 模式

Mock 模式为**双 Tab**，二者**互斥，同一时刻只有一个生效**，且**切换 Tab 即切换生效策略**（Tab 上方的提示栏会显示当前生效项）。

#### 2.1 全局 Mock

- 规则列表：URL、HTTP 方法、备注、启用状态、**命中次数**（命中时播放动画）。
- 右下角 `+` 新增规则；点击卡片编辑，右侧可删除。
- 支持可选的**请求参数匹配**（`requestParam`）。
- **互斥规则**：同一 `URL + 方法` 的规则同时只生效一条，开启一条会自动禁用同组其它规则。

#### 2.2 页面级 Mock

以「页面」为配置单元，适合只 mock 当前页面所依赖的接口。

**页面列表**

- 显示页面名、路由地址、首字图标；搜索（名称/路由）、按分组筛选。
- 右上角：**添加页面**、**导入配置**、**导出配置**（均基于剪贴板，无需文件选择器）。
- **右键菜单**：`修改页面`（可改页面名与路由地址）、`删除页面`（二次确认）。
- 已应用的页面会显示「当前页面」徽标。
- **路由允许重复**，页面之间以唯一 `id` 区分。

**页面详情**

- **路由入参**：JSON 展示，可点「编辑」弹窗修改（同时作为跳转指令的 `arguments`）。
- **接口配置**：每个接口卡片包含 `方法徽标 + 路径 + 命中次数`，以及底部 `启用开关 + 状态 + 编辑 + 删除`。
  - 同一页面下允许多个接口配置，但**方法 + 路径相同的配置互斥**，同时只生效一个。
  - Mock 数据支持弹窗编辑与**全屏编辑**（必须是合法 JSON）。
- **右上角两个按钮，职责分离**：

| 按钮 | 职责 | 依赖客户端连接 |
|---|---|---|
| **进入页面** | 只向手机端下发跳转指令（路由 + 入参），并回显 下发中/成功/失败 | ✅ 需要 |
| **应用规则 / 取消应用** | 只让该页面的 Mock 配置生效 / 取消生效（取消后该策略不再命中任何接口） | ❌ 纯本地 |

- 命中路径匹配兼容两种写法：完整 URL 与纯路径（比对前会去掉 query / fragment）。

### 3. MCP（供 AI 调用）

MCP Server 监听 `127.0.0.1:8765`，路径 `/mcp`（JSON-RPC 2.0 over HTTP + SSE）。

| 工具 | 用途 |
|---|---|
| `add_mock_rule` | 新增一条**全局 Mock** 规则 |
| `list_mock_pages` | 列出 Mock 页面（可按 `keyword` / `group` 过滤） |
| `jump_mock_page` | 跳转页面，可选 `apply: true` 表示同时应用该页面规则 |
| `get_page_mock_data` | 获取页面关联接口及 Mock 数据（可按 `method` / `path` 过滤） |
| `get_current_page` | 获取当前生效页面与最近一次跳转指令状态 |

MCP 与 UI 读的是同一份状态，避免「两套真相」。

---

## 三、快速开始

### 前置条件

- Flutter SDK `^3.6.0`（桌面端已启用）
- 插件源码：`dio_remote_interceptor`（当前 `pubspec.yaml` 使用**本地 path 依赖**）

### 安装与运行

```bash
# 1. 确认插件路径（pubspec.yaml）
#    dio_remote_interceptor:
#      path: ../../Dart/dio_remote_interceptor

flutter pub get
flutter run -d windows     # 或 -d macos / -d linux
```

打包调试版：

```bash
flutter build windows --debug
```

静态检查：

```bash
flutter analyze
```

> ⚠️ 重新构建前请先关闭正在运行的 `remote_interceptor.exe`，否则输出目录被占用会导致 `INSTALL.vcxproj` 报 `MSB3073`。

---

## 四、被调试端（手机 App）接入

```dart
// main.dart —— 仅 Debug 生效
if (kDebugMode) {
  dio.interceptors.add(
    RemoteInterceptor.create(
      "Pixel-8-Dev",                       // 设备标识，桌面端据此识别
      // 桌面端下发 jump 指令时触发；形态与宿主路由封装对齐
      onNavigate: (String page, {dynamic arguments}) {
        RouteUtils.toNamed(page, arguments: arguments);
      },
    ),
  );
}
```

要点：

- `onNavigate` 的入参形态与 `RouteUtils.toNamed(page, {arguments})` 一致，宿主只需透传。
- **不要直接操作 `Navigator`**，必须走宿主自有路由封装，保证登录校验、埋点等逻辑不被绕过。
- 被调试的业务页面**无需任何改动**，也不需要新增任何 UI。
- `create` 内部自行持有 `RemoteResponseClient`，需要显式管理生命周期时改用
  `RemoteInterceptor(RemoteResponseClient())` 以拿到句柄调用 `stop()`。

示例见插件仓库 `example/run_remote_client_with_navigate.dart`。

---

## 五、通信协议

消息体为**平铺结构**，通过顶层 `type` 判别类型（缺省 `http`，保证向后兼容）。

| `type` | 方向 | 说明 | 是否回包 |
|---|---|---|---|
| `http`（缺省） | 手机 → 桌面 | 响应上报，字段全部平铺（`requestId` / `statusCode` / `headers` / `data` / `requestOptions` / `requestTime` …） | 是 |
| `command` | 桌面 → 手机 | 指令下发 | 否 |
| `commandResult` | 手机 → 桌面 | 指令回执 | 否 |
| `ping` | 手机 → 桌面 | 心跳保活（15s） | 否 |

### 跳转指令

桌面 → 手机：

```json
{
  "type": "command",
  "commandId": "1730000000000_123",
  "action": "jump",
  "payload": {
    "pageId": "page_1730000000000001",
    "page": "/user/detail",
    "arguments": { "userId": "12345" }
  }
}
```

手机 → 桌面回执：

```json
{
  "type": "commandResult",
  "commandId": "1730000000000_123",
  "action": "jump",
  "success": true,
  "message": ""
}
```

`type` 为 `commandResult`（及预留的 `event`）的消息，桌面端**只回调、不回包**，避免手机端收到自己的回声。

---

## 六、本地存储

均使用 `shared_preferences`：

| Key | 内容 |
|---|---|
| `MockRuleStore` | 全局 Mock 规则 |
| `MockPageStore` | 页面级 Mock 页面配置（含路由入参、接口 Mock 数据） |
| `DeviceDiscoveryHistoryStore` | 手动添加的设备历史 |

> 命中次数为**内存态**，不落盘，重启归零。

---

## 七、目录结构

```
lib/
├── main.dart                 入口（窗口 600x800）
├── application.dart          生命周期：启动/停止 WS Server 与 MCP Server
├── router/router_util.dart   go_router 路由表
├── model/                    数据模型（MockRule / MockPageConfig / RequestRecord / DeviceModel …）
├── state/                    Riverpod 状态类（HomeState / MockPageState / ResponseEditState …）
├── viewmodel/                StateNotifier 业务逻辑
├── providers/                依赖注入（Provider / StateNotifierProvider）
├── server/                   RemoteServer（WS 服务端封装）、DeviceDiscoveryServer（UDP 发现）
├── data/local/               SharedPreferences 持久化
├── page/                     页面（设备发现 / 首页 / 编辑模式 / Mock 模式）
├── dialog/                   各类弹窗（Mock 规则、页面、路由入参、接口、请求详情 …）
├── widgets/                  通用组件（JSON 预览、命中计数、右键菜单、方法徽标 …）
└── mcp/                      MCP Server 与工具实现
```

技术栈：`flutter_riverpod`（状态管理）、`go_router`（路由）、`re_editor`（JSON 编辑器）、`window_manager`（窗口）、`shared_preferences`（存储）。

---

## 八、已知限制

| 限制 | 说明 |
|---|---|
| 一对一连接 | WS 服务端只保留最新一个客户端，新连接会顶替旧连接，暂不支持多设备并发调试 |
| 无自动重连 | 插件侧 WS 重连已禁用，断线后依赖重新走 UDP 发现流程 |
| 页面感知 | 手机端未上报页面切换（`pageChanged`），当前页面由桌面端的「应用规则」决定，**手机端手动导航时桌面端无法感知** |
| 页面结构 / 截图 | MCP 的 Widget 树导出与截图能力为二期规划，暂未实现 |
| 未做能力 | 单接口粒度的 Mock 开关（字段已预留）、跳转历史、收藏、远程配置热更新 |
