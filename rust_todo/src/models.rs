use super::schema::todos;

use serde::{Serialize, Deserialize};

#[table_name = "todos"]
#[changeset_options(treat_none_as_null = "true")]
#[derive(Debug, Insertable, Queryable, QueryableByName, AsChangeset, Identifiable, PartialEq, Deserialize, Serialize)]
pub struct Todo {
    pub id: String,
    pub title: String,
    pub description: Option<String>,
    pub created_ts: i64,
    pub is_completed: bool,
}