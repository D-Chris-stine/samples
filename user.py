#IMPORT LIBRARIES
import time
import json
from selenium import webdriver
import pandas as pd
import boto3

#OPEN JSON CREDENTIALS FILE
with open('credentials.json') as config_file:
    data = json.load(config_file)

config = json.load(open("credentials.json"))["focus"]
username = config["username"]
password = config["password"]

# FUNCTION TO THE DOWNLOAD OF THE FILE ON HEADLESS CHROME
def enable_download_headless(browser,download_dir):
    browser.command_executor._commands["send_command"] = ("POST", '/session/$sessionId/chromium/send_command')
    params = {'cmd':'Page.setDownloadBehavior', 'params': {'behavior': 'allow', 'downloadPath': download_dir}}
    browser.execute("send_command", params)

# INSTANTIATE HEADLESS BROWSER
chrome_options = webdriver.ChromeOptions()
chrome_options.add_argument("--headless")
chrome_options.add_argument("--disable-gpu")
chrome_options.add_argument("--disable-dev-shm-usage")
prefs = {"download.default_directory" : '/home/kippjaxdata/focus'}
chrome_options.add_experimental_option('prefs', prefs)

# INITIALIZE CHROME OBJECT DRIVER
driver = webdriver.Chrome(options=chrome_options)

# DOWNLOAD DIRECTORY
download_dir = "/home/kippjaxdata/focus"

# CALL FUNCTION TO ENABLE DOWNLOAD ON HEADLESS DRIVER
enable_download_headless(driver, download_dir)

#USE THE REPORT PAGE URL TO PROMPT THE LOGIN PAGE - B/C THE FOCUS LOGIN PAGE CANNOT BE BOOKMARKED OR LINKED DIRECTLY
driver.get('https://duval.focusschoolsoftware.com/focus/Modules.php?force_package=SIS&modname=Reports/RunReport.php&id=13587')
time.sleep(5)

# CLICK ON THE EMPLOYEE LOGIN BUTTON
driver.find_element_by_xpath('//*[@class="idp"]').click()
time.sleep(5)

#INPUT LOGIN CREDENTIALS
driver.find_element_by_id("userNameInput").send_keys([username])
driver.find_element_by_id ("passwordInput").send_keys([password])
time.sleep(15)
driver.find_element_by_id("submitButton").click()
time.sleep(20)

#SET FOCUS TO 1271
driver.find_element_by_xpath('//*[@class="swift-box-button"]').click()
time.sleep(10)
driver.find_element_by_xpath('//*[text()="C-KIPP Impact School - 1271"]').click()
time.sleep(20)

#INPUT THE REPORT URL AGAIN TO OPEN THE 1271 REPORT
driver.get('https://duval.focusschoolsoftware.com/focus/Modules.php?force_package=SIS&modname=Reports/RunReport.php&id=13587')
time.sleep(15)

#CLICK THE EXPORT TO CSV BUTTON
driver.find_element_by_xpath('//*[@class="lo_export_csv"]').click()
time.sleep(25)

#CREATE THE DATAFRAME FROM THE CSV
us1271_df = pd.read_csv('/home/kippjaxdata/focus/Portal.csv')



#SWITCH FOCUS TO 5901
driver.find_element_by_xpath('//*[@class="swift-box-button"]').click()
time.sleep(5)
driver.find_element_by_xpath('//*[text()="C-KIPP Jacksonville High School - 5901"]').click()
time.sleep(15)

#INPUT THE URL TO ACCESS THE REPORT FOR 5901
driver.get('https://duval.focusschoolsoftware.com/focus/Modules.php?force_package=SIS&modname=Reports/RunReport.php&id=12863')
time.sleep(25)

#CLICK TO EXPORT 5901 REPORT
driver.find_element_by_xpath('//*[@class="lo_export_csv"]').click()
time.sleep(25)
#os.rename(r'/home/kippjaxdata/focus/Portal.csv',r'/home/kippjaxdata/focus/users5901.csv')

#CREATE THE DATAFRAME FROM THE UPDATED CSV FILE
us5901_df = pd.read_csv('/home/kippjaxdata/focus/Portal.csv')


#COMBINE THE 2 DATAFRAMES INTO ONE AND RENAME

users_df = pd.concat([us1271_df, us5901_df])

driver.quit();

#REFORMAT THE COLUMN NAMES FOR DATABASE OPTIMIZATION
users_df.rename(columns={'User ID':'user_id'}, inplace=True)
users_df.rename(columns={'E-mail Address':'email_address'}, inplace=True)
users_df.rename(columns={'Last':'last'}, inplace=True)
users_df.rename(columns={'First':'first'}, inplace=True)
users_df.rename(columns={'Middle':'middle'}, inplace=True)
users_df.rename(columns={'Gender':'gender'}, inplace=True)
users_df.rename(columns={'Education':'education'}, inplace=True)
#users_df.rename(columns={'Staff Number Identifier, Local':'staff_local_id'}, inplace=True)

#COMBINE 2 COLUMNS TO CREATE A NAME COLUMN TO FOR USERS JOINS ON TABLE WITHOUT USER ID NUMBERS
users_df["teacher_name"] = users_df["last"] +', '+ users_df["first"]

#REMOVE 'Profile' and 'Personnel Type' COLUMNS FROM THE DATAFRAME. THESE ARE USED TO FILTER THE FOCUS REPORT BUT NOT NEEDED IN THE DATABASE.
users_df.drop(['Profile'], axis=1, inplace=True)
users_df.drop(['Personnel_Type'], axis=1, inplace=True)


#REMOVE DUPLICATE ROWS BASED ON user_id
users_df.drop_duplicates(subset='user_id', keep='first', inplace=True)

#SAVE DATAFRAME AS A CSV IN PYTHON ANYWHERE DIRECTORY
users_df.to_csv('/home/kippjaxdata/focus/user_roster.csv', index=False)


#COPY THE CSV INTO AWS S3
aws_config = json.load(open("credentials_s3_rostering.json"))["awss3"]
access_key_id = aws_config["access_key_id"]
access_secret_key = aws_config["access_secret_key"]
bucket_name = aws_config["bucket_name"]

data = open (r'''/home/kippjaxdata/focus/user_roster.csv''', 'rb')

s3 = boto3.resource('s3', aws_access_key_id=access_key_id,
                    aws_secret_access_key = access_secret_key,
                  )
s3.Bucket(bucket_name).put_object(Key='focus_user_roster.csv',Body=data)

print(users_df)
