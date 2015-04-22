require("LeweiTcpClient")
LeweiTcpClient.init("01","your_api_key_here")
function test(p1)
   print("test function!"..p1)
end
--添加一个标识为switch01，初始值为1的开关
LeweiTcpClient.addUserSwitch(test,"switch01",1)