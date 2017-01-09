require("LeweiHttpClient")
local disp
function init_OLED(sda,scl) --Set up the u8glib lib
     sla = 0x3c
     i2c.setup(0, sda, scl, i2c.SLOW)
     disp = u8g.ssd1306_128x64_i2c(sla)
     disp:setFont(u8g.font_6x10)
     disp:setFontRefHeightExtendedText()
     disp:setDefaultForegroundColor()
     disp:setFontPosTop()
end
init_OLED(5,6) --Run setting up

local sensorId
if(_G["sensorId"] ~= nil) then sensorId = _G["sensorId"]
else sensorId = "dust"
end

local pm25 = nil
local Hum = nil
local Temp = nil

LeweiHttpClient.init("01","your_api_key_here")

function calcAQI(pNum)
     --local clow = {0,15.5,40.5,65.5,150.5,250.5,350.5}
     --local chigh = {15.4,40.4,65.4,150.4,250.4,350.4,500.4}
     --local ilow = {0,51,101,151,201,301,401}
     --local ihigh = {50,100,150,200,300,400,500}
     local ipm25 = {0,35,75,115,150,250,350,500}
     local laqi = {0,50,100,150,200,300,400,500}
     local result={"优","良","轻度污染","中度污染","重度污染","严重污染","爆表"}
     --print(table.getn(chigh))
     aqiLevel = 8
     for i = 1,table.getn(ipm25),1 do
          if(pNum<ipm25[i])then
               aqiLevel = i
               break
          end
     end
     --aqiNum = (ihigh[aqiLevel]-ilow[aqiLevel])/(chigh[aqiLevel]-clow[aqiLevel])*(pNum-clow[aqiLevel])+ilow[aqiLevel]
     aqiNum = (laqi[aqiLevel]-laqi[aqiLevel-1])/(ipm25[aqiLevel]-ipm25[aqiLevel-1])*(pNum-ipm25[aqiLevel-1])+laqi[aqiLevel-1]
     return math.floor(aqiNum),result[aqiLevel-1]
end

function setTimer()
     tmr.alarm(0, 60000, 0, function()
               if(pm25 ~=nil) then 
               if(Temp~=nil) then LeweiHttpClient.appendSensorValue("T1",Temp)  end
               if(Hum~=nil) then LeweiHttpClient.appendSensorValue("H1",Hum) end
               aqi,result = calcAQI(pm25)
               LeweiHttpClient.appendSensorValue("AQI",aqi)
               LeweiHttpClient.sendSensorValue(sensorId,pm25) 
               setTimer()
               end
     end)
end

setTimer()

disp:firstPage()
repeat
disp:drawFrame(15,15,100,25) 
disp:drawStr(25,25,"PM2.5 Detector") 
disp:drawStr(20,50,"www.lewei50.com") 
until disp:nextPage() == false 

uart.setup( 0, 9600, 8, 0, 1, 0 )
uart.on("data", 0, 
 function(data)
     if((string.len(data)==32) and (string.byte(data,1)==0x42) and (string.byte(data,2)==0x4d))  then
          pm25 = (string.byte(data,13)*256+string.byte(data,14))
          --socket:send(pm25..'\n\r')    
          local si7021 = require("si7021")
          
          SDA_PIN = 5 -- sda pin, GPIO14
          SCL_PIN = 6 -- scl pin, GPIO12
          
          si7021.init(SDA_PIN, SCL_PIN)
          si7021.read(OSS)
          Hum = si7021.getHumidity()
          Temp = si7021.getTemperature()
          --print(Hum)
          --print(Temp)
          -- release module
          si7021 = nil
          _G["si7021"]=nil
           disp:firstPage()
           repeat
               disp:drawStr(10,20,"PM2.5:"..pm25.." ug/m3") 
               disp:drawStr(10,40,"Temp:"..Temp.."'C") 
               disp:drawStr(10,50,"Humi:"..Hum.."%")         
           until disp:nextPage() == false  
     end
end, 0)

