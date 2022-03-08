table! {
    todos (id) {
        id -> Text,
        title -> Text,
        description -> Nullable<Text>,
        is_completed -> Bool,
        created_ts -> BigInt,
    }
}
