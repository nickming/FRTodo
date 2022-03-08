use std::borrow::BorrowMut;
use std::sync::{Arc, RwLock};

use diesel::{ExpressionMethods, QueryDsl, RunQueryDsl, SqliteConnection};
use flutter_rust_bridge::StreamSink;
use serde::{Serialize, Serializer};

use crate::database::RustDataBase;
use crate::error::DataBaseError;
use crate::log::CustomLogger;
use crate::models::Todo;
use crate::schema::todos::columns::{created_ts, description, id, is_completed, title};
use crate::schema::todos::dsl::todos;

lazy_static! {
    pub static ref TODO_MANAGER:RwLock<TodoManager> = RwLock::new(TodoManager::new());
    pub static ref TOKIO_RUNTIME : tokio::runtime::Runtime = tokio::runtime::Builder::new_multi_thread()
                .enable_all()
                .thread_name("todo-runtime")
                .build()
                .expect("can not init tokio runtime");
}

pub trait TodoAction {
    fn clear_completed(&mut self) -> anyhow::Result<usize>;

    fn complete_all(&mut self, is_completed_value: bool) -> anyhow::Result<usize>;

    fn delete_todo(&mut self, deleted_id: &str) -> anyhow::Result<usize>;

    fn fetch_todos(&mut self) -> anyhow::Result<Vec<Todo>>;

    fn save_todo(&mut self, todo: Todo) -> anyhow::Result<usize>;
}

pub struct TodoManager {
    database: Option<Arc<RustDataBase>>,
    events: Option<StreamSink<String>>,
}

fn send_event(event: String) {
    println!("{}", event);
    let manager = TODO_MANAGER.read().unwrap();
    if let Some(stream) = (*manager).get_event_stream() {
        stream.add(event);
    }
}

impl TodoManager {
    pub fn new() -> TodoManager {
        TodoManager { database: None, events: None }
    }


    pub fn get_event_stream(&self) -> Option<&StreamSink<String>> {
        self.events.as_ref()
    }


    #[inline]
    fn init_logger(&self) {
        if let Err(e) = log::set_boxed_logger(Box::new(CustomLogger::new(|level, content| {
            send_event(content)
        }, true))) {
            log::debug!("set logger failed!:{:?}", e)
        } else {
            log::set_max_level(log::LevelFilter::Trace)
        }
    }

    pub fn initialize(&mut self, path: &str) -> anyhow::Result<()> {
        self.init_logger();
        match RustDataBase::new(path) {
            Some(database) => {
                self.database = Some(Arc::new(database));
                log::info!("init database successful!");
                Ok(())
            }
            None => {
                log::info!("can not initialized!");
                Err(anyhow!("data base init error"))
            }
        }
    }

    pub fn register_events(&mut self, listener: StreamSink<String>) {
        self.events = Some(listener);
    }

    pub fn execute_transaction<U, F: FnOnce(&SqliteConnection) -> anyhow::Result<U>>(&self, transaction: F) -> anyhow::Result<U> {
        let pool = self.database
            .as_ref()
            .ok_or(DataBaseError::UnknownError("执行事务异常".to_string()))?
            .get_sqlite_connection()?;
        transaction(&pool)
    }
}

impl TodoAction for TodoManager {
    fn clear_completed(&mut self) -> anyhow::Result<usize> {
        self.execute_transaction(|con| {
            let rows = diesel::delete(todos)
                .filter(is_completed.eq(true))
                .execute(con)?;
            Ok(rows)
        })
    }

    fn complete_all(&mut self, is_completed_value: bool) -> anyhow::Result<usize> {
        self.execute_transaction(|con| {
            let row = diesel::update(todos)
                .set(is_completed.eq(is_completed_value))
                .execute(con)?;
            Ok(row)
        })
    }

    fn delete_todo(&mut self, deleted_id: &str) -> anyhow::Result<usize> {
        self.execute_transaction(|con| {
            let row = diesel::delete(todos.filter(id.eq(deleted_id)))
                .execute(con)?;
            Ok(row)
        })
    }

    fn fetch_todos(&mut self) -> anyhow::Result<Vec<Todo>> {
        self.execute_transaction(|con| {
            let result = todos.select((id, title, description, created_ts, is_completed))
                .load::<Todo>(con)?;
            Ok(result)
        })
    }

