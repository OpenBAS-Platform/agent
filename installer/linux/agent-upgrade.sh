#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)

os=$(uname | tr '[:upper:]' '[:lower:]')
install_dir="/opt/openbas-agent"
service_name="openbas-agent"

if [ "${os}" != "linux" ]; then
  echo "Operating system ${os} is not supported yet, please create a ticket in openbas github project"
  exit 1
fi

if ! [ -d /run/systemd/system ]; then
  echo "Linux detected but without systemd, this installation is not supported"
  exit 1
fi

echo "Starting upgrade script for ${os} | ${architecture}"

echo "01. Downloading OpenBAS Agent into ${install_dir}..."
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

echo "03. Restarting the service"
systemctl restart ${service_name} || (echo "Fail restarting ${service_name}" >&2 && exit 1)

echo "OpenBAS Agent started."