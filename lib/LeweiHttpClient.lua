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
local serverIP

local gateWay
local userKey
local sn
local sensorValueTable
local apiUrl = ""
local socket = nil

function M.init(gw,ukey)
     if(_G["gateWay"] ~= nil) then gateWay = _G["gateWay"]
     else gateWay = gw
     end
     if(_G["userKey"] ~= nil) then userKey = _G["userKey"]
     else userKey = ukey
     end
     	apiUrl = "UpdateSensors/"..gateWay
     if(_G["sn"] ~= nil) then sn = _G["sn"]
     	apiUrl = "UpdateSensorsBySN/"..sn
     end
     sensorValueTable = {}
end

function M.appendSensorValue(sname,svalue)
     sensorValueTable[""..sname]=""..svalue
end

function M.sendSensorValue(sname,svalue)
     if(wifi.sta.getip()==nil)then node.restart() end
     --创建一个TCP连接
     socket=net.createConnection(net.TCP, 0)

     --域名解析IP地址并赋值
     if(serverIP == nil) then
     socket:dns(serverName, function(conn, ip)
          print("Connection IP:" .. ip)
          serverIP = ip
          end)     
     end

     if(serverIP ~= nil) then
     
     socket:connect(80, serverIP)
     socket:on("connection", function(sck, response)
          cntLen = 0
          for i,v in pairs(sensorValueTable) do
          cntLen = cntLen + string.len(i)+string.len(v)+23
          end
          cntLen = cntLen + string.len(sname)+string.len(svalue)+24

          --定义数据变量格式
          --HTTP请求头定义
          pl = ""
          pl = pl .. "POST /api/V1/gateway/"..apiUrl.." HTTP/1.1\r\n"
          pl = pl .. "Host: "..serverName.."\r\n"
          pl = pl .. "Content-Length: " .. cntLen .. "\r\n"
          if(userKey~=nil) then pl = pl .. "userkey: "..userKey.."\r\n" end
          pl = pl .. "\r\n"
          pl = pl .. "["
          for i,v in pairs(sensorValueTable) do 
               pl = pl .. "{\"Name\":\""..i.."\",\"Value\":\"" .. v .. "\"},"
               --print(i)
               --print(v) 
          end
          pl = pl .. "{\"Name\":\""..sname.."\",\"Value\":\"" .. svalue .. "\"}"
          pl = pl .. "]"
          socket:send(pl .. "\r\n")
          end)
          --socket:on("sent", function(sck, response)
               --print(tmr.now().."sent")
          --sensorValueTable  = {}
          --end)
     
     --HTTP响应内容
     socket:on("receive", function(sck, response)
          --print(response)
          PostData = nil
          socket:close()
          --print(node.heap())
        end)
     end
end
