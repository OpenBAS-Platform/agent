use log::{info};
mod api;
mod process;
mod common;

use clap::{Error, Parser};
use crate::process::keep_alive;
use crate::process::agent_job;

// This agent is NOT a throwable implant
// Things to develop
// (/) Agent must register itself in OpenBAS as an endpoint + ping every minute
// (X) OpenBAS must have a garbage scheduler for timeout endpoint
// (/) Agent must check every 30 secs the job to execute
// (X) Windows -> Must be installed as a Windows service
// (X) Linux -> Must be configured in rc.d, rpm and deb.
// (X) Auto remove executable after

#[derive(Parser, Debug)]
#[command(version, about, long_about = None)]
struct Args {
    /// OpenBAS uri
    #[arg(short, long)]
    uri: String,

    /// Number of times to greet
    #[arg(short, long)]
    token: String,
}

fn main() -> Result<(), Error> {
    // Init a simple json console logger
    tracing_subscriber::fmt().json().init();
    info!("Starting OpenBAS agent 0.0.1");
    // Get args from command line
    let args = Args::parse();
    // Starts the ping alive thread
    let _ = keep_alive::ping(args.uri.clone(), args.token.clone());
    // Starts the agent listening thread
    let agent_handle = agent_job::listen(args.uri.clone(), args.token.clone());
    // Don't stop the exec until the listening thread is done
    agent_handle.unwrap().join().unwrap();
    // Everything is done
    Ok(())
}


