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

# log
logger:
  level: info
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

  # - name: "server1"
  #   from: localhost:82
  #   to: 192.168.10.101:80

```

### TODOLIST

- [x] 协议整理
- [ ] 链接关闭事件
- [ ] UDP支持
- [ ] Server动态配置
- [ ] Server Web
- [ ] Release pkg

### 协议整理

  1. 建立连接阶段

  client连接上server后，会主动上报自己的ip，这个ip不用是真实ip，只是用来标识一个连接，上报ip的格式为

  ```
  | 0x09 | 0x01 | ip0 | ip1 | ip2 | ip3 |
  ```
  以192.168.10.1为例子，上报的packet为 <0x09, 0x01, ip0, ip1, ip2, ip3>
  server接收到这个packet之后，会发送回执
  ```
  |0x09 | 0x02 |
  ```
  client收到后表示握手结束。

  2. 外部新的tcp连接建立阶段

  当新的外部流量与server建立新的tcp连接， server会发送packet给client，告知有新的tcp连接接入，让client与对应的内网端口建立连接。
  packet格式如下
  ```
  | key::16 | client_port::16 | 0x09, 0x03 |
  ```
  2字节长度的key用于标识server端的外部连接， 2字节长的client_port表示内网端口，后面9，3两个数字固定

  client收到该packet后，主动建立到client_port的连接，这里不予回执，因为有些软件会在建立tcp连接后有回执内容，如果协议中加上回执，可能会造成混淆。

  3. 通信阶段

  当连接都建立完毕，外部流量包在转发时，会带上4字节前缀，格式如下：
  ```
  | key::16 | client_port::16 | real packet |
  ```
  与建立连接阶段一致，2字节长度的key用于标识server端的外部连接， 2字节长的client_port表示内网端口。
  client接收到内部回复的流量，在转发时会带上2字节前缀, 格式如下：
  ```
  | key::16 | real packet |
  ```
  服务端接收到会根据key来找到对应的外部连接，并吐出真实流量。


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