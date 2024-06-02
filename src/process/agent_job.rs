use log::{info};
use std::io::Error;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;
use std::thread::{JoinHandle, sleep};
use std::time::Duration;
use crate::api::Client;
use crate::process::agent_exec;

pub fn listen(uri: String, token: String) -> Result<JoinHandle<()>, Error> {
    // Declare an api client
    let api_client = Client::new(uri, token);
    // Create a thread to ping the api on a regular basis
    let term = Arc::new(AtomicBool::new(false));
    signal_hook::flag::register(signal_hook::consts::SIGTERM, Arc::clone(&term))?;
    let handle = thread::spawn(move || {
        // While no stop signal received
        while !term.load(Ordering::Relaxed) {
            let jobs = api_client.list_jobs();
            if jobs.is_ok() {
                jobs.unwrap().iter().for_each(|j| {
                    info!("Start handling {:?}", j.asset_agent_inject);
                    // 01. Remove the execution job
                    info!("Cleaning {:?}", j.asset_agent_id);
                    let clean_result = api_client.clean_job(j.asset_agent_id.as_str());
                    // 02. Execute the command
                    if clean_result.is_ok() {
                        info!("Executing {:?}", j.asset_agent_command);
                        let _ = agent_exec::command_execution(j.asset_agent_command.as_str());
                    }
                    info!("Done handling {:?}", j.asset_agent_inject);
                });
            }
            // Wait for the next ping (30 secs)
            sleep(Duration::from_secs(30));
        }
    });
    Ok(handle)
}