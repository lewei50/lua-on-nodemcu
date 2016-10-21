tmr.softwd(3600)

tmr.delay(1000)
require('keyDetector')
require('acMeter')
acMeter.stopMeter()
keyDetector.enableTrig()

wifi.setmode(wifi.STATION)

if( file.open("network_user_cfg.lua") ~= nil) then
     dofile("network_user_cfg.lua")
     --print("set up wifi mode")
     print("start")
     wifi.sta.config(ssid,password)
     wifi.sta.connect()
end

wifi.sta.eventMonReg(wifi.STA_IDLE, function() print("STATION_IDLE") end)
wifi.sta.eventMonReg(wifi.STA_CONNECTING, function() print("STATION_CONNECTING") end)
wifi.sta.eventMonReg(wifi.STA_WRONGPWD, function() print("STATION_WRONG_PASSWORD") end)
wifi.sta.eventMonReg(wifi.STA_APNOTFOUND, function() print("STATION_NO_AP_FOUND") end)
wifi.sta.eventMonReg(wifi.STA_FAIL, function() print("STATION_CONNECT_FAIL") end)
wifi.sta.eventMonReg(wifi.STA_GOTIP, function() 
print("STATION_GOT_IP")
if( file.open("network_user_cfg.lua") ~= nil) then
     require('run')
end
end)

wifi.sta.eventMonStart()
