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

    echo "Starting install script for ${os} | ${architecture}"

    echo "01. Stopping existing openbas-agent-session..."
    systemctl --user stop openbas-agent-session || echo "Fail stopping openbas-agent-session"

    echo "02. Downloading OpenBAS Agent into $HOME/.local/openbas-agent-session..."
    (mkdir -p $HOME/.local/openbas-agent-session && touch $HOME/.local/openbas-agent-session >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to $HOME/.local\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o $HOME/.local/openbas-agent-session/openbas-agent
    chmod +x $HOME/.local/openbas-agent-session/openbas-agent

    echo "03. Creating OpenBAS configuration file"
    cat > $HOME/.local/openbas-agent-session/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

    echo "04. Writing agent service"
    cat > $HOME/.local/openbas-agent-session/openbas-agent-session.service <<EOF
      [Unit]
      Description=OpenBAS Agent Session
      After=network.target
      [Service]
      Type=exec
      ExecStart=$HOME/.local/openbas-agent-session/openbas-agent
      StandardOutput=journal
      [Install]
      WantedBy=default.target
EOF

    echo "05. Starting agent service"
    (
      ln -sf $HOME/.local/openbas-agent-session/openbas-agent-session.service $HOME/.config/systemd/user/
      systemctl --user daemon-reload
      systemctl --user enable openbas-agent-session
      systemctl --user start openbas-agent-session
    ) || (echo "Error while enabling OpenBAS Agent systemd unit file or starting the agent" >&2 && exit 1)

    echo "OpenBAS Agent started."
else
  echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
  exit 1
fi