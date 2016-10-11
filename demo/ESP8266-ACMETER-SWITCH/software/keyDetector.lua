local moduleName = ...
local M = {}
_G[moduleName] = M

local pulse1 = 0
local du = 0

local flashButton = 7
--bEnabledPMS = true


local swtState



function noOp(level)
print("no op")
end

function M.setSwtState(state)
     swtState = state
     
     gpio.mode(0,gpio.OUTPUT)
     gpio.write(0,state)
     print(state)
     if file.open("swtState.lua", "w+") then
       -- write 'foo bar' to the end of the file
       file.writeline(state)
       file.close()
     end
     if(wifi.sta.getip()~=nil and LeweiTcpClient ~= nil) then
          print("update LeweiTcpClient")
          LeweiTcpClient.updateUserSwitch("DO",state)
     end
end

function M.getSwtState()
     return swtState
end

function shortPress()
     if(swtState== 1) then 
          M.setSwtState(0)
          swtState= 0
     else 
          M.setSwtState(1)
          swtState= 1
     end
     tmr.stop(6)
end

function longPress()
     tmr.stop(6)
     gpio.trig(flashButton, "down")
     acMeter.stopMeter()
     require("EasyWebConfig")
     EasyWebConfig.addVar("gateWay")
     EasyWebConfig.addVar("userKey")
     EasyWebConfig.doMyFile("run.lc")
end

function pin1cb(level)
     if level == 1 then 
          --print("up"..tmr.now().."-"..pulse1)
          gpio.trig(flashButton, "down",pin1cb) 
          du = tmr.now()-pulse1
          if(du<50000)then
               --ignor
          elseif(du<600000)then
                    shortPress()
          end
     else 
          --print("down"..tmr.now())
          pulse1 = tmr.now()
          tmr.alarm(6, 3000, 0, function()
               print("3s")
               longPress()
               end )
          gpio.trig(flashButton, "up",pin1cb) 
     end
     --print(node.heap())
end


function M.disableTrig()
--print("disable trig")
gpio.mode(flashButton,gpio.INT)
--print("disable trig1")
     gpio.trig(flashButton, "down",noOp)
--print("disable trig2")
end

function M.enableTrig()
--print("enable trig")
gpio.mode(flashButton,gpio.INT)
     gpio.trig(flashButton, "down",pin1cb)
end
--enableTrig()

if file.open("swtState.lua", "r") then
  swtState = file.read(1)
  file.close()
  M.setSwtState(swtState)
end

return M
