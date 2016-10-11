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
     conn:on("receive",function(conn,payload)
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
          conn:send("HTTP/1.0 200 OK\r\nContent-type: text/html\r\nServer: ESP8266\r\n\n")
          conn:send("<html><head>")
          if(_G["wifiStatue"]=="Saved") then
          conn:send("<meta http-equiv=\"refresh\" content=\"30\">")
          end
          conn:send("</head><body><table><tr><td colspan=\"2\">")
          --file.open("logo.htm","r")
          --conn:send(file.read())
          
          conn:send("</td></tr><tr><td colspan=\"2\"><h2>Configuration</h2></div>")
          conn:send("<font color=\"red\">[<i>".._G["wifiStatue"].."</i>]</color>")
          if(_G["wifiStatue"]=="Saved") then
          conn:send("<br>wait 30 sec<br>Server lost mean NO ERROR MET.</td></tr>")
          else
	          conn:send("<FORM action=\"\" method=\"POST\">")
	          conn:send("<tr><td>")
	          
	          for vK,vN in ipairs(_G["config"]) do
	          conn:send("<tr><td>"..vN.name.."</td><td><input type=\"")
		  if(vN.name == "password") then
		  	conn:send(vN.name)
		  else
		  	conn:send("text")
		  end
	          conn:send("\" name=\""..vN.name.."\" value=\"")
	          if(_G[vN.name] ~= nil) then 
	          conn:send(_G[vN.name])
	          end
	          conn:send("\"></td></tr>")
	          end
	          conn:send("<tr><td><input type=\"submit\" value=\"SAVE\"></td></tr>")
	          conn:send("</form>")
               conn:send("</table>")
	          conn:send("</body>")
	          conn:send("</html>")
					end
	        conn:close()
          if(_G["wifiStatue"]=="Saved") then
               print("reboot")
               tmr.alarm(0,3000,0,function()node.restart() end )
          end
          --file.close()
     end)
     
     
end)

          if(_G["wifiStatue"]=="..." or _G["wifiStatue"]=="Failed") then 
               --keep server open for 10 min to configure
               --print("count down")
               tmr.alarm(0,6000000,0,function()
               print("2nd try")
               node.restart()
               end )
          end
