use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;
use std::io::Error;
use std::thread::{JoinHandle, sleep};
use std::time::Duration;
use crate::api::Client;

pub fn ping(uri: String, token: String) -> Result<JoinHandle<()>, Error> {
    // Declare an api client
    let api_client = Client::new(uri, token);
    // Sync register to validate the API availability
    api_client.register_agent().unwrap();
    // Create a thread to ping the api on a regular basis
    let term = Arc::new(AtomicBool::new(false));
    signal_hook::flag::register(signal_hook::consts::SIGTERM, Arc::clone(&term))?;
    let handle = thread::spawn(move || {
        // While no stop signal received
        while !term.load(Ordering::Relaxed) {
            // Register, ping the agent
            let _ = api_client.register_agent();
            // Wait for the next ping (2 minutes)
            sleep(Duration::from_secs(120));
        }
    });
    Ok(handle)
}