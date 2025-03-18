from conftest import BASE_URL
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.keys import Keys
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.firefox.service import Service
from selenium.webdriver.firefox.options import Options

GUI_URL = f'{BASE_URL}/register'

def _register_user_via_gui(driver, data):
    driver.get(GUI_URL)

    wait = WebDriverWait(driver, 5)
    buttons = wait.until(EC.presence_of_all_elements_located((By.CLASS_NAME, "actions")))
    input_fields = driver.find_elements(By.TAG_NAME, "input")

    for idx, str_content in enumerate(data):
        input_fields[idx].send_keys(str_content)
    input_fields[4].send_keys(Keys.RETURN)

    WebDriverWait(driver, 2).until(EC.url_changes(GUI_URL))

    print(driver.page_source)  # Debug output

    # Wait for a single flashes element to be present
    first_li = wait.until(EC.visibility_of_element_located((By.CSS_SELECTOR, "ul.flashes li")))

    return first_li.text


def test_register_user_via_gui():
    """
    This is a UI test. It only interacts with the UI that is rendered in the browser and checks that visual
    responses that users observe are displayed.
    """
    firefox_options = Options()
    firefox_options.add_argument("--headless")
    firefox_options.binary_location = "/usr/bin/firefox-esr"
    # firefox_options = None
    with webdriver.Firefox(options=firefox_options) as driver:
        generated_msg = _register_user_via_gui(driver, ["Me1", "me@some.where", "secure123", "secure123"])
        expected_msg = "You were successfully registered and can login now"
        assert generated_msg == expected_msg