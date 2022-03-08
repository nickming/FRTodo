extern crate time;

use backtrace::Backtrace;
use crossbeam_channel::{unbounded, Sender};
use log::{Log, Metadata, Record};
use std::{panic, thread};

pub struct CustomLogger {
    _handle: Option<std::thread::JoinHandle<()>>,
    sender: Option<Sender<(u32, String)>>,
    callback: Option<Box<dyn Fn(u32, String) + Send + Sync + 'static>>,
}

impl CustomLogger {
    pub fn new<F>(callback: F, log_in_thread: bool) -> Self
        where
            F: Fn(u32, String) + Send + Sync + 'static,
    {
        init_panic_hook();
        if log_in_thread {
            let (sender, receiver) = unbounded::<(u32, String)>();
            let handle = std::thread::Builder::new()
                .name("log_thread".to_string())
                .spawn(move || {
                    receiver.iter().for_each(move |item| {
                        callback(item.0, item.1)
                    });
                })
                .unwrap();
            Self {
                _handle: Some(handle),
                sender: Some(sender),
                callback: None,
            }
        } else {
            Self {
                _handle: None,
                sender: None,
                callback: Some(Box::new(callback)),
            }
        }
    }
}

impl Log for CustomLogger {
    fn enabled(&self, _metadata: &Metadata) -> bool {
        true
    }

    fn log(&self, record: &Record) {
        let log_str = format!(
            "[{}] [{}] {}.rs:{} {}",
            time::OffsetDateTime::now_utc().format("%m-%d %T %N"),
            record.level(),
            record.target(),
            record.line().unwrap_or(0),
            record.args()
        );
        if let Some(ref sender) = self.sender {
            let _ = sender.try_send((record.level() as u32, log_str));
        } else if let Some(cb) = self.callback.as_ref() {
            (cb)(record.level() as u32, log_str)
        }
    }

    fn flush(&self) {}
}

fn init_panic_hook() {
    panic::set_hook(Box::new(|info| {
        let backtrace = Backtrace::default();

        let thread = thread::current();
        let thread = thread.name().unwrap_or("<unnamed>");

        let msg = match info.payload().downcast_ref::<&'static str>() {
            Some(s) => *s,
            None => match info.payload().downcast_ref::<String>() {
                Some(s) => &**s,
                None => "Box<Any>",
            },
        };

        match info.location() {
            Some(location) => {
                log::error!(
                    target: "panic", "thread '{}' panicked at '{}': {}:{}",
                    thread,
                    msg,
                    location.file(),
                    location.line(),
                );
            }
            None => log::error!(
                target: "panic",
                "thread '{}' panicked at '{}'",
                thread,
                msg,
            ),
        }
        let backtrace_str = format!("{:?}", backtrace);
        let backtrace_str_vec: Vec<&str> = backtrace_str.split('\n').collect();
        for msg in backtrace_str_vec {
            log::error!("{}", msg);
        }
    }));
}
