# V2Ray for Koyeb

使用 Docker 在 Koyeb 上部署 V2Ray，提供 Nginx + WebSocket + VMess/VLESS。容器以非 root 用户运行，当前内置 V2Ray `v5.52.0`，支持 `linux/amd64` 和 `linux/arm64`。

> 请遵守服务所在地及使用者所在地的法律法规。本项目仅用于合法的网络与隐私保护用途。

## 一键部署

[![Deploy to Koyeb](https://www.koyeb.com/static/images/deploy/button.svg)](https://app.koyeb.com/deploy?type=git&builder=docker&repository=github.com/wxcydzcc/V2&branch=main&name=v2ray&ports=8080;http;/&env[UUID]=REPLACE_WITH_YOUR_UUID)

部署前请把 `REPLACE_WITH_YOUR_UUID` 替换为你自己的 UUID。建议在 Koyeb 中创建 Secret，并将它绑定到 `UUID` 环境变量，不要把真实 UUID 提交到仓库。

生成 UUID：

```powershell
[guid]::NewGuid().ToString()
```

## 环境变量

| 变量 | 必须 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `UUID` | 是 | 无 | VMess 与 VLESS 客户端 UUID，必须是有效 UUID |
| `VMESS_WSPATH` | 否 | `/vmess` | VMess WebSocket 路径 |
| `VLESS_WSPATH` | 否 | `/vless` | VLESS WebSocket 路径 |

两个 WebSocket 路径必须不同、以 `/` 开头，且只能包含 URL 路径安全字符。

## 运行参数

- 容器端口：`8080`
- 健康检查：`GET /healthz`
- TLS：由 Koyeb 边缘代理终止
- VMess：WebSocket，内部端口 `10000`
- VLESS：WebSocket，内部端口 `20000`，`decryption=none`

## 本地构建

```bash
docker build -t v2-koyeb .
docker run --rm -p 8080:8080 \
  -e UUID=7b21e8d4-8b31-4dd8-a2c8-394ea642ce47 \
  v2-koyeb
```

访问 `http://127.0.0.1:8080/healthz` 应返回 `ok`。

## 自动构建

GitHub Actions 会在 Pull Request、`main` 分支推送和每周定时任务中执行 ShellCheck、镜像构建、配置校验及容器健康检查。

手动运行工作流或推送到 `main` 时，如果配置了以下仓库 Secrets，还会发布 `amd64`/`arm64` 镜像到 Docker Hub；没有配置时会正常跳过发布，不影响构建检查：

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`：建议使用 Docker Hub access token
- `DOCKER_REPO`

发布标签为 `latest` 和 `v5.52.0`。

## 更新 V2Ray

升级版本时，需要同时更新 Dockerfile 中的版本号以及官方发布资产对应的 SHA-256。构建阶段会验证摘要，摘要不匹配时拒绝生成镜像。

## 致谢

项目基于 [fscarmen2/V2-for-Koyeb](https://github.com/fscarmen2/V2-for-Koyeb) 调整。

