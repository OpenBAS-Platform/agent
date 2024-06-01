use std::time::Duration;

fn main() {
    // Initialize the http client
    let api_client = ureq::AgentBuilder::new()
        .timeout(Duration::from_secs(10))
        .user_agent("openbas-agent/0.0.1")
        .build();
    println!("Hello, world!");
}
