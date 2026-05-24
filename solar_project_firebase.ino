#include <WiFi.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <Firebase_ESP_Client.h>
#include "time.h"

#define WIFI_SSID "project"
#define WIFI_PASSWORD "12345678"

#define API_KEY "AIzaSyDy7ZhckuET_p39bi87-CcOozTzPTx1dtA"
#define DATABASE_URL "https://solarmonitor-8db42-default-rtdb.asia-southeast1.firebasedatabase.app/"

const char* ntpServer = "pool.ntp.org";
long gmtOffset_sec = 19800;
int daylightOffset_sec = 0;

LiquidCrystal_I2C lcd(0x27, 16, 2);

FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

const int voltagePin = 35;
const int currentPin = 34;

float voltageMultiplier = 3.3 * 5.0;

float sensitivity = 0.185;
float offsetVoltage = 2.5;

void setup()
{
  Serial.begin(115200);

  lcd.init();
  lcd.backlight();

  lcd.setCursor(0,0);
  lcd.print("Solar Monitor");
  delay(2000);
  lcd.clear();

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting WiFi");

  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(500);
  }

  Serial.println("\nWiFi Connected");

  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer);

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;

  if (Firebase.signUp(&config, &auth, "", "")){
    Serial.println("Firebase connected");
  }
  else{
    Serial.printf("Signup failed: %s\n", config.signer.signupError.message.c_str());
  }

  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop()
{
  int voltageADC = analogRead(voltagePin);
  int currentADC = analogRead(currentPin);

  float voltageSensor = (voltageADC / 4095.0) * 3.3;
  float solarVoltage = voltageSensor * 5.0;

  float currentSensorVoltage = (currentADC / 4095.0) * 3.3;
  float solarCurrent = (currentSensorVoltage - offsetVoltage) / sensitivity;

  if(abs(solarCurrent) < 0.05)
    solarCurrent = 0;

  Serial.print("Voltage: ");
  Serial.print(solarVoltage + 0.86);
  Serial.print(" V   Current: ");
  Serial.print(solarCurrent);
  Serial.println(" A");

  struct tm timeinfo;

  if(getLocalTime(&timeinfo))
  {
    char dateString[15];
    char timeString[15];

    strftime(dateString, sizeof(dateString), "%Y-%m-%d", &timeinfo);
    strftime(timeString, sizeof(timeString), "%H-%M-%S", &timeinfo);

    String path = "/solar/";
    path += dateString;
    path += "/";
    path += timeString;

    if(Firebase.ready())
    {
      if(solarVoltage > 0)
      {
        Firebase.RTDB.setFloat(&fbdo, path + "/voltage", solarVoltage + 0.86);
        Firebase.RTDB.setFloat(&fbdo, path + "/current", currentSensorVoltage);
      }
      else
      {
        Firebase.RTDB.setFloat(&fbdo, path + "/voltage", 0);
        Firebase.RTDB.setFloat(&fbdo, path + "/current", 0);        
      }
    }
  }
  if(solarVoltage>0)
  {
  lcd.setCursor(0,0);
  lcd.print("Volt: ");
  lcd.print((solarVoltage + 0.86),2);
  lcd.print("V   ");

  lcd.setCursor(0,1);
  lcd.print("Curr: ");
  lcd.print(currentSensorVoltage,2);
  lcd.print("A   ");
  delay(2000);
  }
  else
  {
  lcd.setCursor(0,0);
  lcd.print("Volt: 0");
  lcd.print("V   ");

  lcd.setCursor(0,1);
  lcd.print("Curr: 0");
  lcd.print("A   ");
  delay(2000);
  }
}