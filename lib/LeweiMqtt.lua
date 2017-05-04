-- ***************************************************************************
-- LeweiMQTT module for ESP8266 with nodeMCU
-- LeweiMQTT compatible tested 20170117
-- need CJSON,MQTT modules for Nodemcu firmware
--
-- Written by yangbo
--
-- MIT license, http://opensource.org/licenses/MIT
-- ***************************************************************************

--[[
--*****sample*****
wifi.setmode(wifi.STATION)

station_cfg={}
station_cfg.ssid="WIFI_SSID"
station_cfg.pwd="WIFI_PASSWORD"
wifi.sta.config(station_cfg)
wifi.sta.connect()

require("LeweiMqtt")
LeweiMqtt.init("LEWEI_USERKEY","LEWEI_GATEWAY")


function localFnAppendSensorValue(p1)
   LeweiMqtt.appendSensorValue("sensor2",0)
   print("test function!"..p1)
end

function localFnSendSensorValue(p1)
   print("test function1!"..p1)
   LeweiMqtt.sendSensorValue("t1",1)
end

--add 2 switches on LEWEI50 website,name them "a","s"
LeweiMqtt.addUserSwitch(localFnAppendSensorValue,"a",1)
LeweiMqtt.addUserSwitch(localFnSendSensorValue,"s",1)

wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..T.netmask.."\n\tGateway IP: "..T.gateway)
LeweiMqtt.connect()

end)
wifi.sta.eventMonStart()
]]--

local moduleName = 'LeweiMqtt'
local M = {}
_G[moduleName] = M

local serverName = "mqtt.lewei50.com"
local serverPort = 1883
local gateWay
local userKey
local sn
local clientId
local sensorValueTable = {}
local uSwitchNode = nil
local m
local bConnected = false
local onlineChkTmr = tmr.create()


local cjson = require("cjson")

function M.init(uKey,gw,tmOut)
     if(tmOut==nil)then tmOut = 120 end
     clientId = uKey.."_"..gw
     if(_G["sn"] ~= nil) then sn = _G["sn"]
          clientId = sn
     end
     sensorValueTable = {}

     
     m = mqtt.Client(clientId, tmOut)
     
     --set a timer to keep online
     onlineChkTmr:register(15000+math.random(60000), tmr.ALARM_AUTO, function()
          M.connect()
     end)
     
end


function M.appendSensorValue(sname,svalue)
     sensorValueTable[""..sname]=""..svalue
end


function M.sendSensorValue(sname,svalue)
     --定义数据变量格式
     PostData = "["
     for i,v in pairs(sensorValueTable) do 
          PostData = PostData .. "{\"Name\":\""..i.."\",\"Value\":\"" .. v .. "\"},"
          --print(i)
          --print(v) 
     end
     PostData = PostData .."{\"Name\":\""..sname.."\",\"Value\":\"" .. svalue .. "\"}"
     PostData = PostData .. "]"
     
     if(bConnected) then
          m:publish("/lw/u/"..clientId,PostData,0,0, function(client)
               print("sent")
               PostData = ""
          end)
     end
end


--add user defined switch with a default value
function M.addUserSwitch(uSwitchAdd,uSwitchName,uSwitchValue)
     
     --print("addUserSwitch"..uSwitchName..":"..uSwitchValue)
     --print("UserSwitch")
     local l = uSwitchNode
     while l do
          --make sure no Duplicated Adding
          if (uSwitchName == l.value.usName) then
               --update user switch
               l.value.usValue = uSwitchValue
               l.value.usAdd(uSwitchValue)
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

local function sendFeedBack(msg,data)
     responseStr = "{\"successful\":true,\"message\":\""..msg.."\""
     --data area is for switchs
     if(data ~= nil) then
          responseStr = responseStr..",\"data\":["..data.."]"
     end
     
     responseStr = responseStr.."}"
     --print(responseStr)
     m:publish("/lw/r/"..clientId,responseStr,0,0, function(client) print("answered") end)
     responseStr = nil
end

local function fbSwitchState()
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
end


function M.connect()
     -- for TLS: m:connect("192.168.11.118", secure-port, 1)
     print ("connecting")
     m:on("offline", function(client) 
          print (" offline")
          bConnected = false
          onlineChkTmr:start()
     end)
     
     -- on publish message receive event
     m:on("message", function(client, topic, data) 
          if(topic == "/lw/c/"..clientId) then
            if data ~= nil then
              --print(topic .. ":" ..data)
              r = cjson.decode(data)
              if(r['f']=="getAllSensors") then
               fbSwitchState()
              elseif(r['f']=="updateSensor") then
               M.updateUserSwitch(r['p1'],r['p2'])
               fbSwitchState()
              end
            end
          end
     end)
     
     --m:connect(serverName, serverPort)
     m:connect(serverName, serverPort, 0, function(client)
          print("connected") 
          onlineChkTmr:stop()
          bConnected = true
          m:subscribe("/lw/c/"..clientId,0, function(client) print("subscribe success") end)
     end, function(client, reason)
          print("failed reason: "..reason) 
     end)
end

return M
