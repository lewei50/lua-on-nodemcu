ip = "192.168.4.1"
svr = nil
chipId = string.format("%x",node.chipid())
mac = wifi.sta.getmac()
mac = string.gsub(mac, ":", "")

snDisabled = false
strOnline = ""
sensorState=""
sensorData=""

gateWay = nil
userKey = nil
regCode = ""


function getTemp()
     sensorState = "succeed"
     local pin = 5
     local dhtStatus, temp, humi, temp_dec, humi_dec = dht.read(pin)
     if dhtStatus == dht.OK then
          -- Float firmware using this example
          --print("DHT Temperature:"..temp..";".."Humidity:"..humi)
          temp = string.format("%0.1f",temp)
          humi = string.format("%0.1f",humi)
          sensorData = temp..","..humi
          T1 = temp
          H1 = humi
     else
          H1 = nil
          --sensorState = "fail"
          --sensorData = ""
          local ow_pin = 5
          ds18b20.setup(ow_pin)
          -- read all sensors and print all measurement results
          ds18b20.read(
          function(ind,rom,res,temp,tdec,par)
               if(temp ~= nil) then
                    sensorData = string.format("%0.1f",temp)
                    T1 = temp
                    H1 = nil
               else
                    sensorState = "fail"
                    sensorData = ""
                    T1 = nil
               end
          end,{})
     end
     
     strOnline = '{"status":"${sensorState}","data":[${sensorData}],"sn":"${regCode}","mac":"${mac}"}'
     strOnline = strOnline:gsub('($%b{})', function(w)
          return _G[w:sub(3, -2)] or ""
     end)
     --[[
     strOnline = "{\"status\":\""..sensorState.."\","
     strOnline = strOnline .."\"data\":["..sensorData.."],"
     strOnline = strOnline .."\"sn\":\"".. regCode .."\","
     strOnline = strOnline .."\"mac\":\""..string.gsub(mac, ":", "")
     strOnline = strOnline .."\"}"
     ]]--
     return temp
end

function updateRegCode()
     if(regCode~="") then
          local result = {}
          for match in (regCode.."_"):gmatch("(.-)".."_") do
             table.insert(result, match)
          end
          if(result[1]~=nil and result[2]~=nil) then
               userKey = result[1]
               gateWay = result[2]
               if(LeweiHttpClient ~= nil) then
                    LeweiHttpClient.init(gateWay,userKey)
               end
          else
               sn = regCode
          end             
          regCodeShort =string.sub(regCode,-10,-1)
     else
          regCodeShort = ""
     end
end


