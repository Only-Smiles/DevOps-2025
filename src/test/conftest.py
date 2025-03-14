import base64

import pytest
import requests
import json
from os import getenv
from os.path import join
import psycopg
from dotenv import load_dotenv

BASE_URL = 'http://minitwit:4567'
API_URL = f"{BASE_URL}/api"

load_dotenv()
DB_USER = getenv('DB_USER')
DB_PWD = getenv('DB_PWD')
DATABASE = f"dbname=minitwit host=database user={DB_USER} password={DB_PWD}"

SCHEMA = join("/test", "schema.sql")

USERNAME = 'simulator'
PWD = 'super_safe!'
CREDENTIALS = ':'.join([USERNAME, PWD]).encode('ascii')
ENCODED_CREDENTIALS = base64.b64encode(CREDENTIALS).decode()
HEADERS = {'Connection': 'close',
           'Content-Type': 'application/json',
           'Authorization': f'Basic {ENCODED_CREDENTIALS}'}

def init_db():
    """Creates the database tables."""
    with open(SCHEMA, "r") as fp:
            schema = fp.read()
    with psycopg.connect(DATABASE) as con:
        with con.cursor() as cursor:
            for statement in schema.split(";"):
                if statement.strip():  # Avoid empty statements
                    cursor.execute(statement)
            con.commit()

def reset_db():
    """Empty the database and initialize the schema again"""
    with psycopg.connect(DATABASE) as con:
        with con.cursor() as cursor:
            cursor.execute("DROP SCHEMA public CASCADE;")
            cursor.execute("CREATE SCHEMA public;")  # Resets schema instead of dropping tables one by one
            con.commit()

@pytest.fixture(scope="module", autouse=True)
def setup():
    reset_db()
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

