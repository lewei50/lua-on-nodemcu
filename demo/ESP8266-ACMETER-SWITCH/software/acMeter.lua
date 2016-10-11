local moduleName = ...
local M = {}
_G[moduleName] = M

--require('crc16')



local fb = ""
--uart.setup(0,4800,8,0,1,0)


local voltVal = nil
local powerVal = nil
local wattVal = nil

tmr.alarm(0, 2000, 1, function()
     uart.write(0,0x01)
     uart.write(0,0x03)
     uart.write(0,0x00)
     uart.write(0,0x48)
     uart.write(0,0x00)
     uart.write(0,0x08)
     uart.write(0,0xc4)
     uart.write(0,0x1a)
end)




function M.getData()
     local v,e,p
     v = voltVal
     p = powerVal
     e = wattVal
     voltVal = nil
     powerVal = nil
     wattVal = nil
     return v,p,e
end

function M.stopMeter()
     uart.setup(0,9600,8,0,1,0)
     tmr.stop(0)
     uart.on("data")
end

function M.startMeter()
     uart.setup(0,4800,8,0,1,0)
     tmr.start(0)
     uart.on("data",0,
      function(data)
        --print(data)
        fb = fb .. data
        --print(string.len(fb))
        if(string.len(fb)>=37) then
          --print(string.byte(fb,1))
          if(string.byte(fb,1) == 1 and string.byte(fb,2) == 3) then
               --change to crc later
               --uart.write(0,string.len(fb))
               voltVal = (string.byte(fb,4)*256*256*256+string.byte(fb,5)*256*256+string.byte(fb,6)*256+string.byte(fb,7))/10000
               ampVal = (string.byte(fb,8)*256*256*256+string.byte(fb,9)*256*256+string.byte(fb,10)*256+string.byte(fb,11))/10000
               wattVal =(string.byte(fb,12)*256*256*256+string.byte(fb,13)*256*256+string.byte(fb,14)*256+string.byte(fb,15))/10000
               powerVal =(string.byte(fb,16)*256*256*256+string.byte(fb,17)*256*256+string.byte(fb,18)*256+string.byte(fb,19))/10000
               factVal = (string.byte(fb,20)*256*256*256+string.byte(fb,21)*256*256+string.byte(fb,22)*256+string.byte(fb,23))/1000
               --print(voltVal.."v"..ampVal.."a"..wattVal.."w"..powerVal.."d"..factVal.."%")
               if(voltVal > 280 or ampVal >30) then --it can be much more than that value
                    voltVal = nil
                    ampVal = nil
                    wattVal = nil
                    powerVal = nil
                    factVal = nil
               end
          end
          fb = ""
        end
     
        if (string.find(data,"quit")~=nil) then 
          uart.on("data",0,
          function(data)
          print("quit")
          end,1) 
        end        
     end, 0)
end

return M
