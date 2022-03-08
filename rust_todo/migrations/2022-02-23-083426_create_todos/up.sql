-- Your SQL goes here

CREATE TABLE todos (
  id VARCHAR PRIMARY KEY NOT NULL,
  title VARCHAR NOT NULL,
  description TEXT,
  is_completed BOOLEAN NOT NULL DEFAULT FALSE,
  created_ts BIGINT NOT NULL DEFAULT 0
)