import Config

config :server, cfg_path: "~/.config/tunnel_ex/server_config.yml"


config :logger,
  backends: [:console]

config :logger, :console,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:file]
