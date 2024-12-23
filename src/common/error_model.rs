use std::fmt;

#[derive(Debug)]
pub enum Error {
    Internal(String),
    Api(String),
    Io(std::io::Error),
}

impl fmt::Display for Error {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Error::Internal(message) => write!(f, "{}", message),
            Error::Api(api_message) => write!(f, "{}", api_message),
            Error::Io(io) => write!(f, "{}", io),
        }
    }
}

impl std::error::Error for Error {}

impl From<std::io::Error> for Error {
    fn from(err: std::io::Error) -> Self {
        Error::Io(err)
    }
}
