#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)

install_dir="/opt/openbas-agent"
service_name="openbas-agent"

os=$(uname | tr '[:upper:]' '[:lower:]')
if [ "${os}" = "darwin" ]; then
  os="macos"
fi

if [ "${os}" != "macos" ]; then
  echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
  exit 1
fi

echo "Starting upgrade script for ${os} | ${architecture}"

echo "01. Downloading OpenBAS Agent into ${install_dir}..."
(mkdir -p ${install_dir} && touch ${install_dir} >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o ${install_dir}/openbas-agent_upgrade
mv ${install_dir}/openbas-agent_upgrade ${install_dir}/openbas-agent
chmod 755 ${install_dir}/openbas-agent

echo "02. Updating OpenBAS configuration file"
cat > ${install_dir}/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

echo "03. Starting agent service"
launchctl bootout system/ ~/Library/LaunchDaemons/${service_name}.plist || echo "openbas-agent already stopped"
launchctl bootstrap system/ ~/Library/LaunchDaemons/${service_name}.plist

echo "OpenBAS Agent started."