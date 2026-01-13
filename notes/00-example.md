# 示例笔记：MCP 工具集成

> **课程**: 01-1 MCP 工具集成 · 和风天气
> **学习时间**: 2026-01-13
> **难度**: ⭐⭐⭐

## 核心概念

### MCP 协议

MCP (Model Context Protocol) 是一种用于 AI 智能体与工具通信的协议。它定义了：

- **服务器 (Server)**: 提供工具和资源的端点
- **客户端 (Client)**: 使用工具的 AI 智能体
- **工具 (Tools)**: 可执行的功能函数
- **资源 (Resources)**: 静态数据文件

### 和风天气 API 集成

本示例展示如何将和风天气 API 封装为 MCP 工具。

## 代码示例

### 天气服务器实现

```python
from mcp.server import Server
import httpx

app = Server("weather-server")

@app.tool("get_weather")
async def get_weather(location: str) -> str:
    """获取指定位置的天气信息"""
    api_key = "your_api_key"
    url = f"https://devapi.qweather.com/v7/weather/now?location={location}&key={api_key}"

    async with httpx.AsyncClient() as client:
        response = await client.get(url)
        data = response.json()

    return f"{location} 当前天气：{data['now']['text']}，温度 {data['now']['temp']}°C"
```

### 客户端调用

```python
from mcp.client import Client

client = Client()
await client.connect("weather-server")

result = await client.call_tool("get_weather", {"location": "北京"})
print(result)
```

## 关键要点

1. **MCP 服务器**: 使用 `@app.tool()` 装饰器注册工具
2. **异步处理**: 使用 `async/await` 处理异步请求
3. **类型提示**: 明确指定参数和返回值类型
4. **错误处理**: 添加适当的异常处理逻辑

## 实践练习

1. 尝试添加其他天气参数（如湿度、风力）
2. 实现天气预警查询功能
3. 添加缓存机制减少 API 调用

## 参考资源

- [MCP 官方文档](https://modelcontextprotocol.io/)
- [和风天气 API 文档](https://dev.qweather.com/)
- 原始代码位置: `Agent_In_Action/01-agent-tool-mcp/mcp-demo/`

---

*本笔记由 Agent Learner 自动生成*
