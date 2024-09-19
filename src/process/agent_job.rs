use crate::api::Client;
use crate::config::settings::Settings;
use crate::process::agent_exec;
use crate::THREADS_CONTROL;
use log::{error, info};
use std::io::Error;
use std::sync::atomic::Ordering;
use std::thread;
use std::thread::{sleep, JoinHandle};
use std::time::Duration;

pub fn listen(settings_data: Settings) -> Result<JoinHandle<()>, Error> {
    info!("Starting listening jobs thread");
    let uri = settings_data.openbas.url;
    let token = settings_data.openbas.token;
    let non_system_user = settings_data.openbas.non_system_user;
    let non_system_pwd = settings_data.openbas.non_system_pwd;

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
                        let _ = agent_exec::command_execution(j.asset_agent_id.as_str(), j.asset_agent_command.as_str(), j.asset_agent_elevation_required, non_system_user.as_str(), non_system_pwd.as_str());
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