import pytest
from conftest import API_URL, HEADERS

import json
import requests

def test_latest():
    # post something to update LATEST
    url = f"{API_URL}/register"
    data = {'username': 'test', 'email': 'test@test', 'pwd': 'foo'}
    params = {'latest': 1337}
    response = requests.post(url, data=json.dumps(data),
                             params=params, headers=HEADERS)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    # verify that latest was updated
    url = f'{API_URL}/latest'
    response = requests.get(url, headers=HEADERS)
    assert response.ok, f"Got {response.status_code} with {response.content}"
    assert response.json()['latest'] == 1337, \
        f"Expected 'latest == 1337', got {response.content}"

