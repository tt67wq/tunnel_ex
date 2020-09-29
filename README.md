# TunnelEx(网络穿透工具)

--------------

### 物理架构

![架构图](https://gitlab.jiliguala.com/alex_wan/tunnel_ex/raw/master/media/structure.png)


### 配置文件示例

- client 位于 ~/.config/tunnel_ex/client_config.yml

```

# client
client:
  host: 192.168.10.220 # localhost

# server
server:
  host: 192.168.10.101 # remote host
  port: 22000 # remote port

# pool
pool:
  size: 5

```

- server 位于 ~/.config/tunnel_ex/server_config.yml

```
# server cfg
server:
  port: 22000

# 转发配置
nat:
  - name: "server0"
    from: localhost:8080 # outside port
    to: 192.168.10.101:80 # inside port

  - name: "server1"
    from: localhost:8081
    to: 192.168.10.101:81

```

### TODOLIST

- [x] 协议整理
- [x] 链接关闭事件
- [x] Release pkg
- [x] 用连接池提升效率
- [x] 日志
- [ ] UDP支持
- [ ] Server动态配置，穿透配置持久化
- [ ] Server Web


### 协议整理

  [协议内容](https://gitlab.jiliguala.com/alex_wan/tunnel_ex/blob/master/apps/common/lib/protocal.ex)


### 安装 & 执行

##### 1. RELEASE(目前只有Linux_x64的版本，其他平台的需要自己编译)

- [client](http://10.50.126.0:8000/tunnel_client_v1.1.zip)
- [server](http://10.50.126.0:8000/tunnel_server_v1.1.zip)

##### 2. 源码编译安装
依赖
```
Elixir >= 1.9
erlang >= 22.0
```

- client
```
cd tunnel_ex/app/client
MIX_ENV=prod mix release --path ${your install_path}
cd ${your install_path}
./bin/client --help
```

- server
```
cd tunnel_ex/app/server
MIX_ENV=prod mix release --path ${your install_path}
cd ${your install_path}
./bin/server --help
```