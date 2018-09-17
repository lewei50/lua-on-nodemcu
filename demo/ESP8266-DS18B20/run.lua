require("LeweiHttpClient")

LeweiHttpClient.init(gateWay,userKey)
tmr.alarm(2, 60000, tmr.ALARM_AUTO, function()
     if(H1 ~= nil) then
          LeweiHttpClient.appendSensorValue("H1",H1)
     end
     if(T1 ~= nil) then
          LeweiHttpClient.sendSensorValue("T1",T1)
          T1 = nil
     end
end)




