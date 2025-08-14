#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)
user="$(id -un)"
group="$(id -gn)"
systemd_status=$(systemctl is-system-running)

os=$(uname | tr '[:upper:]' '[:lower:]')
install_dir="${OPENBAS_INSTALL_DIR}-${user}"
service_name="${user}-${OPENBAS_SERVICE_NAME}"

if [ "${os}" != "linux" ]; then
  echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
  exit 1
fi

if [ "$systemd_status" != "running" ] && [ "$systemd_status" != "degraded" ]; then
  echo "Systemd is in unexpected state: $systemd_status. Installation is not supported."
  exit 1
else
  echo "Systemd is in acceptable state: $systemd_status"
fi

echo "Starting upgrade script for ${os} | ${architecture}"


echo "01. Downloading OpenBAS Agent into ${install_dir}..."
(mkdir -p ${install_dir} && touch ${install_dir} >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to ${install_dir}\n" >&2 && exit 1)
curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o ${install_dir}/openbas-agent_upgrade
mv ${install_dir}/openbas-agent_upgrade ${install_dir}/openbas-agent
chmod +x ${install_dir}/openbas-agent

echo "02. Updating OpenBAS configuration file"
cat > ${install_dir}/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
installation_mode = "service-user"
service_name = "${OPENBAS_SERVICE_NAME}"
EOF

echo "03. Kill the process of the existing service"
(pkill -9 -f "${install_dir}/openbas-agent") || (echo "Error while killing the process of the openbas agent service" >&2 && exit 1)
echo "The OpenBAS agent process was stopped, the service will automatically restart in 60 seconds"
