#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)

os=$(uname | tr '[:upper:]' '[:lower:]')
install_dir="$HOME/.local/openbas-agent-session"
service_name="openbas-agent-session"

if [ "${os}" = "linux" ]; then
    if ! [ -d /run/systemd/system ]; then
      echo "Linux detected but without systemd, this installation is not supported"
      exit 1
    fi

    echo "Starting install script for ${os} | ${architecture}"

    echo "01. Stopping existing openbas-agent-session..."
    systemctl --user stop ${service_name} || echo "Fail stopping ${service_name}"

    echo "02. Downloading OpenBAS Agent into ${install_dir}..."
    (mkdir -p ${install_dir} && touch ${install_dir} >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to ${install_dir}\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o ${install_dir}/openbas-agent
    chmod +x ${install_dir}/openbas-agent

    echo "03. Creating OpenBAS configuration file"
    cat > ${install_dir}/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

    echo "04. Writing agent service"
    cat > ${install_dir}/${service_name}.service <<EOF
      [Unit]
      Description=OpenBAS Agent Session
      After=network.target
      [Service]
      Type=exec
      ExecStart=${install_dir}/openbas-agent
      StandardOutput=journal
      [Install]
      WantedBy=default.target
EOF

    echo "05. Starting agent service"
    (
      ln -sf ${install_dir}/${service_name}.service $HOME/.config/systemd/user/
      systemctl --user daemon-reload
      systemctl --user enable ${service_name}
      systemctl --user start ${service_name}
    ) || (echo "Error while enabling OpenBAS Agent systemd unit file or starting the agent" >&2 && exit 1)

    echo "OpenBAS Agent started."
else
  echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
  exit 1
fi