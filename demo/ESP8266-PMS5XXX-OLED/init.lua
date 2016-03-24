disp = nil
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

disp:firstPage()
repeat
disp:drawFrame(15,15,100,25) 
disp:drawStr(25,25,"PM2.5 Detector") 
disp:drawStr(20,50,"www.lewei50.com") 
until disp:nextPage() == false 

require("EasyWebConfig")
EasyWebConfig.addVar("gateWay")
EasyWebConfig.addVar("userKey")
--EasyWebConfig.addVar("sensorId")
EasyWebConfig.doMyFile("run.lua")
--dofile("run.lua")
