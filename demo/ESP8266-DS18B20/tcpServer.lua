

local moduleName = ...
local M = {}
_G[moduleName] = M

--TCP_server = "192.168.1.129"--"192.168.1.129"--
--TCP_port = 9970
--strOnline = ""
flag = false
local mytimer = tmr.create()


local function connectServer()
     tmr.register(mytimer, math.random(10000), tmr.ALARM_SINGLE, function (t) 
          
          conn=net.createConnection(net.TCP, 0)
          --print("net"..node.heap())    
          conn:on("connection", function(sck, response)
               conn:send(strOnline)
               flag = true 
               --[[
               uart.on('data',function(data)
                         conn:send(data)
               end,0)    
               ]]--
          end)
          conn:on("disconnection", function(sck, response)  
               connectServer() 
               flag = false 
          end)     
          conn:on("receive", function(sck, response) 
               --uart.write(0,response)
               if(response=="read")then
                    M.keepOnline()
               end
               --conn:close()
          end)      
         
        conn:connect(TCP_port,TCP_server)  
        tmr.unregister(t) end)
     if(tmr.state(mytimer)==false) then tmr.start(mytimer) end

end

function M.keepOnline()
     --print(node.heap())
     if(tcpSvr) then
          if flag == true then
               conn:send(strOnline)
          else
               connectServer()         
          end
     end
end

function M.init()
     if(tcpSvr) then
          local result = {}
          for match in (tcpSvr..":"):gmatch("(.-)"..":") do
             table.insert(result, match)
          end
          if(result[1]~=nil and result[2]~=nil) then
               TCP_server = result[1]
               TCP_port = result[2]
          end  
          
          connectServer()
     end
     --print("Server:"..TCP_server..":"..TCP_port)
     --print(User_defined)
     --strOnline = 0x0
     --print(strOnline)
end
