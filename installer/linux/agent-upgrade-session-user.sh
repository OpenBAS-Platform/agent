#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)

os=$(uname | tr '[:upper:]' '[:lower:]')

if [ "${os}" = "linux" ]; then
    if ! [ -d /run/systemd/system ]; then
      echo "Linux detected but without systemd, this installation is not supported"
      exit 1
    fi

    echo "Starting upgrade script for ${os} | ${architecture}"

    echo "01. Downloading OpenBAS Agent into $HOME/.local/openbas-agent-session..."
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o $HOME/.local/openbas-agent-session/openbas-agent_upgrade
    mv $HOME/.local/openbas-agent-session/openbas-agent_upgrade $HOME/.local/openbas-agent-session/openbas-agent
    chmod +x $HOME/.local/openbas-agent-session/openbas-agent

    echo "02. Updating OpenBAS configuration file"
    cat > $HOME/.local/openbas-agent-session/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF


    echo "03. Restarting the service"
    systemctl s--user restart openbas-agent-session || echo "Fail restarting openbas-agent-session"

    echo "OpenBAS Agent Session User started."
else
  echo "Operating system ${os} is not supported yet, please create a ticket in openbas github project"
  exit 1
fi