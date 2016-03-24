--------------------------------------------------------------------------------
-- EasyWebConfig module for NODEMCU
-- LICENCE: http://opensource.org/licenses/MIT
-- yangbo<gyangbo@gmail.com>
--------------------------------------------------------------------------------

--[[
here is the demo.lua:
require("EasyWebConfig")
--EasyWebConfig.addVar("gateWay")
--EasyWebConfig.addVar("userKey")
EasyWebConfig.doMyFile("demo.lua")
--]]
local moduleName = ...
local M = {}
_G[moduleName] = M
_G["wifiStatue"] = "..."

_G["config"]  = {}

local userScriptFile = ""


function M.doMyFile(fName)
     userScriptFile = fName
end

function M.addVar(vName)
     table.insert(_G["config"],{name=vName,value=""})
end

M.addVar("ssid")
M.addVar("password")

--try to open user configuration file
if( file.open("network_user_cfg.lua") ~= nil) then
     ssid=""
     password=""
     require("network_user_cfg")
          --print("set up wifi mode")
          wifi.setmode(wifi.STATION)
          --please config ssid and password according to settings of your wireless router.
          wifi.sta.config(ssid,password)
          wifi.sta.connect()
          cnt = 0
          tmr.alarm(1, 1000, 1, function()
               if (wifi.sta.getip() == nil) and (cnt < 10) then
                    --print(".")
                    cnt = cnt + 1
               else
                    tmr.stop(1)
                    if (cnt < 10) then print("IP:"..wifi.sta.getip())
                         --_G["wifiStatue"] = "OK"
                         if(userScriptFile ~="") then 
                              --print(node.heap())
                              --for n in pairs(_G) do print(n) end
                              ssid= nil
                              password = nil
                              _G["config"] = nil
                              --M = nil
                              --print("---")
                              --for n in pairs(_G) do print(n) end
                              --print(node.heap())
                              _G["EasyWebConfig"]=nil
                              package.loaded["network_user_cfg"]=nil
                              package.loaded["EasyWebConfig"]=nil
                              dofile(userScriptFile) 
                         end
                    else print("FailToConnect,LoadDefault")
                         wifi.sta.disconnect()
                         _G["wifiStatue"] = "Failed"
                         require("network_default_cfg")
                         print ("LoadDefault")
                         disp:firstPage()
                         repeat
                         disp:drawStr(10,10,"Configuration:")
                         disp:drawStr(10,25,"WIFI:"..ssid)
                         disp:drawStr(10,35,"PSWD:"..password)
                         disp:drawStr(10,45,"Open URL:192.168.4.1")
                         until disp:nextPage() == false 
                    end
               end
          end)
else
     require("network_default_cfg")
     print ("LoadDefault")
     disp:firstPage()
     repeat
     disp:drawStr(10,10,"Configuration:")
     disp:drawStr(10,25,"WIFI:"..ssid)
     disp:drawStr(10,35,"PSWD:"..password)
     disp:drawStr(10,45,"Open URL:192.168.4.1")
     until disp:nextPage() == false 
end
