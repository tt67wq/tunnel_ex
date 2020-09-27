import Config

config :client, cfg_path: "~/.config/tunnel_ex/client_config.yml"

config :logger,
  backends: [:console]

config :logger, :console,
  format: "\n$time $metadata[$level] $message\n",
  metadata: [:file]
