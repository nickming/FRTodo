#[macro_use]
extern crate anyhow;
#[macro_use]
extern crate diesel;
#[macro_use]
extern crate diesel_migrations;
#[macro_use]
extern crate lazy_static;
#[macro_use]
extern crate thiserror;

mod bridge_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

pub mod database;
pub mod schema;
pub mod models;
pub mod error;
pub mod todo_impl;
mod log;

#[cfg(test)]
mod test {
    use crate::todo_impl::*;

    #[test]
    fn test() {
        let mut manager = TODO_MANAGER.write().unwrap();
        manager.initialize("./todos.db").unwrap();
        manager.fetch_todos().unwrap();
    }
}
