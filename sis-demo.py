#import libraries
import time
import json
from selenium import webdriver
import pandas as pd
import boto3

#open JSON file with credentials and save credentials as variables
with open('credentials.json') as config_file:
    data = json.load(config_file)

config = json.load(open("credentials.json"))["focus"]
username = config["username"]
password = config["password"]
url1= config["url1']
url2= config["url2"]

# function to take care of downloading file
def enable_download_headless(browser,download_dir):
    browser.command_executor._commands["send_command"] = ("POST", '/session/$sessionId/chromium/send_command')
    params = {'cmd':'Page.setDownloadBehavior', 'params': {'behavior': 'allow', 'downloadPath': download_dir}}
    browser.execute("send_command", params)

# instantiate a chrome options object so you can set the size and headless preferenced
options = webdriver.ChromeOptions()
options.add_argument("--headless")
options.add_argument("--disable-gpu")
options.add_argument("--disable-dev-shm-usage")
prefs = {"download.default_directory" : '/home/kippjaxdata/focus'}
options.add_experimental_option('prefs', prefs)

# initialize driver object
driver = webdriver.Chrome(options=options)
# download directory location
download_dir = "/home/kippjaxdata/focus"
# function to handle setting up headless download
enable_download_headless(driver, download_dir)

#access report page
driver.get(url1)

#wait 3 seconds for page to load
time.sleep(5)

driver.find_element_by_xpath('//*[@class="idp"]').click()

#wait 5 seconds for page to load
time.sleep(5)

#input credentials
driver.find_element_by_id("userNameInput").send_keys([username])
driver.find_element_by_id ("passwordInput").send_keys([password])
#driver.find_element_by_id("submitButton").click()
driver.find_element_by_class_name("submit").click()


#wait 5 seconds for page to load
time.sleep(20)

#SET FOCUS TO 1271
#driver.find_element_by_xpath('//*[@class="swift-box-button"]').click()
driver.find_element_by_css_selector("div.swift-box-button").click()
time.sleep(5)
driver.find_element_by_xpath('//*[text()="C-KIPP Impact School - 1271"]').click()
time.sleep(20)

# access report page
driver.get(url1)

#wait 15 seconds for page to load
time.sleep(20)

#Click export
driver.find_element_by_xpath('//*[@class="lo_export_csv"]').click()

time.sleep(15)

#import csv as dataframe and modify
f1271_df = pd.read_csv('/home/kippjaxdata/focus/Portal.csv')


#SWITCH FOCUS TO 5901
driver.find_element_by_xpath('//*[@class="swift-box-button"]').click()
time.sleep(5)
driver.find_element_by_xpath('//*[text()="C-KIPP Jacksonville High School - 5901"]').click()
time.sleep(20)

#access report page
driver.get(url2)
time.sleep(15)

#Click export
driver.find_element_by_xpath('//*[@class="lo_export_csv"]').click()
time.sleep(25)

#import csv as dataframe and modify
f5901_df = pd.read_csv('/home/kippjaxdata/focus/Portal.csv')

driver.quit()

#COMBINE THE 2 DATAFRAMES INTO ONE AND RENAME
foundation_df = pd.concat([f1271_df, f5901_df])



#change column name to remove space
foundation_df.rename(columns={'Student ID':'student_id'}, inplace=True)
foundation_df.rename(columns={'Last':'last'}, inplace=True)
foundation_df.rename(columns={'first':'first'}, inplace=True)
foundation_df.rename(columns={'Counselor':'school_id'}, inplace=True)
foundation_df.rename(columns={'Enrollment Start Date':'enrollment_start_date'}, inplace=True)
foundation_df.rename(columns={'Drop Date':'enrollment_drop_date'}, inplace=True)
foundation_df.rename(columns={'Enrollment Code':'enrollment_code'}, inplace=True)
foundation_df.rename(columns={'Drop Code':'drop_code'}, inplace=True)
foundation_df.rename(columns={'Grade':'grade'}, inplace=True)
foundation_df.rename(columns={'Gender':'gender'}, inplace=True)
foundation_df.rename(columns={'Birthdate':'birthdate'}, inplace=True)
foundation_df.rename(columns={'Ethnicity: Hispanic or Latino':'hispanic_latino'}, inplace=True)
foundation_df.rename(columns={'Race: American Indian or Alaska Native':'american_indian_alaska_native'}, inplace=True)
foundation_df.rename(columns={'Race: Asian':'asian'}, inplace=True)
foundation_df.rename(columns={'Race: Black or African American':'black_african_american'}, inplace=True)
foundation_df.rename(columns={'Race: Native Hawaiian or Other Pacific Islander':'native_hawaiian_pacific_islander'}, inplace=True)
foundation_df.rename(columns={'Race: White':'white'}, inplace=True)
foundation_df.rename(columns={'Most Frequently Spoken Language Student':'most_frequently_spoken_language'}, inplace=True)
foundation_df.rename(columns={'English Language Learner':'english_language_learner'}, inplace=True)
foundation_df.rename(columns={'School Year':'school_year'}, inplace=True)
foundation_df.rename(columns={'Florida Education Identifier':'fleid'}, inplace=True)
foundation_df.rename(columns={'Primary ESE':'primary_ese'}, inplace=True)

#reformat school year
foundation_df.school_year.replace('2021-2022','2022', inplace=True)

#drop non-numeric values
#foundation_df.school_id.replace('[^0-9]','', inplace=True)

#foundation_df.drop_duplicates(subset=['student_id'], keep='last', inplace=True)

#save df as csv in pythonanywhere focus folder
foundation_df.to_csv('/home/kippjaxdata/focus/foundation.csv', index=False)


#pull in aws credentials
aws_config = json.load(open("credentials_s3.json"))["awss3"]
access_key_id = aws_config["access_key_id"]
access_secret_key = aws_config["access_secret_key"]
bucket_name = aws_config["bucket_name"]

data = open (r'''/home/kippjaxdata/focus/foundation.csv''', 'rb')

s3 = boto3.resource('s3', aws_access_key_id=access_key_id,
                    aws_secret_access_key = access_secret_key,
                   )
s3.Bucket(bucket_name).put_object(Key='foundation.csv',Body=data)
