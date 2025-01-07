use serde::Deserialize;
use crate::common::error_model::Error;

use super::Client;

#[derive(Debug, Deserialize)]
pub struct JobResponse {
    pub asset_agent_id: String,
    pub asset_agent_inject: Option<String>,
    #[allow(dead_code)]
    pub asset_agent_agent: String,
    pub asset_agent_command: String,
}

impl Client {
    pub fn list_jobs(&self, is_service: bool, is_elevated: bool, executed_by_user: String) -> Result<Vec<JobResponse>, Error> {
        // Post the input to the OpenBAS API
        let post_data = ureq::json!({
          "asset_external_reference": mid::get("openbas").unwrap(),
          "agent_is_service": is_service,
          "agent_is_elevated": is_elevated,
          "agent_executed_by_user": executed_by_user
        });
        match self.post("/api/endpoints/jobs").send_json(post_data) {
            Ok(response) => {
                Ok(response.into_json()?)
            }
            Err(ureq::Error::Status(_, response)) => {
                Err(Error::Api(response.into_string().unwrap()))
            },
            Err(err) => {
                Err(Error::Internal(err.to_string()))
            }
        }
    }
    pub fn clean_job(&self, job_id: &str) -> Result<(), Error> {
        // Post the input to the OpenBAS API
        return match self.delete(&format!("/api/endpoints/jobs/{}", job_id)).call() {
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