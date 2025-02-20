#!/bin/sh
set -e

# --- Parse command-line arguments ---
USER_ARG=""
GROUP_ARG=""

while [ $# -gt 0 ]; do
  case "$1" in
    --user)
      shift
      USER_ARG="$1"
      ;;
    --group)
      shift
      GROUP_ARG="$1"
      ;;
    *)
      echo "Usage: $0 --user [user] --group [group]"
      exit 1
      ;;
  esac
  shift
done

# --- Validate that user and group are provided ---
if [ -z "$USER_ARG" ]; then
  echo "Error: --user argument is required and cannot be empty."
  exit 1
fi

if [ -z "$GROUP_ARG" ]; then
  echo "Error: --group argument is required and cannot be empty."
  exit 1
fi

# --- Verify that the user exists ---
if ! id "$USER_ARG" >/dev/null 2>&1; then
  echo "Error: User '$USER_ARG' does not exist."
  exit 1
fi

# --- Verify that the group exists ---
if ! getent group "$GROUP_ARG" >/dev/null 2>&1; then
  echo "Error: Group '$GROUP_ARG' does not exist."
  exit 1
fi

base_url=${OPENBAS_URL}
architecture=$(uname -m)
user="$USER_ARG"
group="$GROUP_ARG"

os=$(uname | tr '[:upper:]' '[:lower:]')

if [ "${os}" = "linux" ]; then
    if ! [ -d /run/systemd/system ]; then
      echo "Linux detected but without systemd, this installation is not supported"
      exit 1
    fi

    echo "Starting install script for ${os} | ${architecture}"

    echo "01. Stopping existing openbas-agent-${user}..."
    systemctl stop ${user}-openbas-agent || echo "Fail stopping ${user}-openbas-agent"

    echo "02. Downloading OpenBAS Agent into /opt/openbas-agent-service-${user}..."
    (mkdir -p /opt/openbas-agent-service-${user} && touch /opt/openbas-agent-service-${user} >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o /opt/openbas-agent-service-${user}/openbas-agent
    chmod +x /opt/openbas-agent-service-${user}/openbas-agent

    echo "03. Creating OpenBAS configuration file"
    cat > /opt/openbas-agent-service-${user}/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

    echo "04. Writing agent service"
    cat > /opt/openbas-agent-service-${user}/${user}-openbas-agent.service <<EOF
      [Unit]
      Description=OpenBAS Agent Service ${user}
      After=network.target
      [Service]
      User=${user}
      Group=${group}
      Type=exec
      ExecStart=/opt/openbas-agent-service-${user}/openbas-agent
      StandardOutput=journal
      Restart=always
      RestartSec=60
      [Install]
      WantedBy=multi-user.target
EOF

    chown -R ${user}:${group} /opt/openbas-agent-service-${user}
    echo "05. Starting agent service"
    (
      ln -sf /opt/openbas-agent-service-${user}/${user}-openbas-agent.service /etc/systemd/system/${user}-openbas-agent.service
      systemctl daemon-reload
      systemctl enable ${user}-openbas-agent
      systemctl start ${user}-openbas-agent
    ) || (echo "Error while enabling OpenBAS Agent systemd unit file or starting the agent" >&2 && exit 1)

    echo "OpenBAS Agent started."
else
  echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
  exit 1
fi