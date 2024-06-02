use std::time::Duration;
use ureq::{Agent, Request};

mod register_agent;
mod manage_jobs;

#[derive(Debug)]
pub struct Client {
    http_client: Agent,
    server_url: String,
    token: String,
}

impl Client {
    pub fn new(server_url: String, token: String) -> Client {
        let http_client = ureq::AgentBuilder::new()
            .timeout(Duration::from_secs(10))
            .user_agent("openbas-agent/0.0.1")
            .build();

        Client {
            http_client,
            server_url,
            token
        }
    }

    pub fn post(&self, route: &str) -> Request {
        let api_route = format!("{}{}", self.server_url, route);
        let request = self.http_client.post(&api_route)
            .set("Authorization", &format!("Bearer {}", self.token));
        return request;
    }

    pub fn get(&self, route: &str) -> Request {
        let api_route = format!("{}{}", self.server_url, route);
        let request = self.http_client.get(&api_route)
            .set("Authorization", &format!("Bearer {}", self.token));
        return request;
    }
}