    fn save_todo(&mut self, todo: Todo) -> anyhow::Result<usize> {
        self.execute_transaction(|con| {
            let exist: bool = todos.select((id, title, description, created_ts, is_completed)).filter(id.eq(todo.id.as_str())).first::<Todo>(con).is_ok();
            log::info!("save todo is exist:{}",exist);
            if exist {
                let description_text = match todo.description {
                    Some(s) => s,
                    None => "".to_string()
                };
                let rows = diesel::update(todos)
                    .set((title.eq(todo.title), description.eq(description_text), is_completed.eq(todo.is_completed)))
                    .filter(id.eq(todo.id.as_str()))
                    .execute(con)?;
                Ok(rows)
            } else {
                let result = diesel::insert_into(todos).values(todo).execute(con)?;
                Ok(result)
            }
        })
    }
}


#[derive(Debug, Serialize)]
pub struct Response {
    pub error: Option<String>,
    pub data: Option<Vec<Todo>>,
    pub change_rows: Option<usize>,
}

impl Response {
    fn new_data(data: Vec<Todo>) -> Response {
        Response {
            error: None,
            data: Some(data),
            change_rows: None,
        }
    }

    fn new_error(error: String) -> Response {
        Response {
            error: Some(error),
            data: None,
            change_rows: None,
        }
    }

    fn new_change_size(size: usize) -> Response {
        Response {
            error: None,
            change_rows: Some(size),
            data: None,
        }
    }

    fn to_string(&self) -> String {
        serde_json::to_string(self).unwrap()
    }
}

pub fn initialize(path: String) -> anyhow::Result<()> {
    let mut manager = TODO_MANAGER.write().unwrap();
    manager.initialize(path.as_str());
    Ok(())
}

pub fn register_event_listener(listener: StreamSink<String>) -> anyhow::Result<()> {
    let mut manager = TODO_MANAGER.write().unwrap();
    manager.register_events(listener);
    Ok(())
}

pub fn query_all() -> anyhow::Result<String> {
    let mut manager = TODO_MANAGER.write().unwrap();
    match manager.fetch_todos() {
        Ok(data) => {
            Ok(Response::new_data(data).to_string())
        }
        Err(e) => {
            Ok(Response::new_error(format!("query error:{:?}", e)).to_string())
        }
    }
}


pub fn delete(todo_id: String) -> anyhow::Result<String> {
    let mut manager = TODO_MANAGER.write().unwrap();
    match manager.delete_todo(todo_id.as_str()) {
        Ok(size) => {
            Ok(Response::new_change_size(size).to_string())
        }
        Err(e) => {
            Ok(Response::new_error(format!("delete todo error:{}", e)).to_string())
        }
    }
}

pub fn save(todo_data: String) -> anyhow::Result<String> {
    let mut manager = TODO_MANAGER.write().unwrap();
    let todo = serde_json::from_str::<Todo>(todo_data.as_str());
    if todo.is_err() {
        return Ok(Response::new_error(format!("parse json todo error:{}", todo_data)).to_string());
    }
    match manager.save_todo(todo.unwrap()) {
        Ok(size) => {
            Ok(Response::new_change_size(size).to_string())
        }
        Err(e) => {
            Ok(Response::new_error(format!("update todo error:{}", e)).to_string())
        }
    }
}

pub fn clear_completed() -> anyhow::Result<String> {
    let mut manager = TODO_MANAGER.write().unwrap();
    match manager.clear_completed() {
        Ok(size) => {
            Ok(Response::new_change_size(size).to_string())
        }
        Err(e) => {
            Ok(Response::new_error(format!("clear completed error:{}", e)).to_string())
        }
    }
}


pub fn complete_all(is_completed_value: bool) -> anyhow::Result<String> {
    let mut manager = TODO_MANAGER.write().unwrap();
    match manager.complete_all(is_completed_value) {
        Ok(size) => {
            Ok(Response::new_change_size(size).to_string())
        }
        Err(e) => {
            Ok(Response::new_error(format!("complete all error:{}", e)).to_string())
        }
    }
}
