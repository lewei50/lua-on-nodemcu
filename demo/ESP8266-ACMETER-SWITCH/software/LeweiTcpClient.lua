--------------------------------------------------------------------------------
-- LeweiTcpClient module for NODEMCU
-- LICENCE: http://opensource.org/licenses/MIT
-- yangbo<gyangbo@gmail.com>
--------------------------------------------------------------------------------

--[[
demo.lua:

require("LeweiTcpClient")
LeweiTcpClient.init("01","your_api_key_here")
function test(p1)
   print("test function!"..p1)
   LeweiTcpClient.sendSensorValue("sensor1",1)
end
function test2(p1)
   LeweiTcpClient.appendSensorValue("sensor2",0)
   print("test function!"..p1)
end
LeweiTcpClient.addUserSwitch(test,"switch01",1)
LeweiTcpClient.addUserSwitch(test2,"switch02",1)
]]--

local moduleName = ...
local M = {}
_G[moduleName] = M

local socket = nil
local server = "tcp.lewei50.com"
--local server = "192.168.2.5"--
local port = 9960
local bConnected = false
local gateWay = ""
local userKey = ""
local uSwitchNode = nil
local strOnline = ""
local strSensorValue = ""

--get value from string like "p1":"1","f":"getAllSensors"
local function getStrValue(str,strName)
     i,j = string.find(str,"\""..strName.."\":\"")
     k,l = string.find(string.sub(str, j+1, -1),"\"")
     return string.sub(str, j+1,j-1+l)
end

local function sendFeedBack(msg,data)
     responseStr = "{\"method\":\"response\",\"result\":{\"successful\":true,\"message\":\""..msg.."\""
     --data area is for switchs
     if(data ~= nil) then
          responseStr = responseStr..",\"data\":["..data.."]"
     end
     
     responseStr = responseStr.."}}&^!"
     --print(responseStr)
     socket:send(responseStr)
     responseStr = nil
end

local function dealResponse(str)
     ufunctionName = getStrValue(str,"f")
     if(ufunctionName == "getAllSensors") then
          local l = uSwitchNode
          nodeStr = ""
          local bFirstNode = nil
          while l do
               --to add a "," between each switch section
               if (bFirstNode == nil) then
                    bFirstNode = false
               else
                    nodeStr = nodeStr..","
               end
               nodeStr = nodeStr .."{\"id\":\""..l.value.usName.."\",\"value\":\""..l.value.usValue.."\"}"
               l = l.next
          end
          bFirstNode = nil
          sendFeedBack("OK",nodeStr)
          nodeStr = nil
          str = nil
          return
     elseif (ufunctionName == "updateSensor") then
          uswitchName = getStrValue(str,"p1")
          uswitchValue = getStrValue(str,"p2")
          --deal action for changing user's switch value
          local l = uSwitchNode
          nodeStr = ""
          local bFirstNode = nil
          while l do
               if(l.value.usName == uswitchName) then
                   l.value.usValue =  uswitchValue
                   l.value.usAdd(uswitchValue)
               end
               if (bFirstNode == nil) then
                    bFirstNode = false
               else
                    nodeStr = nodeStr..","
               end
               nodeStr = nodeStr .."{\"id\":\""..l.value.usName.."\",\"value\":\""..l.value.usValue.."\"}"
              l = l.next
          end
          sendFeedBack("OK",nodeStr)
          nodeStr = nil
          str = nil
          
          return
     end
     str = nil
end

local function connectServer()
     --print("cs")
     --print(node.heap())
     socket=net.createConnection(net.TCP, 0)
     --print(node.heap())
     --HTTP响应内容
     
     socket:on("connection", function(sck, response)
          --print("c")
          socket:send(strOnline)
          --print(node.heap())
          bConnected = true
     end)
     --print(node.heap())
     --[[
     socket:on("reconnection", function(sck, response)
          print("r")
     end)
     ]]--
     socket:on("disconnection", function(sck, response)
          --print("d")
          if(socket:getpeer()~=nil) then socket:close() end
          connectServer()
          bConnected = false
     end)
     --print(node.heap())
     socket:on("receive", function(sck, response)
          --print("receive"..response)
          dealResponse(response)
     end)
     --print(node.heap())
     socket:on("sent", function(sck, response)
          --print(tmr.now().."sent")
     end)
     --print(node.heap())
     socket:connect(port, server)
end


local function keepOnline()
     --print("k")
     if bConnected == true then
          socket:send(strOnline)
     else
          connectServer()         
     end
end


--add user defined switch with a default value
function M.addUserSwitch(uSwitchAdd,uSwitchName,uSwitchValue)
     --print("UserSwitch")
     local l = uSwitchNode
     while l do
          --make sure no Duplicated Adding
          if (uSwitchName == l.value.usName) then
               --update user switch
               l.value.usValue = uSwitchValue
               return
          end
         l = l.next
     end
     --data structure to store user's switchs
     uSwitchNode = {next = uSwitchNode, value = {usAdd=uSwitchAdd,usName=uSwitchName,usValue=uSwitchValue}}
     
end

function M.updateUserSwitch(uName,uValue)
     M.addUserSwitch(nil,uName,uValue)
end

function M.appendSensorValue(sName,sValue)
     strSensorValue=strSensorValue.."{\"Name\":\""..sName.."\",\"Value\":\""..sValue.."\"},"
end

function M.sendSensorValue(sName,sValue)
     sensorStr="{\"method\": \"upload\", \"data\":["..strSensorValue.."{\"Name\":\""..sName.."\",\"Value\":\""..sValue.."\"}]}&^!"
     socket:send(sensorStr)
     sensorStr = nil
     strSensorValue = ""
end

function M.init(gw,userkey)
     if(_G["gateWay"] ~= nil) then gateWay = _G["gateWay"]
     else gateWay = gw
     end
     if(_G["userKey"] ~= nil) then userKey = _G["userKey"]
     else userKey = userkey
     end

     strOnline = "{\"method\":\"update\",\"gatewayNo\":\""..gateWay.."\",\"userkey\":\""..userKey.."\"}&^!"

     connectServer()
     tmr.alarm(1, 50000, 1, function() 
          keepOnline()
     end)
end
