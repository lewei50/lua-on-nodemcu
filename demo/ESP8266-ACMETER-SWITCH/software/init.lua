--tmr.softwd(3600)

tmr.alarm(2, 3000, tmr.ALARM_SINGLE, function()
require('keyDetector')
require('acMeter')
acMeter.stopMeter()
keyDetector.enableTrig()

uploader = nil

wifi.setmode(wifi.STATION)

if( file.open("network_user_cfg.lua") ~= nil) then
     dofile("network_user_cfg.lua")
     --print("set up wifi mode")
     print("start")
     station_cfg={}
     station_cfg.ssid=ssid
     station_cfg.pwd=password
     wifi.sta.config(station_cfg)
     wifi.sta.connect()
end
wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
T.BSSID.."\n\tChannel: "..T.channel)
end)

wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
T.BSSID.."\n\treason: "..T.reason)
     if(run) then run.stop() end
end)
wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function() 
print("STATION_GOT_IP")
if( file.open("network_user_cfg.lua") ~= nil) then
     require('run')
     run.start()
end
end)

--wifi.sta.eventMonStart()
end)
