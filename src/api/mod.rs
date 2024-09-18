use std::sync::Arc;
use std::time::Duration;
use ureq::{Agent, Request};

mod manage_jobs;
mod register_agent;

const VERSION: &str = env!("CARGO_PKG_VERSION");

#[derive(Debug)]
pub struct Client {
    http_client: Agent,
    server_url: String,
    token: String,
}

impl Client {
    pub fn new(server_url: String, token: String) -> Client {
        let arc_crypto_provider = std::sync::Arc::new(rustls::crypto::ring::default_provider());
        let config = rustls_platform_verifier::tls_config_with_provider(arc_crypto_provider)
            .expect("Failed to create TLS config with crypto provider");
        let http_client = ureq::AgentBuilder::new()
            .timeout_connect(Duration::from_secs(2))
            .timeout(Duration::from_secs(5))
            .user_agent(format!("openbas-agent/{}", VERSION).as_str())
            .tls_config(Arc::new(config))
            .try_proxy_from_env(true)
            .build();
        // Remove trailing slash
        let mut url = server_url;
        if url.ends_with('/') {
            url.pop();
        }
        // Initiate client
        Client {
            http_client,
            server_url: url,
            token,
        }
    }

    pub fn post(&self, route: &str) -> Request {
        let api_route = format!("{}{}", self.server_url, route);
        self.http_client
            .post(&api_route)
            .set("Authorization", &format!("Bearer {}", self.token))
    }

    pub fn get(&self, route: &str) -> Request {
        let api_route = format!("{}{}", self.server_url, route);
        self.http_client
            .get(&api_route)
            .set("Authorization", &format!("Bearer {}", self.token))
    }
}

