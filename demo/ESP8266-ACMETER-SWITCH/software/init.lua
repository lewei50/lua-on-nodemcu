tmr.softwd(3600)

tmr.delay(1000)
require('keyDetector')
require('acMeter')
acMeter.stopMeter()
keyDetector.enableTrig()

tmr.alarm(1, 10000, 1, function()
     tmr.wdclr()--feed dog
     if( file.open("network_user_cfg.lua") ~= nil) then
          require("network_user_cfg")
          --print("set up wifi mode")
          wifi.setmode(wifi.STATION)
          --please config ssid and password according to settings of your wireless router.
          wifi.sta.config(ssid,password)
          wifi.sta.connect()
          if(wifi.sta.getip()~=nil) then
          tmr.stop(1)--feed dog in other file
          require('run')
          end
     end
end)
