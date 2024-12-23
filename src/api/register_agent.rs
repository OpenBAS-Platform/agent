use crate::common::error_model::Error;
use network_interface::NetworkInterface;
use network_interface::NetworkInterfaceConfig;
use serde::Deserialize;
use std::env;
use super::Client;

const VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Debug, Deserialize)]
pub struct RegisterAgentResponse {
    #[allow(dead_code)]
    pub asset_id: String,
}

pub fn capitalize(s: &str) -> String {
    let mut c = s.chars();
    match c.next() {
        None => String::new(),
        Some(f) => f.to_uppercase().collect::<String>() + c.as_str(),
    }
}

pub fn get_arch() -> String {
    let arch = match env::consts::ARCH {
        "aarch64" => "arm64", // Mac still use the old nomenclature
        other => other,
    };
    String::from(arch)
}

pub fn get_operating_system() -> String {
    
    match env::consts::OS {
        "macos" => String::from("MacOS"),
        other => capitalize(other),
    }
}

impl Client {
    pub fn register_agent(&self, is_service: bool, is_elevated: bool, executed_by_user: String) -> Result<RegisterAgentResponse, Error> {
        // region Build the content to register
        let networks = NetworkInterface::show().unwrap();
        let mac_addresses: Vec<String> = networks
            .iter()
            .map(|interface| &interface.mac_addr)
            .filter_map(|mac| mac.clone())
            .collect();
        let ip_addresses: Vec<String> = networks
            .iter()
            .flat_map(|interface| &interface.addr)
            .map(|addr| addr.ip().to_string())
            .collect();
        let post_data = ureq::json!({
          "asset_name": hostname::get()?.to_string_lossy(),
          "asset_external_reference": mid::get("openbas").unwrap(),
          "endpoint_agent_version": VERSION,
          "endpoint_ips": ip_addresses,
          "endpoint_platform": get_operating_system(),
          "endpoint_arch": get_arch(),
          "endpoint_mac_addresses": mac_addresses,
          "endpoint_hostname": hostname::get()?.to_string_lossy(),
          "agent_is_service": is_service,
          "agent_is_elevated": is_elevated,
          "agent_executed_by_user": executed_by_user
        });
        // endregion
        // Post the input to the OpenBAS API
        match self.post("/api/endpoints/register").send_json(post_data) {
            Ok(response) => Ok(response.into_json()?),
            Err(ureq::Error::Status(_, response)) => {
                Err(Error::Api(response.into_string().unwrap()))
            }
            Err(err) => Err(Error::Internal(err.to_string())),
        }
    }
}
