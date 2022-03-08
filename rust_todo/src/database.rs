use std::collections::hash_map::DefaultHasher;
use std::collections::HashMap;
use std::hash::{Hash, Hasher};
use std::sync::Mutex;
use std::sync::RwLock;

use diesel::{Connection, RunQueryDsl, SqliteConnection};
use diesel::r2d2::{Builder, ConnectionManager, Pool, PooledConnection};

use crate::error;
use crate::error::DataBaseError;

lazy_static! {
    pub static ref DB_MANAGER: Mutex<HashMap<u64, Pool<ConnectionManager<SqliteConnection>>>> =
        Mutex::new(HashMap::new());
}

diesel_migrations::embed_migrations!("./migrations");


pub struct RustDataBase(u64);

impl RustDataBase {
    pub fn new(path: &str) -> Option<Self> {
        create_database_with_path(path).map(|pool| RustDataBase(pool))
    }

    pub fn close(&self) {
        let pool = DB_MANAGER.lock().unwrap().remove(self.get_pool());
        drop(pool)
    }

    pub fn get_sqlite_connection(&self) -> anyhow::Result<PooledConnection<ConnectionManager<SqliteConnection>>> {
        let lock = DB_MANAGER.lock().unwrap();
        Ok(lock.get(self.get_pool()).ok_or(DataBaseError::UnknownError("获取连接池异常".to_string()))?.get()?)
    }

    fn get_pool(&self) -> &u64 {
        &self.0
    }
}

pub fn create_database_with_path(path: &str) -> Option<u64> {
    let mut hasher = DefaultHasher::new();
    path.hash(&mut hasher);
    let key = hasher.finish();
    let mut dbs_guard = DB_MANAGER.lock().unwrap();
    if let Some(_) = dbs_guard.get(&key) {
        log::info!("database has been initialized:{}",path);
        return Some(key);
    }

    let connection = ConnectionManager::<SqliteConnection>::new(path);
    match Pool::builder().max_size(5 + 1).build(connection) {
        Ok(pool) => {
            if let Ok(conn) = pool.get() {
                embedded_migrations::run_with_output(&conn, &mut std::io::stdout()).unwrap();
            }
            dbs_guard.insert(key, pool);
            Some(key)
        }
        Err(e) => {
            log::warn!("database init error:{:?}",e);
            None
        }
    }
}


#[allow(dead_code)]
pub fn establish_connections(db_url: &str) -> SqliteConnection {
    let connection = SqliteConnection::establish(db_url).unwrap();
    embedded_migrations::run_with_output(&connection, &mut std::io::stdout()).unwrap();
    connection
}

