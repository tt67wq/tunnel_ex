# TunnelEx(网络穿透工具)

--------------

### 物理架构

![架构图](https://gitlab.jiliguala.com/alex_wan/tunnel_ex/raw/master/media/structure.png)


### 配置文件示例

- client 位于 /etc/tunnel_ex/client_config.yml

```

# client
client:
  host: 192.168.10.220 # localhost

# server
server:
  host: 192.168.10.101 # remote host
  port: 22000 # remote port

# log
logger:
  level: info
```

- server 位于 /etc/tunnel_ex/server_config.yml

```
# server cfg
server:
  port: 22000

# 转发配置
nat:
  - name: "server0"
    from: localhost:8080 # outside port
    to: 192.168.10.101:80 # inside port

  # - name: "server1"
  #   from: localhost:82
  #   to: 192.168.10.101:80

```


### 安装 & 执行

依赖 Elixir > 1.9, erlang > 21.0

- client
```
cd tunnel_ex/app/client
MIX_ENV=prod mix release --path ${your install_path}
cd ${your install_path}
./bin/client
```

- server
```
cd tunnel_ex/app/server
MIX_ENV=prod mix release --path ${your install_path}
cd ${your install_path}
./bin/server
```