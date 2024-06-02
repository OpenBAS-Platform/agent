mod api;
mod process;
mod common;
mod config;

use crate::process::keep_alive;
use crate::process::agent_job;
use crate::config::settings::Settings;

// This agent is NOT a throwable implant
// Things to develop
// (/) Agent must register itself in OpenBAS as an endpoint + ping every minute
// (X) OpenBAS must have a garbage scheduler for timeout endpoint
// (/) Agent must check every 30 secs the job to execute
// (X) Windows -> Must be installed as a Windows service
// (X) Linux -> Must be configured in rc.d, rpm and deb.
// (X) Auto remove executable after

fn main() {
    // Init a simple json console logger
    tracing_subscriber::fmt().json().init();
    // Get args from command line
    let settings = Settings::new().unwrap();
    // Starts the ping alive thread
    let url = settings.openbas.url;
    let token = settings.openbas.token;
    let _ = keep_alive::ping(url.clone(), token.clone());
    // Starts the agent listening thread
    let agent_handle = agent_job::listen(url.clone(), token.clone());
    // Don't stop the exec until the listening thread is done
    agent_handle.unwrap().join().unwrap();
}


