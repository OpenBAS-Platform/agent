#!/bin/sh
set -e
echo "Downloading OpenBAS Agent into /opt/openbas-agent..."
(mkdir -p /opt/openbas-agent && touch /opt/openbas-agent >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
curl -sSf http://localhost:8000/openbas-agent -o /opt/openbas-agent/openbas-agent
chmod 755 /opt/openbas-agent/openbas-agent

cat > /opt/openbas-agent/openbas-agent-config.toml <<EOF
debug=true
[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
EOF


if [ -d /etc/systemd/system -a  "$(systemctl is-system-running)" != "offline" ]; then
  echo "Detected init: systemd"

  cat > /opt/openbas-agent/openbas-agent.service <<EOF
[Unit]
Description=OpenBAS Agent
After=network.target
[Service]
Type=exec
ExecStart=/opt/openbas-agent/openbas-agent
StandardOutput=journal
[Install]
WantedBy=multi-user.target
EOF

  (
    ln -sf /opt/openbas-agent/openbas-agent.service /etc/systemd/system/openbas-agent.service
    systemctl daemon-reload
    systemctl enable openbas-agent
    systemctl start openbas-agent
  ) || (echo "Error while enabling OpenBAS Agent systemd unit file or starting the agent" >&2 && exit 1)

  echo "OpenBAS Agent started... Runtime status:\n"
  systemctl status openbas-agent
  exit 0
fi


echo "No init found, you need to configure it yourself to start /opt/openbas-agent/openbas-agent at startup"