#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)
if [ "${architecture}" = "arm64" ]; then
  architecture="arm_64"
fi

os=$(uname | tr '[:upper:]' '[:lower:]')
if [ "${os}" = "darwin" ]; then
  os="macos"
fi

if [ "${os}" = "darwin" ]; then
    echo "Starting upgrade script for ${os} | ${architecture}"

    echo "01. Downloading OpenBAS Agent into /opt/openbas-agent..."
    (mkdir -p /opt/openbas-agent && touch /opt/openbas-agent >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o /opt/openbas-agent/openbas-agent_upgrade
    mv /opt/openbas-agent/openbas-agent_upgrade /opt/openbas-agent/openbas-agent
    chmod 755 /opt/openbas-agent/openbas-agent

    echo "02. Starting agent service"
    launchctl bootout system/ ~/Library/LaunchDaemons/openbas-agent.plist || echo "openbas-agent already stopped"
    launchctl bootstrap system/ ~/Library/LaunchDaemons/openbas-agent.plist

    echo "OpenBAS Agent started."
else
    echo "Operating system ${os} is not supported yet, please create a ticket in openbas github project"
    exit 1
fi