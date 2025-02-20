#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)

os=$(uname | tr '[:upper:]' '[:lower:]')
if [ "${os}" = "darwin" ]; then
  os="macos"
fi

if [ "${os}" = "macos" ]; then
    echo "Starting upgrade script for ${os} | ${architecture}"

    echo "01. Downloading OpenBAS Agent into ~/.local/openbas-agent-session..."
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o ~/.local/openbas-agent-session/openbas-agent_upgrade
    mv ~/.local/openbas-agent-session/openbas-agent_upgrade ~/.local/openbas-agent-session/openbas-agent
    chmod +x ~/.local/openbas-agent-session/openbas-agent

    echo "02. Updating OpenBAS configuration file"
    cat > ~/.local/openbas-agent-session/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

    echo "03. Starting agent service"
    launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/openbas-agent-session.plist || echo "openbas-agent already stopped"
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/openbas-agent-session.plist

    echo "OpenBAS Agent Session User started."
else
    echo "Operating system ${os} is not supported yet, please create a ticket in openbas github project"
    exit 1
fi