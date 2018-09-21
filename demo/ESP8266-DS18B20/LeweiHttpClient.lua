--------------------------------------------------------------------------------
-- LeweiHttpClient module for NODEMCU
-- LICENCE: http://opensource.org/licenses/MIT
-- yangbo<gyangbo@gmail.com>
--------------------------------------------------------------------------------

--[[
here is the demo.lua:

require("LeweiHttpClient")
LeweiHttpClient.init("01","your_api_key")
tmr.alarm(0, 60000, 1, function()
--添加数据，等待上传
LeweiHttpClient.appendSensorValue("sensor1","1")
--实际发送数据
LeweiHttpClient.sendSensorValue("sensor2","3")
end)
--]]

local moduleName = ...
local M = {}
_G[moduleName] = M
local serverName = "open.lewei50.com"
--local serverName = "192.168.0.5:81"
local serverIP

local gateWay
local userKey
local sn
local sensorValueTable
local apiUrl = ""
local apiLogUrl = ""
local socket = nil

function M.init(gw,ukey)
     if(_G["sn"] ~= nil) then sn = _G["sn"]
      apiUrl = "UpdateSensorsBySN/"..sn
      apiLogUrl = "updatelogBySN/"..sn
     else
          if(gw ~=nil) then
               gateWay = gw
               apiUrl = "UpdateSensors/"..gateWay
               apiLogUrl = "updatelog/"..gateWay
          end
          if(_G["userKey"] ~= nil) then userKey = _G["userKey"]
          else userKey = userkey
          end
     end
     print(apiUrl)
     sensorValueTable = {}
end

function M.appendSensorValue(sname,svalue)
     --sensorValueTable[""..sname]=""..svalue
     tmpTbl = {}
     tmpTbl["name"]=sname
     tmpTbl["value"]=svalue
     table.insert(sensorValueTable,tmpTbl)
end

function M.sendSensorValue(sname,svalue)
     M.appendSensorValue(sname,svalue)
     --创建一个TCP连接
     --socket=net.createConnection(net.TCP, 0)

     --[[
     --域名解析IP地址并赋值
     if(serverIP == nil) then
     socket:dns(serverName, function(conn, ip)
          print("Connection IP:" .. ip)
          serverIP = ip
          end)     
     end
     ]]--
     print(sjson.encode(sensorValueTable))
     print(serverName)
     if(userKey~=nil) then userkeyStr = "userkey:"..userKey.."\r\n" end
     if(apiUrl ~="") then 
          http.post('http://'..serverName.."/api/V1/gateway/"..apiUrl,
               userkeyStr,
               sjson.encode(sensorValueTable),
               function(code, data)
               if (code < 0) then
                print("HTTP request failed")
               else
                print(code, data)
                if(string.find(data, 'disabled'))then
                    snDisabled = true
                end
               end
          end)
     end
     sensorValueTable = {}
end
