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

if [ "${os}" = "macos" ]; then
    echo "Starting install script for ${os} | ${architecture}"

    echo "01. Stopping existing openbas-agent..."
    launchctl bootout system/ ~/Library/LaunchDaemons/openbas-agent.plist || echo "openbas-agent already stopped"

    echo "02. Downloading OpenBAS Agent into /opt/openbas-agent..."
    (mkdir -p /opt/openbas-agent && touch /opt/openbas-agent >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to /opt\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o /opt/openbas-agent/openbas-agent
    chmod 755 /opt/openbas-agent/openbas-agent

    echo "03. Creating OpenBAS configuration file"
    cat > /opt/openbas-agent/openbas-agent-config.toml <<EOF
      debug=true
      [openbas]
      url = "${OPENBAS_URL}"
      token = "${OPENBAS_TOKEN}"
EOF

    echo "04. Writing agent service"
    mkdir -p ~/Library/LaunchDaemons
    cat > ~/Library/LaunchDaemons/openbas-agent.plist <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>openbas.agent</string>

            <key>Program</key>
            <string>/opt/openbas-agent/openbas-agent</string>

            <key>RunAtLoad</key>
            <true/>

            <!-- The agent needs to run at all times -->
            <key>KeepAlive</key>
            <true/>

            <!-- This prevents macOS from limiting the resource usage of the agent -->
            <key>ProcessType</key>
            <string>Interactive</string>

            <!-- Increase the frequency of restarting the agent on failure, or post-update -->
            <key>ThrottleInterval</key>
            <integer>3</integer>

            <!-- Wait for 10 minutes for the agent to shut down (the agent itself waits for tasks to complete) -->
            <key>ExitTimeOut</key>
            <integer>600</integer>

            <key>StandardOutPath</key>
            <string>/opt/openbas-agent/runner.log</string>
            <key>StandardErrorPath</key>
            <string>/opt/openbas-agent/runner.log</string>
        </dict>
    </plist>
EOF

    echo "05. Starting agent service"
    launchctl enable system/openbas.agent
    launchctl bootstrap system/ ~/Library/LaunchDaemons/openbas-agent.plist

    echo "OpenBAS Agent started."
else
    echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
    exit 1
fi