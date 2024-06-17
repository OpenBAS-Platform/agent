use serde::Deserialize;
use crate::common::error_model::Error;

use super::Client;

#[derive(Debug, Deserialize)]
pub struct JobResponse {
    pub asset_agent_id: String,
    pub asset_agent_inject: Option<String>,
    #[allow(dead_code)]
    pub asset_agent_asset: String,
    pub asset_agent_command: String,
}

impl Client {
    pub fn list_jobs(&self) -> Result<Vec<JobResponse>, Error> {
        // Post the input to the OpenBAS API
        let agent_id = mid::get("openbas").unwrap();
        return match self.get(&format!("/api/endpoints/jobs/{}", agent_id)).call() {
            Ok(response) => {
                Ok(response.into_json()?)
            }
            Err(ureq::Error::Status(_, response)) => {
                Err(Error::Api(response.into_string().unwrap()))
            },
            Err(err) => {
                Err(Error::Internal(err.to_string()))
            }
        };
    }
    pub fn clean_job(&self, job_id: &str) -> Result<(), Error> {
        // Post the input to the OpenBAS API
        return match self.post(&format!("/api/endpoints/jobs/{}", job_id)).call() {
            Ok(_) => {
                Ok(())
            }
            Err(ureq::Error::Status(_, response)) => {
                Err(Error::Api(response.into_string().unwrap()))
            },
            Err(err) => {
                Err(Error::Internal(err.to_string()))
            }
        };
    }
}