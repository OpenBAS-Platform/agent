use std::sync::atomic::{Ordering};
use std::{thread};
use std::io::Error;
use std::thread::{JoinHandle, sleep};
use std::time::Duration;
use log::{error, info};
use crate::api::Client;
use crate::{THREADS_CONTROL};
use crate::config::execution_details::ExecutionDetails;

pub fn ping(uri: String, token: String, unsecured_certificate: bool, with_proxy: bool, is_service: bool) -> Result<JoinHandle<()>, Error> {
    info!("Starting ping thread");
    let api = Client::new(uri, token,unsecured_certificate, with_proxy);
    let execution_details = ExecutionDetails::new(is_service).unwrap();
    let handle = thread::spawn(move || {
        // While no stop signal received
        while THREADS_CONTROL.load(Ordering::Relaxed) {
            // Register, ping the agent
            let register = api.register_agent(execution_details.is_service.clone(), execution_details.is_elevated.clone(), execution_details.executed_by_user.clone());
            if register.is_err() {
                error!("Fail registering the agent {}", register.unwrap_err())
            }
            // Wait for the next ping (2 minutes)
            sleep(Duration::from_secs(120));
        }
    });
    Ok(handle)
}