tmr.alarm(0,2000,0,function()

if(wifi.sta.getip() ~= nil) then
     ip = wifi.sta.getip()
end
require("config")
require("devConfig")
updateRegCode()

function setupDefaultAp()
     --print("start ap")
     cfg={}
     cfg.ssid="eMonitor"
     if(regCode~=nil and regCode~='') then
          cfg.ssid="eMonitor-"..regCodeShort
     end
     cfg.pwd="12345678"
     if(wifi.ap.config(cfg))then
          print("AP ON")
          setupServer()
     end
end

function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local unescape = function (s)
     s = string.gsub(s, "+", " ")
     s = string.gsub(s, "%%(%x%x)", function (h)
          return string.char(tonumber(h, 16))
         end)
     return s
end



local function setupSSDP()
     --print("setupssdp")
     if(wifi.sta.getip() ~= nil) then
          if(tmr.state(0)== nil) then
               tmr.alarm(0,30000,0,function()
                    print("AP OFF")
                    wifi.setmode(wifi.STATION)
                    require("run")
                    require('upnp')
               end)
          end
     end
end


function setupServer()
     if srv ~= nil then srv:close() end
     --print("webserver on")
     srv=net.createServer(net.TCP)
     srv:listen(80,function(conn)
     conn:on("receive", function(client,request)
          --local buf = ""
          writeConfig = false
          local fetchFile = "wifi.html"
          local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");

          --if(method == nil)then
           _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
          print(method,path,vars)
          if(path =="/dev") then
               writeConfig = true
               fetchFile = "dev.html"
          elseif(path =="/info.xml") then
               fetchFile = "info.xml"
          elseif(path=="/" or string.find(path,"?")~=nil) then
               writeConfig = true
          else--if(path =="/monitorjson.htm") then
               getTemp()
               fetchFile = "monitor.json"
               --buf = strOnline
          end
     	print("Send HTML File:"..fetchFile)
     	--print(node.heap())
     	if (file.open(fetchFile,'r')) then
     	    buf = file.read()
     	    file.close()
     	end
               
          --end
          --end
          local _GET = {}
          configFile = "config.lua"
          if (vars ~= nil)then
               for k, v in string.gmatch(vars, "([_%w]+)=([^%&]+)&*") do
                    _GET[k] = unescape(v)
                    if(k=="regCode" or k=="tcpSvr")then configFile = "devConfig.lua" end
               end
          end
          cfgContent = ""
          -- write every variable in the form
          for k,v in pairs(_GET) do
               cfgContent = cfgContent .. k..' = "'..v ..'"\r\n'
               _G[k]=v
          end
          if(cfgContent ~= "" and writeConfig==true) then
               if(file.open(configFile, "w+")) then
                    --print("writing cfg:"..configFile)
                    file.write(cfgContent)
                    cfgContent = ""
                    file.close()
                    dofile(configFile)
                    updateRegCode()
               end
          end

          if (_GET.password ~= nil) then
               if (_GET.ssid == "-1") then _GET.ssid=_GET.hiddenssid end
               --_G['html_head']="<meta http-equiv=\"refresh\" content=\"5;url=\\\">"
               --if(wifi.sta.status()~=5) then
                    _G['status']="Saved.Connecting..."
                    station_cfg={}
                    station_cfg.ssid=_GET.ssid
                    station_cfg.pwd=_GET.password
                    station_cfg.save=true
                    wifi.sta.config(station_cfg)
               --end
           end
           if(_G['status']=="Saved.Connecting...")then
               _G['html_head']="<meta http-equiv=\"refresh\" content=\"10;url=\\\">"
           end
          --node.compile("config.lua")
          --file.remove("config.lua")
          --client:send(buf);
          --node.restart();

          buf = buf:gsub('($%b{})', function(w)
               return _G[w:sub(3, -2)] or ""
          end)

          payloadLen = string.len(buf)
          client:send("HTTP/1.1 200 OK\r\n")
          --print("info:",info)
          if(info~="" and info~= nil) then
               client:send("Content-Type: text/xml\r\n")
          else
               client:send("Content-Type: text/html; charset=UTF-8\r\n")
               client:send("Content-Length:" .. tostring(payloadLen) .. "\r\n")
          end
          client:send("Connection:close\r\n\r\n")
          if(info~="" and info~= nil) then client:send(buf, function(client) client:close() end);
          --print(info)
               info = nil
          else
               client:send(buf, function(client) client:close() end);
          end
          buf = nil
          _G['html_head']=""
          _GET = nil
          --print(node.heap())
          collectgarbage()
          end)
     end)
     --print("Webserver ready: " .. ip)
     setupSSDP()
end


function setupMonitor()
     wifi.eventmon.register(wifi.eventmon.STA_CONNECTED, function(T)
     print("\n\tSTA - CONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
     T.BSSID.."\n\tChannel: "..T.channel)
     end)
     wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T)
               print("\n\tSTA - DISCONNECTED".."\n\tSSID: "..T.SSID.."\n\tBSSID: "..
               T.BSSID.."\n\treason: "..T.reason)
               _G['status']="wifi error code:"..T.reason
               wifi.sta.disconnect()
               wifi.sta.connect()
          if(tmr.state(0)== nil) then
               setupDefaultAp()
               --restart in 5 min later
               tmr.alarm(0,300000,0,function()
                    --wifi.sta.connect()
                    node.restart()
               end)
          end
     end)
     wifi.eventmon.register(wifi.eventmon.STA_GOT_IP, function(T)
     print("\n\tSTA - GOT IP".."\n\tStation IP: "..T.IP.."\n\tSubnet mask: "..
     T.netmask.."\n\tGateway IP: "..T.gateway)
     --_G['html_head']="<meta http-equiv=\"refresh\" content=\"25;url=http://"..T.IP.."\\\">"
     ip = T.IP
     _G['status']="Connected"
     setupServer()
     --setupSSDP()
     end)
end

wifi.setmode(wifi.STATIONAP)
setupMonitor()
ssid, password, bssid_set, bssid=wifi.sta.getconfig()

if(ssid==nil or ssid=="")then
     setupDefaultAp()
else
     print("Connecting")
     wifi.sta.connect()
     if(wifi.sta.getip()~=nil) then
          setupServer()
     end
end

end )
tmr.alarm(1, 3000, 1, function()
    getTemp()
end)
