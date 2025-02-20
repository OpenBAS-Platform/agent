#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)
user="$(id -un)"
group="$(id -gn)"

os=$(uname | tr '[:upper:]' '[:lower:]')
if [ "${os}" = "darwin" ]; then
  os="macos"
fi

if [ "${os}" = "macos" ]; then
    echo "Starting upgrade script for ${os} | ${architecture}"

    echo "01. Downloading OpenBAS Agent into /opt/openbas-agent-service-${user}..."
    (mkdir -p /opt/openbas-agent-service-${user} && touch /opt/openbas-agent-service-${user} >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o /opt/openbas-agent-service-${user}/openbas-agent_upgrade
    mv /opt/openbas-agent-service-${user}/openbas-agent_upgrade /opt/openbas-agent-service-${user}/openbas-agent
    chmod +x /opt/openbas-agent-service-${user}/openbas-agent

    echo "02. Updating OpenBAS configuration file"
    cat > /opt/openbas-agent-service-${user}/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

    echo "03. Kill the process of the existing service"
    (pkill -9 -f "/opt/openbas-agent-service-${user}/openbas-agent") || (echo "Error while killing the process of the openbas agent service" >&2 && exit 1)
    echo "The OpenBAS agent process was stopped, the service will automatically restart in 60 seconds"
else
    echo "Operating system ${os} is not supported yet, please create a ticket in openbas github project"
    exit 1
fi