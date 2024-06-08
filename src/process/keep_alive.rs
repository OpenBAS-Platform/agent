use std::sync::atomic::{Ordering};
use std::{thread};
use std::io::Error;
use std::thread::{JoinHandle, sleep};
use std::time::Duration;
use log::{error, info};
use crate::api::Client;
use crate::{THREADS_CONTROL};

pub fn ping(uri: String, token: String) -> Result<JoinHandle<()>, Error> {
    info!("Starting ping thread");
    let api = Client::new(uri, token);
    let handle = thread::spawn(move || {
        // While no stop signal received
        while THREADS_CONTROL.load(Ordering::Relaxed) {
            // Register, ping the agent
            let register = api.register_agent();
            if register.is_err() {
                error!("Fail registering the agent {}", register.unwrap_err())
            }
            // Wait for the next ping (2 minutes)
            sleep(Duration::from_secs(120));
        }
    });
    Ok(handle)
}