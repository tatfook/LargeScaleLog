--[[ 
Title: NPL Compiler
Author: LiXizhi
Date: 2010/10/9
Desc: 
The bytecode generated by Luajit is incompatible with lua, but is cross-platform for any architecture. 
I.e. string.dump(f [,strip]) generates portable bytecode. 
The generated bytecode is portable and can be loaded on any architecture that LuaJIT supports, 
independent of word size or endianess. 

See: http://luajit.org/extensions.html

An extra argument has been added to string.dump(). If set to true, 'stripped' bytecode without debug information is generated. 
This speeds up later bytecode loading and reduces memory usage. See also the -b command line option.
The generated bytecode is portable and can be loaded on any architecture that LuaJIT supports, independent of word size or 
endianess. However the bytecode compatibility versions must match. Bytecode stays compatible for dot releases (x.y.0 �� x.y.1), 
but may change with major or minor releases (2.0 �� 2.1) or between any beta release. 
Foreign bytecode (e.g. from Lua 5.1) is incompatible and cannot be loaded. 

-----------------------------------------------
NPL.load("(gl)script/ide/Debugger/NPLCompiler.lua");
NPL.CompileFiles("script/config.lua");
-- *.npl is also supported with meta-compiler
NPL.CompileFiles("script/ide/System/Compiler/dsl/DSL_NPL.npl");
-----------------------------------------------
]]
-- luac.lua - partial reimplementation of luac in Lua.
-- http://lua-users.org/wiki/LuaCompilerInLua
-- David Manura et al.
-- Licensed under the same terms as Lua (MIT license).
local function npl_compile(...)
	local arg = {...};
	local outfile = 'luac.out'

	-- Parse options.
	local chunks = {}
	local allowoptions = true
	local iserror = false
	local parseonly = false
	while arg[1] do
	  if     allowoptions and arg[1] == '-' then
		chunks[#chunks + 1] = arg[1]
		allowoptions = false
	  elseif allowoptions and arg[1] == '-l' then
		LOG.std("", "warn", "NPL", '-l option not implemented')
		iserror = true
	  elseif allowoptions and arg[1] == '-o' then
		outfile = assert(arg[2], '-o needs argument')
		table.remove(arg, 1)
	  elseif allowoptions and arg[1] == '-p' then
		parseonly = true
	  elseif allowoptions and arg[1] == '-s' then
		LOG.std("", "warn", "NPL", "-s option ignored")
	  elseif allowoptions and arg[1] == '-v' then
		LOG.std("", "warn", "NPL", tostring(_VERSION).. " Copyright (C) 2007-2010 ParaEngine Co.")
	  elseif allowoptions and arg[1] == '--' then
		allowoptions = false
	  elseif allowoptions and arg[1]:sub(1,1) == '-' then
		LOG.std("", "warn", "NPL", "luac: unrecognized option '" .. arg[1]);
		iserror = true
		break
	  else
		chunks[#chunks + 1] = arg[1]
	  end
	  table.remove(arg, 1)
	end
	if #chunks == 0 then
	  LOG.std("", "warn", "NPL", "luac: no input files given");
	  iserror = true
	end

	if iserror then
	  LOG.std("", "error", "NPL", [[
	usage: luac [options] [filenames].
	Available options are:
	  -        process stdin
	  -l       list
	  -o name  output to file 'name' (default is "luac.out")
	  -p       parse only
	  -s       strip debug information
	  -v       show version information
	  --       stop handling options
	]])
	end

	-- Load/compile chunks.
	for i,filename in ipairs(chunks) do
		--chunks[i] = assert(loadfile(filename ~= '-' and filename or nil))
		local file = ParaIO.open(filename, "r");
		if(file:IsValid()) then
			local text = file:GetText();
			if(filename:match("%.npl$")) then
				NPL.load("(gl)script/ide/System/Compiler/nplc.lua");
				chunks[i] = assert(NPL.loadstring(text, filename));
			else
				chunks[i] = assert(loadstring(text, filename));
			end
			file:close();
		else
			LOG.std(nil, "warn", "NPL.compiler", "file: %s not found or size is 0",  filename);
			return;
		end
	end

	if parseonly then
	  return
	end

	-- Combine chunks.
	if #chunks == 1 then
	  chunks = chunks[1]
	else
	  -- Note: the reliance on loadstring is possibly not ideal,
	  -- though likely unavoidable.
	  local ts = { "local loadstring=loadstring;"  }
	  for i,f in ipairs(chunks) do
		ts[i] = ("loadstring%q(...);"):format(string.dump(f))
	  end
	  --possible extension: ts[#ts] = 'return ' .. ts[#ts]
	  chunks = assert(loadstring(table.concat(ts)))
	end

	-- Output.
	local out = assert(ParaIO.open(outfile, "wb"))
	local data = string.dump(chunks);
	out:write(data, #data);
	out:close();
end

-- now we will override the NPL.Compile function. 
function NPL.Compile(cmdLine)
	if(cmdLine) then
		local args = {};
		local arg;
		for arg in cmdLine:gmatch("[^\" \t]+") do 
			args[#args + 1] = arg;
		end
		-- LOG.info({cmdLine, args})
		local ok, errmsg = pcall(function() npl_compile(unpack(args)) end );
		if(not ok and errmsg) then
			LOG.std(nil, "error", "NPL.compiler", errmsg);
		end
		return ok, errmsg;
	end
end

---------------------
-- compiler: to compile all simply call NPL.CompileFiles("script/*.lua", nil, 10);
---------------------
-- Compile input files to target directory
-- e.g. 
--		NPL.CompileFiles("script/config.lua"); -- print single file
--		NPL.CompileFiles("script/ide/*.lua", nil, 10); -- print all files in directory and sub dirs of script/ide
--		NPL.CompileFiles({"script/ide/*.lua", "script/*.lua"}); -- print only in two parent dir, but not sub directory
-- @param files: a string file path or an array of file strings.
--  file string may contain wild card patterns like script/*.lua, etc. 
-- @param additionalParams: additional parameter. this is usually nil. Alternatively one can also specify 
--		"-p": which only parses the file but does not generate output files. 
--		"-s": to strip debug information.
-- @param searchDepth: if nil, it defaults to 0. otherwise "script/*.lua" will search recursively for *.lua files. 
-- @param targetDir: if nil, it defaults to "bin" folder, hence "script/*.lua" will be compiled to "bin/script/*.o"
function NPL.CompileFiles(files, additionalParams, searchDepth, targetDir)
	local error_count = 0;
	if(type(files) == "string") then
		if(string.find(files, "%*")) then
			local _,_,dir, filepattern = string.find(files, "^(.*/)([^/]+)$")
			if(dir and filepattern) then
				local output = {};
				commonlib.SearchFiles(output, dir, filepattern, searchDepth or 0, 100000, true)
				commonlib.log("NPL.CompileFiles len: %s\n", #output)
				local _, file
				for _, file in ipairs(output) do
					if(string.match(file, "lua$") or string.match(file, "npl$")) then
						error_count = error_count + NPL.CompileFiles(dir..file, additionalParams)
					end
				end
			else
				commonlib.log("warning: unknown file pattern %s in NPL.CompileFiles\n", files)
			end
		else
			local args = "";
			if(additionalParams) then
				args = args..additionalParams.." "
			end
			local output = string.gsub(files, "^(.*)lua$", "bin/%1o");
			output = string.gsub(output, "^(.*)npl$", "bin/%1o");
			if(ParaIO.CreateDirectory(output)) then
				args = string.format("%s -o %s %s", args, output, files)
				commonlib.log("Compiling: %s\n", files)
				local ok, msg = NPL.Compile(args);
				if(ok) then
					commonlib.log("\t\t--> %s\n", output)
				else
					error_count = error_count + 1;
				end
			else
				commonlib.log("warning: unable to create directory at %s \n", output);
			end	
		end
	elseif(type(files) == "table") then
		local _, file
		for _, file in ipairs(files) do
			error_count = error_count + NPL.CompileFiles(file, additionalParams, searchDepth, targetDir)
		end
	end
	return error_count;
end