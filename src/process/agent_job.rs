use log::{info};
use std::io::Error;
use std::sync::atomic::{Ordering};
use std::thread;
use std::thread::{JoinHandle, sleep};
use std::time::Duration;
use crate::api::Client;
use crate::process::agent_exec;
use crate::THREADS_CONTROL;

pub fn listen(uri: String, token: String) -> Result<JoinHandle<()>, Error> {
    info!("Starting listening jobs thread");
    let api = Client::new(uri, token);
    let handle = thread::spawn(move || {
        // While no stop signal received
        while THREADS_CONTROL.load(Ordering::Relaxed) {
            let jobs = api.list_jobs();
            if jobs.is_ok() {
                jobs.unwrap().iter().for_each(|j| {
                    info!("Start handling inject: {:?}", j.asset_agent_inject);
                    // 01. Remove the execution job
                    info!("Cleaning job: {:?}", j.asset_agent_id);
                    let clean_result = api.clean_job(j.asset_agent_id.as_str());
                    // 02. Execute the command
                    if clean_result.is_ok() {
                        let _ = agent_exec::command_execution(j.asset_agent_command.as_str());
                    }
                    info!("Done handling inject: {:?}", j.asset_agent_inject);
                });
            }
            // Wait for the next ping (30 secs)
            sleep(Duration::from_secs(30));
        }
    });
    Ok(handle)
}