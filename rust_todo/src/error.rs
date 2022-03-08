use thiserror::Error;

#[derive(Error, Debug)]
pub enum DataBaseError {
    #[error("r2d2 error: {0}")]
    R2d2Error(#[from] diesel::r2d2::PoolError),

    #[error("transaction error:{0}")]
    TransactionError(String),

    #[error("unknown error")]
    UnknownError(String),
}