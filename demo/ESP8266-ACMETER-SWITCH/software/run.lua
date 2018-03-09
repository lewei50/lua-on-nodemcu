local moduleName = ...
local M = {}
_G[moduleName] = M

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
--boot = 1
uploadtimer = tmr.create()
uploadtimer:register(30000, tmr.ALARM_AUTO, function()
tmr.wdclr()--feed dog here
--print('upload'..node.heap())
v,p,e = acMeter.getData()
--print(v,p,e)
if(v ~= nil and e ~= nil and p ~= nil) then
     LeweiTcpClient.appendSensorValue("AI0",v)
     LeweiTcpClient.appendSensorValue("AI1",e)
     --LeweiTcpClient.appendSensorValue("sys",boot)
     --LeweiTcpClient.appendSensorValue("ram",node.heap())
     LeweiTcpClient.sendSensorValue("AI2",p)
     --boot = 0
end
end)

function M.stop()
     uploadtimer:stop()
end

function M.start()
     uploadtimer:start()
end

