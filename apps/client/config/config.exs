import Config

config :client, cfg_path: "~/.config/tunnel_ex/client_config.yml"

config :logger,
  backends: [:console, {LoggerFileBackend, :std}]

config :logger, :console,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:file]

config :logger, :std,
  format: "\n$time $metadata[$level] $message\n",
  path: "/var/log/tunnel_ex/client.log",
  level: :debug
