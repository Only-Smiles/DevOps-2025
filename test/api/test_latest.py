import pytest
from conftest import BASE_URL, HEADERS

import json
import requests

def test_latest():
    # post something to update LATEST
    url = f"{BASE_URL}/register"
    data = {'username': 'test', 'email': 'test@test', 'pwd': 'foo'}
    params = {'latest': 1337}
    response = requests.post(url, data=json.dumps(data),
                             params=params, headers=HEADERS)
    assert response.ok

    # verify that latest was updated
    url = f'{BASE_URL}/latest'
    response = requests.get(url, headers=HEADERS)
    assert response.ok
    assert response.json()['latest'] == 1337

