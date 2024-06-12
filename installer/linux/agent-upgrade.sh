echo "Downloading OpenBAS Agent into /opt/openbas-agent..."
curl -sSf ${OPENBAS_URL}/api/agent/executable/openbas/linux -o /opt/openbas-agent/openbas-agent_upgrade
mv /opt/openbas-agent/openbas-agent_upgrade /opt/openbas-agent/openbas-agent
chmod 755 /opt/openbas-agent/openbas-agent

if [ -d /run/systemd/system ]; then
  echo "Detected init: systemd"
  echo "Restarting existing openbas-agent..."
  systemctl restart openbas-agent || echo "Fail restarting openbas-agent"
else
  echo "No init found, you need to configure it yourself to start /opt/openbas-agent/openbas-agent at startup"
fi