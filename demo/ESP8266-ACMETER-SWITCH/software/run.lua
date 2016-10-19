require("LeweiTcpClient")

LeweiTcpClient.init(gateWay,userKey)

require("keyDetector")
keyDetector.enableTrig()

function test(p1)
   --print("test function!"..p1)
   keyDetector.setSwtState(p1)
   --gpio.mode(0,gpio.INPUT)
end

LeweiTcpClient.addUserSwitch(test,"DO",keyDetector.getSwtState())

require('acMeter')
acMeter.startMeter()
tmr.alarm(2, 30000, 1, function()
tmr.wdclr()--feed dog here
v,p,e = acMeter.getData()
if(v ~= nil and e ~= nil and p ~= nil) then
     LeweiTcpClient.appendSensorValue("AI0",v)
     LeweiTcpClient.appendSensorValue("AI1",e)
     LeweiTcpClient.sendSensorValue("AI2",p)
     
end
end)
