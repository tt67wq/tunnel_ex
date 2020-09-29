import Config

config :server, cfg_path: "~/.config/tunnel_ex/server_config.yml"

config :logger,
  backends: [:console, {LoggerFileBackend, :std}]

config :logger, :console,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:file]

config :logger, :std,
  format: "\n$time $metadata[$level] $message\n",
  path: "/var/log/tunnel_ex/server.log",
  level: :debug
