ssid="ESP8266_".. node.chipid()
password="12345678"

function decodeURI(s)
    s = string.gsub(s, '%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
    return s.gsub(s,'\+',' ')
end


_G["para"] = {}

wifi.setmode(wifi.SOFTAP)
--set ap ssid and pwd
cfg={}
cfg.ssid=ssid
cfg.pwd=password
wifi.ap.config(cfg)
print(wifi.ap.getip())

--  http server


srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
	conn:on("receive",function(sck,payload)
		--print(payload)
		print("received")
		--find last line in plyload(stupid function,improve later)
		local i = 0
		local j = 0
		while true do
		     i = string.find(payload, "\n", i+1)
		     -- find 'next' newline  
		     if i == nil then break
		     else 
		     j=i
		     end    
		end
		paraStr = string.sub(payload,j)
		
		
		--there should be a "=" in Post data,such as ssid=id&password=ps
		if (string.find(paraStr,"=")~=nil) then
		     file.open("network_user_cfg.lua","w+")
		     for name, value in string.gfind(paraStr, "([^&=]+)=([^&=]+)") do
		       file.writeline(decodeURI(name).."=\""..decodeURI(value).."\"")
		     end
		     
		     _G["wifiStatue"]="Saved"
		     print("store ok")
		     file.close()
		end
		paraStr = nil
		
		-- html-output
		
		local response = {}
		
		-- if you're sending back HTML over HTTP you'll want something like this instead
		-- local response = {"HTTP/1.0 200 OK\r\nServer: NodeMCU on ESP8266\r\nContent-Type: text/html\r\n\r\n"}
		
		response[#response + 1] = "HTTP/1.0 200 OK\r\nContent-type: text/html\r\nServer: ESP8266\r\n\n<html><head>"
		
		if(_G["wifiStatue"]=="Saved") then
			response[#response + 1] = "<meta http-equiv=\"refresh\" content=\"30\">"
		end
		response[#response + 1] = "</head><body><table><tr><td colspan=\"2\"></td></tr><tr><td colspan=\"2\"><h2>Configuration</h2></div>"
		response[#response + 1] = "<font color=\"red\">[<i>".._G["wifiStatue"].."</i>]</color>"
		
		if(_G["wifiStatue"]=="Saved") then
			response[#response + 1] = "<br>wait 30 sec<br>Server lost mean NO ERROR MET.</td></tr>"
		else
			response[#response + 1] = "<FORM action=\"\" method=\"POST\"><tr><td>"
		end
		for vK,vN in ipairs(_G["config"]) do
			response[#response + 1] ="<tr><td>"..vN.name.."</td><td><input type=\""
		if(vN.name == "password") then
			response[#response + 1] = vN.name
		else
			response[#response + 1] = "text"
		end
		response[#response + 1] = "\" name=\""..vN.name.."\" value=\""
		if(_G[vN.name] ~= nil) then 
			response[#response + 1] = _G[vN.name]
		end
			response[#response + 1] = "\"></td></tr>"
		end
		response[#response + 1] = "<tr><td><input type=\"submit\" value=\"SAVE\"></td></tr>"
		response[#response + 1] = "</form></table></body></html>"
		
		
		if(_G["wifiStatue"]=="Saved") then
			print("reboot")
			tmr.alarm(0,3000,0,function()node.restart() end )
		end
		
		if(_G["wifiStatue"]=="..." or _G["wifiStatue"]=="Failed") then 
			--keep server open for 10 min to configure
			--print("count down")
			tmr.alarm(0,240000,0,function()
				--print("2nd try")
				node.restart()
			end )
		end
		
		-- sends and removes the first element from the 'response' table
		local function send(sk)
			if #response > 0
			then sk:send(table.remove(response, 1))
			else
				sk:close()
				response = nil
			end
		end
		
		-- triggers the send() function again once the first chunk of data was sent
		sck:on("sent", send)
		
		send(sck)
	
	
	end)
end)

gpio.write(1,gpio.HIGH)
gpio.write(2,gpio.LOW)
