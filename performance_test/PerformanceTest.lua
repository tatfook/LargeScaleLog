function PerformanceTest()

	NPL.load("(gl)script/ide/System/Database/TableDatabase.lua");
	local TableDatabase = commonlib.gettable("System.Database.TableDatabase");
	local db = TableDatabase:new():connect("temp/test_raft_database/", function() end);
	db.PerformanceTest:makeEmpty({});
	db.PerformanceTest:flush({});
	db.User:insertOne(nil, {name="1", email="1@1",}, function(err, data)  assert(data.email=="1@1") 	end);
	
	count =0;
	local startTime = os.time();
	for i=1,10000 do
		count = count+1;
		db.PerformanceTest:insertOne(nil, {count = count, data = count,}, function() end);
	end
	local endTime = os.time();
	logger.info("time:%d",endTime-startTime);

end