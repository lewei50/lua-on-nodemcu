require("LeweiHttpClient")
LeweiHttpClient.init("01","your_api_key")
tmr.alarm(0, 60000, 1, function()
--添加数据，等待上传
LeweiHttpClient.appendSensorValue("sensor1","1")
LeweiHttpClient.appendSensorValue("sensor2","2")
--实际发送数据
LeweiHttpClient.sendSensorValue("sensor3","3")
end)