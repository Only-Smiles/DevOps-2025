from pathlib import Path
from contextlib import closing
import base64

import sqlite3
import pytest
import requests
import json
from os.path import dirname, abspath, join

BASE_URL = 'http://localhost:4567'
API_URL = f"{BASE_URL}/api"
BASE_DIR = dirname(abspath(__file__))
DATABASE = join(BASE_DIR, "tmp", "mock.db")
SCHEMA = join(BASE_DIR, "tmp", "schema.sql")
USERNAME = 'simulator'
PWD = 'super_safe!'
CREDENTIALS = ':'.join([USERNAME, PWD]).encode('ascii')
ENCODED_CREDENTIALS = base64.b64encode(CREDENTIALS).decode()
HEADERS = {'Connection': 'close',
           'Content-Type': 'application/json',
           'Authorization': f'Basic {ENCODED_CREDENTIALS}'}


@pytest.fixture(scope="module", autouse=True)
def setup():
    def init_db():
        """Creates the database tables."""
        with closing(sqlite3.connect(DATABASE)) as db:
            with open(SCHEMA) as fp:
                db.cursor().executescript(fp.read())
            db.commit()

# Empty the database and initialize the schema again
    Path(DATABASE).unlink()
    init_db()


@pytest.fixture(scope="module")
def register_users():
    users = ["foo", "a", "b", "c"]
    for user in users:
        username = user
        email = f'{user}@{user}.{user}'
        pwd = user
        data = {'username': username, 'email': email, 'pwd': pwd}
        response = requests.post(f'{API_URL}/register', data=json.dumps(data),
                                 headers=HEADERS)
        assert response.ok

