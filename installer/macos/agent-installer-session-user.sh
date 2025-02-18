#!/bin/sh
set -e

base_url=${OPENBAS_URL}
architecture=$(uname -m)

os=$(uname | tr '[:upper:]' '[:lower:]')
if [ "${os}" = "darwin" ]; then
  os="macos"
fi

if [ "${os}" = "macos" ]; then
    echo "Starting install script for ${os} | ${architecture}"

    echo "01. Stopping existing openbas-agent-session..."
    launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/openbas-agent-session.plist || echo "openbas-agent already stopped"

    echo "02. Downloading OpenBAS Agent into ~/.local/openbas-agent-session..."
    (mkdir -p ~/.local/openbas-agent-session && touch ~/.local/openbas-agent-session >/dev/null 2>&1) || (echo -n "\nFatal: Can't write to ~/.local\n" >&2 && exit 1)
    curl -sSfL ${base_url}/api/agent/executable/openbas/${os}/${architecture} -o ~/.local/openbas-agent-session/openbas-agent
    chmod +x ~/.local/openbas-agent-session/openbas-agent

    echo "03. Creating OpenBAS configuration file"
    cat > ~/.local/openbas-agent-session/openbas-agent-config.toml <<EOF
debug=false

[openbas]
url = "${OPENBAS_URL}"
token = "${OPENBAS_TOKEN}"
unsecured_certificate = "${OPENBAS_UNSECURED_CERTIFICATE}"
with_proxy = "${OPENBAS_WITH_PROXY}"
EOF

    echo "04. Writing agent service"
    mkdir -p ~/Library/LaunchAgents
    cat > ~/Library/LaunchAgents/openbas-agent-session.plist <<EOF
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>openbas.agent.session</string>

            <key>Program</key>
            <string>/Users/$(id -un)/.local/openbas-agent-session/openbas-agent</string>

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
            <integer>60</integer>

            <!-- Wait for 10 minutes for the agent to shut down (the agent itself waits for tasks to complete) -->
            <key>ExitTimeOut</key>
            <integer>600</integer>

            <key>StandardOutPath</key>
            <string>/Users/$(id -un)/.local/openbas-agent-session/runner.log</string>
            <key>StandardErrorPath</key>
            <string>/Users/$(id -un)/.local/openbas-agent-session/runner.log</string>
        </dict>
    </plist>
EOF

    echo "05. Starting agent service"
    launchctl enable user/$(id -u)/~/Library/LaunchAgents/openbas-agent-session.plist
    launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/openbas-agent-session.plist

    echo "OpenBAS Agent started."
else
    echo "Operating system $OSTYPE is not supported yet, please create a ticket in openbas github project"
    exit 1
fi