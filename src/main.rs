mod api;
mod common;
mod config;
mod process;
mod windows;

#[cfg(test)]
mod tests;

use log::info;
use rolling_file::{BasicRollingFileAppender, RollingConditionBasic};
use std::env;
use std::sync::atomic::AtomicBool;
use std::thread::JoinHandle;

use crate::common::error_model::Error;
use crate::config::execution_details::ExecutionDetails;
use crate::config::settings::Settings;
use crate::process::agent_job;
use crate::process::{agent_cleanup, keep_alive};
use crate::windows::service::service_stub;

pub static THREADS_CONTROL: AtomicBool = AtomicBool::new(true);
const VERSION: &str = env!("CARGO_PKG_VERSION");
const PREFIX_LOG_NAME: &str = "openbas-agent.log";

fn agent_start(settings_data: Settings, is_service: bool) -> Result<Vec<JoinHandle<()>>, Error> {
    let url = settings_data.openbas.url;
    let token = settings_data.openbas.token;
    let unsecured_certificate = settings_data.openbas.unsecured_certificate;
    let with_proxy = settings_data.openbas.with_proxy;
    let installation_mode = settings_data.openbas.installation_mode;
    let execution_details = ExecutionDetails::new(is_service).unwrap();
    info!(
        "ExecutionDetails : user {:?} -- is_elevated {:?} -- is_service {:?} ",
        execution_details.executed_by_user,
        execution_details.is_elevated,
        execution_details.is_service
    );
    let keep_alive_thread = keep_alive::ping(
        url.clone(),
        token.clone(),
        unsecured_certificate,
        with_proxy,
        installation_mode,
        execution_details.clone(),
    );
    // Starts the agent listening thread
    let agent_job_thread = agent_job::listen(
        url.clone(),
        token.clone(),
        unsecured_certificate,
        with_proxy,
        execution_details.clone(),
    );
    // Starts the cleanup thread
    let cleanup_thread = agent_cleanup::clean();
    // Don't stop the exec until the listening thread is done
    Ok(vec![
        keep_alive_thread.unwrap(),
        agent_job_thread.unwrap(),
        cleanup_thread.unwrap(),
    ])
}

fn main() -> Result<(), Error> {
    // region Init logger
    let current_exe_patch = env::current_exe().unwrap();
    let parent_path = current_exe_patch.parent().unwrap();
    let log_file = parent_path.join(PREFIX_LOG_NAME);
    let condition = RollingConditionBasic::new().daily();
    let file_appender = BasicRollingFileAppender::new(log_file, condition, 3).unwrap();
    let (file_writer, _guard) = tracing_appender::non_blocking(file_appender);
    tracing_subscriber::fmt()
        .json()
        .with_writer(file_writer)
        .init();
    // endregion
    // region Process execution
    info!("Starting OpenBAS agent {} ({})", VERSION, Settings::mode());
    let settings = Settings::new();
    let settings_data = settings.unwrap();
    if service_stub::is_windows_service() {
        // Running as a Windows service
        agent_start(settings_data, true).unwrap();
        // Service stub is a blocking thread managed by Windows service
        service_stub::run().unwrap();
    } else {
        // Standalone execution
        let agent_handle = agent_start(settings_data, false).unwrap();
        // In this mode, we need to wait for end of threads execution
        agent_handle
            .into_iter()
            .for_each(|handle| handle.join().unwrap());
    }
    // endregion
    Ok(())
}
