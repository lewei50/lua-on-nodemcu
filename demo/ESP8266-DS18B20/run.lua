require("LeweiHttpClient")

LeweiHttpClient.init(gateWay,userKey)

require("tcpServer")
tcpServer.init()

tmr.alarm(2, 60000, tmr.ALARM_AUTO, function()
     if(H1 ~= nil) then
          LeweiHttpClient.appendSensorValue("H1",string.format("%0.1f",H1))
     end
     if(T1 ~= nil) then
          LeweiHttpClient.sendSensorValue("T1",string.format("%0.1f",T1))
          T1 = nil
     end
     if(snDisabled)then
          tmr.stop(2)
     end
end)

tmr.alarm(3, 60000, tmr.ALARM_AUTO, function()
     tcpServer.keepOnline()
end)



