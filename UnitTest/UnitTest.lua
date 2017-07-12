NPL.load("(gl)../script/ide/UnitTest/luaunit.lua");
NPL.load("(gl)npl_mod/Raft/test/TestClusterConfiguration.lua");
NPL.load("(gl)npl_mod/Raft/test/TestSnapshotSyncRequest.lua");
NPL.load("(gl)npl_mod/Raft/test/TestFileBasedSequentialLogStore.lua");
NPL.load("(gl)npl_mod/Raft/test/TestServerStateManager.lua");
NPL.load("(gl)npl_mod/TableDB/test/TestRaftLogEntryValue.lua");
LuaUnit:run('TestRaftLogEntryValue');
LuaUnit:run('TestFileBasedSequentialLogStore');
LuaUnit:run('TestClusterConfiguration');
LuaUnit:run('TestSnapshotSyncRequest');
LuaUnit:run('TestServerStateManager');
ParaGlobal.Exit(0)