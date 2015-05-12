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
local serverName = "ht.api.lewei50.com"
local serverIP

local gateWay
local userKey
local sn
local sensorValueTable
local apiUrl = ""
local apiLogUrl = ""
local socket = nil

function M.init(gw,ukey)
     if(_G["gateWay"] ~= nil) then gateWay = _G["gateWay"]
     else gateWay = gw
     end
     if(_G["userKey"] ~= nil) then userKey = _G["userKey"]
     else userKey = userkey
     end
     	apiUrl = "UpdateSensors/"..gateWay
     	apiLogUrl = "updatelog/"..gateWay
     if(_G["sn"] ~= nil) then sn = _G["sn"]
     	apiUrl = "UpdateSensorsBySN/"..sn
     	apiLogUrl = "updatelogBySN/"..sn
     end
     sensorValueTable = {}
end

function M.appendSensorValue(sname,svalue)
     sensorValueTable[""..sname]=""..svalue
end

function M.sendSensorValue(sname,svalue)
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
          
          --定义数据变量格式
          PostData = "["
          for i,v in pairs(sensorValueTable) do 
               PostData = PostData .. "{\"Name\":\""..i.."\",\"Value\":\"" .. v .. "\"},"
               --print(i)
               --print(v) 
          end
          PostData = PostData .."{\"Name\":\""..sname.."\",\"Value\":\"" .. svalue .. "\"}"
          PostData = PostData .. "]"
          --HTTP请求头定义
          socket:send("POST /api/V1/gateway/"..apiUrl.." HTTP/1.1\r\n")
          socket:send("Host: "..serverName.."\r\n")
          socket:send("Content-Length: " .. string.len(PostData) .. "\r\n")
          if(userKey~=nil) then socket:send("userkey: "..userKey.."\r\n") end
          socket:send("\r\n"..PostData .. "\r\n")
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
          print(node.heap())
        end)
     end
end

function M.sendLog(logStr)
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
          
          --定义数据变量格式
          PostData = "{\"Message\":\"" .. logStr .. "\"}"
          --HTTP请求头定义
          socket:send("POST /api/V1/gateway/"..apiLogUrl.." HTTP/1.1\r\n")
          socket:send("Host: "..serverName.."\r\n")
          socket:send("Content-Length: " .. string.len(PostData) .. "\r\n")
          if(userKey~=nil) then socket:send("userkey: "..userKey.."\r\n") end
          socket:send("\r\n"..PostData .. "\r\n")
          end)
     
     --HTTP响应内容
     socket:on("receive", function(sck, response)
          --print(response)
          PostData = nil
          socket:close()
          print("log send")
        end)
     end
end
