#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)
if [ "${architecture}" = "arm64" ]; then
  architecture="arm64"
fi

os=$(uname | tr '[:upper:]' '[:lower:]')

if [ "${os}" = "linux" ]; then
    if ! [ -d /run/systemd/system ]; then
      echo "Linux detected but without systemd, this installation is not supported"
      exit 1
    fi

    echo "Starting install script for ${os} | ${architecture}"

    echo "01. Stopping existing openbas-agent..."
    systemctl stop openbas-agent || echo "Fail stopping openbas-agent"

    echo "02. Downloading OpenBAS Agent into /opt/openbas-agent..."
    (mkdir -p /opt/openbas-agent && touch /opt/openbas-agent >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o /opt/openbas-agent/openbas-agent
    chmod 755 /opt/openbas-agent/openbas-agent

    echo "03. Creating OpenBAS configuration file"
    cat > /opt/openbas-agent/openbas-agent-config.toml <<EOF
      debug=true
      [openbas]
      url = "${OPENBAS_URL}"
      token = "${OPENBAS_TOKEN}"
EOF

    echo "04. Writing agent service"
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

    echo "05. Starting agent service"
    (
      ln -sf /opt/openbas-agent/openbas-agent.service /etc/systemd/system/openbas-agent.service
      systemctl daemon-reload
      systemctl enable openbas-agent
      systemctl start openbas-agent
    ) || (echo "Error while enabling OpenBAS Agent systemd unit file or starting the agent" >&2 && exit 1)

    echo "OpenBAS Agent started."
else
  echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
  exit 1
fi