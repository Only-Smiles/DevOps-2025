import pytest
from conftest import API_URL, HEADERS

import json
import requests


def test_follow_user(register_users):
    username = 'foo'
    url = f'{API_URL}/fllws/{username}'
    data = {'follow': 'b'}
    params = {'latest': 7}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    data = {'follow': 'c'}
    params = {'latest': 8}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok

    query = {'no': 20, 'latest': 9}
    response = requests.get(url, headers=HEADERS, params=query)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    json_data = response.json()
    assert "b" in json_data["follows"], f"b doesn't follow foo, {json_data}"
    assert "c" in json_data["follows"], f"c doesn't follow foo, {json_data}"

    # verify that latest was updated
    response = requests.get(f'{API_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 9, f"Expected 'latest == 9', got {response.content}"


def test_a_unfollows_b(register_users):
    username = 'a'
    url = f'{API_URL}/fllws/{username}'

    #  first send unfollow command
    data = {'unfollow': 'b'}
    params = {'latest': 10}
    response = requests.post(url, data=json.dumps(data),
                             headers=HEADERS, params=params)
    assert response.ok, f"Got {response.status_code} with {response.content}"

    # then verify that b is no longer in follows list
    query = {'no': 20, 'latest': 11}
    response = requests.get(url, params=query, headers=HEADERS)
    assert response.ok, f"Got {response.status_code} with {response.content}"
    assert 'b' not in response.json()['follows'], \
        f"b still follows a, {response.json()}"

    # verify that latest was updated
    response = requests.get(f'{API_URL}/latest', headers=HEADERS)
    assert response.json()['latest'] == 11, f"Expected 'latest == 11', got {response.content}"
