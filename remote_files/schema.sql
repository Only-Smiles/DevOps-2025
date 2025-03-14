DROP TABLE IF EXISTS "user";
CREATE TABLE "user" (
    user_id SERIAL PRIMARY KEY,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    pw_hash TEXT NOT NULL
);

DROP TABLE IF EXISTS follower;
CREATE TABLE follower (
    who_id INTEGER REFERENCES "user"(user_id),
    whom_id INTEGER REFERENCES "user"(user_id)
);

DROP TABLE IF EXISTS message;
CREATE TABLE message (
    message_id SERIAL PRIMARY KEY,
    author_id INTEGER NOT NULL REFERENCES "user"(user_id),
    text TEXT NOT NULL,
    pub_date INTEGER,
    flagged INTEGER
);
