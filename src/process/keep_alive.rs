use crate::api::Client;
use crate::config::execution_details::ExecutionDetails;
use crate::THREADS_CONTROL;
use log::{error, info};
use std::io::Error;
use std::sync::{Arc, Mutex};
use std::sync::atomic::Ordering;
use std::thread;
use std::thread::{sleep, JoinHandle};
use std::time::Duration;

pub fn ping(
    uri: String,
    token: String,
    unsecured_certificate: bool,
    with_proxy: bool,
    execution_details: Arc<Mutex<ExecutionDetails>>,
) -> Result<JoinHandle<()>, Error> {
    info!("Starting ping thread");
    let api = Client::new(uri, token, unsecured_certificate, with_proxy);
    let handle = thread::spawn(move || {
        // While no stop signal received
        while THREADS_CONTROL.load(Ordering::Relaxed) {
            let execution_details_locked = execution_details.lock().unwrap();
            // Register, ping the agent
            let register = api.register_agent(
                execution_details_locked.is_service,
                execution_details_locked.is_elevated,
                execution_details_locked.executed_by_user.clone(),
            );
            if register.is_err() {
                error!("Fail registering the agent {}", register.unwrap_err())
            }
            // Wait for the next ping (2 minutes)
            sleep(Duration::from_secs(120));
        }
    });
    Ok(handle)
}
