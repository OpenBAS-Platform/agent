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

impl Client {
    pub fn register_agent(&self) -> Result<RegisterAgentResponse, Error> {
        // region Build the content to register
        let networks = NetworkInterface::show().unwrap();
        let mac_addresses: Vec<String> = networks
            .iter()
            .map(|interface| &interface.mac_addr)
            .filter(|mac_opts| mac_opts.is_some())
            .map(|mac| mac.clone().unwrap())
            .collect();
        let ip_addresses: Vec<String> = networks
            .iter()
            .map(|interface| &interface.addr)
            .flatten()
            .map(|addr| addr.ip().to_string())
            .collect();
        let arch = match env::consts::ARCH {
            "aarch64" => "arm64", // Mac still use the old nomenclature
            other => other,
        };
        let post_data = ureq::json!({
          "asset_name": hostname::get()?.to_string_lossy(),
          "asset_external_reference": mid::get("openbas").unwrap(),
          "endpoint_agent_version": VERSION,
          "endpoint_ips": ip_addresses,
          "endpoint_platform": capitalize(env::consts::OS),
          "endpoint_arch": arch,
          "endpoint_mac_addresses": mac_addresses,
          "endpoint_hostname": hostname::get()?.to_string_lossy()
        });
        // endregion
        // Post the input to the OpenBAS API
        return match self.post("/api/endpoints/register").send_json(post_data) {
            Ok(response) => Ok(response.into_json()?),
            Err(ureq::Error::Status(_, response)) => {
                Err(Error::Api(response.into_string().unwrap()))
            }
            Err(err) => Err(Error::Internal(err.to_string())),
        };
    }
}
