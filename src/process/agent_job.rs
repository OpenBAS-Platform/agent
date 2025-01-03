use crate::api::Client;
use crate::process::agent_exec;
use crate::THREADS_CONTROL;
use log::{error, info};
use std::io::Error;
use std::sync::atomic::Ordering;
use std::thread;
use std::thread::{sleep, JoinHandle};
use std::time::Duration;

pub fn listen(
    uri: String,
    token: String,
    unsecured_certificate: bool,
    with_proxy: bool,
) -> Result<JoinHandle<()>, Error> {
    info!("Starting listening jobs thread");
    let api = Client::new(uri, token, unsecured_certificate, with_proxy);
    let handle = thread::spawn(move || {
        // While no stop signal received
        while THREADS_CONTROL.load(Ordering::Relaxed) {
            let jobs = api.list_jobs();
            if let Ok(jobs) = jobs {
                jobs.iter().for_each(|j| {
                    info!("Start handling inject: {:?}", j.asset_agent_inject);
                    info!("Cleaning job: {:?}", j.asset_agent_id);

                    let clean_result = api.clean_job(j.asset_agent_id.as_str());

                    if clean_result.is_ok() {
                        let _ = agent_exec::command_execution(
                            j.asset_agent_id.as_str(),
                            j.asset_agent_command.as_str(),
                        );
                    } else {
                        info!("Failed to clean job: {:?}", j.asset_agent_id);
                    }

                    info!("Done handling inject: {:?}", j.asset_agent_inject);
                });
            } else {
                error!("Fail getting jobs {}", jobs.unwrap_err())
            }
            // Wait for the next ping (30 secs)
            sleep(Duration::from_secs(30));
        }
    });
    Ok(handle)
}
