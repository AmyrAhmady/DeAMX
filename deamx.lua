--[[

	DeAMX, trc_'s .amx -> .pwn decompiler
	  (2008)
	Updated by iAmir (C) 2018

  Licence
	
	You may:
	- Use this program free of charge
	- Modify it
	- Redistribute it with your changes, provided you keep
	  the name of the original author (i.e. don't pretend you
	  made it all by yourself) and this licence, and mention
	  that you changed it (plus eventually what changes you made).
	- Use parts of this program in your own scripts, again
	  provided you mention that you used code from DeAMX and
	  name its author.
	  
	You are not allowed to:
	- Distribute this program, with or without changes, with the
	  name of the author and/or this licence removed, and/or with
	  the claim that you or someone else than the original author
	  made it, because you didn't.
	- Sell this program or a derivation of it.
	
  Disclaimer:

	The author is in no way responsible for what you do with this
	decompiler. You are not allowed to decompile someone else's
	script and re-release it as your own script, unless explicitely
	approved by the script's author.

                                                                ]]--

function include(file)
	assert(loadfile(file))()
end

include('deamx_util.lua')
include('deamx_opcodes.lua')
include('deamx_events.lua')
include('deamx_syscalls.lua')

g_ParamTypeToName = { p = 'playerid', o = 'objectid', v = 'vehicleid'}
g_TypeTags = {
	f = 'Float',
	h = 'File',
	m = 'Menu',
	x = 'Text',
	xp = 'PlayerText',
	d = 'Text3D',
	dp = 'PlayerText3D'
}

sortDescending = function(a, b) return b < a end
function collectNewFrameVars(amx, onlyIfDefined)
	local newFrameVars
	for offset,framevar in pairs(amx.frameVars) do
		if offset < 0 and framevar.new and (not onlyIfDefined or framevar.value) then
			if not newFrameVars then
				newFrameVars = {}
			end
			newFrameVars[#newFrameVars+1] = offset
		end
		framevar.incremented = nil
		framevar.decremented = nil
	end
	if newFrameVars then
		amx.statement = 'new '
		table.sort(newFrameVars, sortDescending)
		local framevar, simpletype
		for i,offset in ipairs(newFrameVars) do
			if i > 1 then
				amx.statement = amx.statement .. ', '
			end
			framevar = amx.frameVars[offset]
			simpletype = framevar.type and (#framevar.type == 1 and framevar.type or framevar.type:sub(1, 1))
			if simpletype and g_TypeTags[simpletype] then
				amx.statement = amx.statement .. g_TypeTags[simpletype] .. ':'
			end
			amx.statement = amx.statement .. framevar[1]
			if framevar.dimensions then
				amx.statement = amx.statement .. dimensionsToString(framevar.dimensions)
			end
			if framevar.value then
				amx.statement = amx.statement .. ' = ' .. framevar.value
			end
			framevar.new = nil
		end
	end
end

function collectRetVal(amx)
	local ret = amx.PRI
	if amx.curPass == 1 then
		if not amx.returnVals[amx.curProcStart] then
			amx.returnVals[amx.curProcStart] = {}
		end
		local retlist = amx.returnVals[amx.curProcStart]
		if ret.globvar then
			retlist[amx.CIP] = { ret.globvar.addr, isglobvar = true }
		elseif ret.outercall then
			retlist[amx.CIP] = { ret.outercall, iscall = true }
		elseif ret.framevar then
			if ret.framevar.stk >= 12 then
				retlist[amx.CIP] = { (ret.framevar.stk-12)/4+1, isargvar = true }
			else
				retlist[amx.CIP] = { ret.framevar.definedat, islocalvar = true }
			end
		end
	elseif type(ret[1]) == 'number' and amx.learnedFunctionPrototypes[amx.curProcStart] and amx.learnedFunctionPrototypes[amx.curProcStart].returntype == 'f' then
		amx.PRI[1] = cell2float(ret[1])
		local ipart, fpart = math.modf(amx.PRI[1])
		if fpart == 0 then
			amx.PRI[1] = tostring(amx.PRI[1]) .. '.0'
		end
	end
end

function removePastOpcodeAddrs(amx)
	while #amx.fnJumps > 0 and amx.CIP > amx.fnJumps[1] do
		table.remove(amx.fnJumps, 1)
	end
	while #amx.fnBreaks > 0 and amx.CIP > amx.fnBreaks[1] do
		table.remove(amx.fnBreaks, 1)
	end
end

function decompileBlock(amx, from, to, indent, catchAllStatements, elseIfAddr)
	--print(('Decompiling from %X to %X'):format(from, to))
	local result = ''
	local indentstr
	if indent then
		amx.indent = indent
		indentstr = ('\t'):rep(indent)
		if not elseIfAddr then
			result = result .. ('\t'):rep(indent-1) .. '{\n'
		end
	else
		indentstr = ''
	end
	
	local stkBkp = amx.STK
	local frameVarsBkp = {}
	for offset,val in pairs(amx.frameVars) do
		if offset < 0 then
			frameVarsBkp[offset] = table.shallowcopy(val)
		end
	end
	
	local g_AMXOpcodes = g_AMXOpcodes
	amx.CIP = from
	local opcode, numArgs
	local args = {}
	while amx.CIP < to do
		removePastOpcodeAddrs(amx)
		opcode = amx.memCOD[amx.CIP]
		--print(('%d %X (%d)'):format(indent or 0, amx.CIP, opcode))
		if opcode == 47 or opcode == 48 or opcode == 137 or catchAllStatements then
			-- ret/retn/break
			collectNewFrameVars(amx, false)
			if opcode == 47 or opcode == 48 then
				collectRetVal(amx)
			end
			table.clear(amx.incrementedGlobalVars)
			table.clear(amx.decrementedGlobalVars)
			if amx.statement and #amx.condnodes == 0 and not ((opcode == 47 or opcode == 48) and amx.PRI[1] ~= 0) then
				result = result .. indentstr .. amx.statement .. (indent and ';\n' or '; ')
			end
			amx.statement = nil
			if (opcode == 47 or opcode == 48) and amx.STK > stkBkp then
				for offset,val in pairs(frameVarsBkp) do
					amx.frameVars[offset] = frameVarsBkp[offset]
				end
				amx.STK = stkBkp
			end
		end
		if opcode == 129 then
			-- switch
			result = result .. indentstr .. 'switch(' .. amx.PRI[1] .. ') {\n'
			local indentstr1 = ('\t'):rep(indent + 1)
			local casetbl = amx.memCOD[amx.CIP+4]+4
			local numCases = amx.memCOD[casetbl]
			local defaultCase = amx.memCOD[casetbl+4]
			local cases = {}
			for i=1,numCases do
				cases[i] = { value = amx.memCOD[casetbl + i*8], addr = amx.memCOD[casetbl + i*8 + 4] }
			end
			table.sort(cases, function(a, b) return a.addr < b.addr end)
			for i,case in ipairs(cases) do
				result = result .. indentstr1 .. 'case ' .. case.value .. ':\n' .. decompileBlock(amx, case.addr, i < numCases and cases[i+1].addr or defaultCase, indent+2, false, true)
			end
			if defaultCase < casetbl + (numCases+1)*8 then
				result = result .. indentstr1 .. 'default:\n' .. decompileBlock(amx, defaultCase, casetbl-4, indent+2, false, true)
			end
			result = result .. indentstr .. '}\n'
		end
		while (opcode == 137 or (amx.forloop and amx.CIP == amx.forloop.loopend or amx.whileloop and amx.CIP == amx.whileloop.loopend)) and amx.CIP < to do
			--print(('%d %X (%d)'):format(indent or 0, amx.CIP, opcode))
			if #amx.condnodes == 0 then
				local loopEnd
				if #amx.fnBreaks >= 2 and #amx.fnJumps >= 2 and amx.fnJumps[1] == amx.fnBreaks[2]-8 and amx.memCOD[amx.fnJumps[1]+4] < amx.fnJumps[2] then
					for i,jmpaddr in ipairs(amx.fnJumps) do
						if amx.memCOD[jmpaddr+4] == amx.fnBreaks[2] then
							loopEnd = jmpaddr + 8
							break
						end
					end
					if loopEnd and isCondOpcode(amx.memCOD[(#amx.fnBreaks >= 3 and amx.fnBreaks[3] < loopEnd and amx.fnBreaks[3] or loopEnd-8)-8]) then
						-- for loop
						--print(('%X Found a for loop'):format(amx.CIP))
						amx.forloop = {}
						amx.forloop.init = decompileBlock(amx, amx.CIP+4, amx.fnBreaks[2]-8, false, true):gsub(';', ',')
						amx.forloop.step = decompileBlock(amx, amx.fnBreaks[1]+4, amx.memCOD[amx.CIP+4], false)
						amx.forloop.loopend = loopEnd
					end
				elseif #amx.fnJumps >= 1 then
					for i,jmpaddr in ipairs(amx.fnJumps) do
						if amx.memCOD[jmpaddr+4] == amx.CIP then
							loopEnd = jmpaddr + 8
							break
						end
					end
					if loopEnd and isCondOpcode(amx.memCOD[(#amx.fnBreaks >= 2 and amx.fnBreaks[2] < loopEnd and amx.fnBreaks[2] or loopEnd-8)-8]) then
						-- while loop
						--print(('%X Found a while loop'):format(amx.CIP))
						amx.whileloop = { loopend = loopEnd }
					end
				end
				break
			else
				amx.statement = nil
				local node = table.remove(amx.condnodes)
				
				if amx.forloop then
					--print(('%X Writing for loop'):format(amx.CIP))
					local forloop = amx.forloop
					amx.forloop = nil
					result = result .. indentstr .. 'for(' .. forloop.init .. '; ' .. node[1] .. '; ' .. forloop.step .. ')\n' .. decompileBlock(amx, amx.CIP, forloop.loopend, indent+1)
				elseif amx.whileloop then
					-- while loop
					--print(('%X Writing while loop'):format(amx.CIP))
					local whileloop = amx.whileloop
					amx.whileloop = nil
					result = result .. indentstr .. 'while(' .. node[1] .. ')\n' .. decompileBlock(amx, amx.CIP, whileloop.loopend, indent+1)
				else
					-- if/else
					if amx.memCOD[node.endpoint-8] == 51 then
						--print('Writing if/else')
						local upcomingBreak = findClosestInstrsAfter(amx, 137, amx.memCOD[node.endpoint] == 137 and node.endpoint+4 or node.endpoint, amx.memCOD[node.endpoint-4], 1)
						local isElseif = #upcomingBreak == 1 and isCondOpcode(amx.memCOD[upcomingBreak[1]-8]) and
							(
								amx.memCOD[upcomingBreak[1]-4] == amx.memCOD[node.endpoint-4]
								or
								(amx.memCOD[amx.memCOD[upcomingBreak[1]-4]-8] == 51 and amx.memCOD[amx.memCOD[upcomingBreak[1]-4]-4] == amx.memCOD[node.endpoint-4])
							)
						result = result .. (elseIfAddr == amx.CIP and ' ' or indentstr) .. 'if(' .. node[1] .. ')\n' .. decompileBlock(amx, amx.CIP+4, node.endpoint-8, indent+1) .. indentstr .. 'else'
						if not isElseif then
							result = result .. '\n'
						end
						result = result .. decompileBlock(amx, node.endpoint, amx.memCOD[node.endpoint-4], isElseif and indent or (indent+1), false, isElseif and upcomingBreak[1])
					else
						--print('Writing if (endpoint = ' .. ('%X'):format(node.endpoint) .. ')')
						result = result .. (elseIfAddr == amx.CIP and ' ' or indentstr) .. 'if(' .. node[1] .. ')\n' .. decompileBlock(amx, amx.CIP+4, node.endpoint, indent+1)
					end
				end
			end
			opcode = amx.memCOD[amx.CIP]
			removePastOpcodeAddrs(amx)
		end
		if amx.CIP < to then
			opcode = amx.memCOD[amx.CIP]
			numArgs = g_AMXOpcodes[opcode][1]
			for i=1,numArgs do
				args[i] = amx.memCOD[amx.CIP + i*4]
			end
			for i=numArgs+1,#args do
				args[i] = nil
			end
			amx.CIP = amx.CIP + 4 + 4*numArgs
			g_AMXOpcodes[opcode][2](amx, unpack(args))
		end
	end
	collectNewFrameVars(amx, true)
	collectRetVal(amx)
	table.clear(amx.incrementedGlobalVars)
	table.clear(amx.decrementedGlobalVars)
	if amx.statement then
		result = result .. indentstr .. amx.statement .. (indent and ';\n' or '')
		amx.statement = nil
	end
	if indent and not elseIfAddr then
		result = result .. ('\t'):rep(indent-1) .. '}\n'
	end
	
	if amx.STK > stkBkp then
		for offset,val in pairs(frameVarsBkp) do
			amx.frameVars[offset] = frameVarsBkp[offset]
		end
		amx.STK = stkBkp
	end
	
	if indent then
		amx.indent = indent - 1
	end
	return result
end

globalVarMT = {
	__index = function(t, k)
		if type(k) ~= 'number' then
			return nil
		end
		t[k] = { ('glob%X'):format(k), addr = k }
		return t[k]
	end
}

frameVarMT = {
	__index = function(t, k)
		if k >= 12 then
			for i=12,k,4 do
				if not rawget(t, i) then
					t[i] = { 'arg' .. ((i-12)/4), stk = i }
					t[i].framevar = t[i]
				end
			end
			return t[k]
		end
	end
}

function listGlobalVars(amx)
	local result = ''
	local sortedGlobalVars = {}
	for addr,glob in pairs(amx.globalVars) do
		table.insert(sortedGlobalVars, { addr = addr, glob = glob })
	end
	table.sort(sortedGlobalVars, function(a, b) return a.addr < b.addr end)
	local addr, glob, name, data
	for i,sortedglob in pairs(sortedGlobalVars) do
		addr, glob = sortedglob.addr, sortedglob.glob
		if not glob.immediate then
			name = (g_TypeTags[glob.type] and (g_TypeTags[glob.type] .. ':') or '') .. glob[1]
			if not glob.dimensions then
				local length = i < #sortedGlobalVars and (sortedGlobalVars[i+1].addr - addr)/4
				if not length or length == 1 then
					data = sgn(amx.memDAT[addr])
					result = result .. 'new ' .. name .. (data == 0 and '' or (' = ' .. data)) .. ';\n\n'
				else
					glob.dimensions = { length }
					result = result .. 'new ' .. name .. '[' .. length .. '];\n\n'
				end
			else
				result = result .. 'new ' .. name .. dimensionsToString(glob.dimensions)
				if isGlobalArrayInitialized(amx, addr, glob.dimensions) then
					result = result .. ' = ' .. dumpGlobalArray(amx, addr, glob.type, glob.dimensions):gsub('\n$', '')
				end
				result = result .. ';\n\n'
			end
		end
	end
	return result
end

function isGlobalArrayInitialized(amx, addr, dimensions, curdim)
	if not curdim then
		curdim = 1
	end
	if curdim < #dimensions then
		for i=0,dimensions[curdim] do
			if isGlobalArrayInitialized(amx, addr + i*4 + amx.memDAT[addr + i*4], dimensions, curdim + 1) then
				return true
			end
		end
	else
		for i=0,(dimensions[curdim] or 0) do
			if amx.memDAT[addr + i*4] ~= 0 then
				return true
			end
		end
	end
	return false
end

function dumpGlobalArray(amx, addr, type, dimensions, curdim, baseindent)
	if not curdim then
		curdim = 1
	end
	local indent = ('\t'):rep((baseindent or 0) + curdim-1)
	local result
	if curdim < #dimensions then
		result = indent .. '{'
		for i=0,dimensions[curdim] do
			if i > 0 then
				result = result:gsub('\n$', '') .. ','
			end
			result = result .. '\n' .. indent .. dumpGlobalArray(amx, addr + i*4 + amx.memDAT[addr + i*4], type, dimensions, curdim + 1)
		end
		return result .. '\n' .. indent .. '}\n'
	elseif type == 's' then
		return '\t"' .. readMemString(amx, addr) .. '"'
	else
		result = indent .. '{ '
		local val
		for i=0,(dimensions[curdim] or 0) do
			if i > 0 then
				result = result .. ', '
			end
			val = amx.memDAT[addr + i*4]
			if type == 'f' then
				val = tostring(cell2float(val))
			else
				val = sgn(val)
			end
			result = result .. val
		end
		return result .. ' }'
	end
end

do
	local amx, opcode, procStart, procEnd
	local outFile, fnName
	local step = step
	for _,file in ipairs(arg) do
		amx = loadAMX(file)
		if amx then
			local funcBody, argList
			local mainOffset = amx.CIP
			local isReplaced
			amx.globalVars = setmetatable({}, globalVarMT)
			amx.incrementedGlobalVars = {}
			amx.decrementedGlobalVars = {}
			amx.condnodes = {}
			amx.learnedFunctionPrototypes = {}		-- { fnAddr = { type, type, ... } }
			amx.learnedFrameVarTypes = {}			-- { definitionAddr = type }
			amx.callVars = {}						-- { call addr = { argNum1 = argSpec, argNum2 = argSpec, ... } }
													--   with argSpec one of: { memAddr, isglobvar = true }
													--                        { definitionAddr, islocalvar = true }
													--                        { argNum, isargvar = true, procaddr = procAddr }
			amx.returnVals = {}						-- { fnAddr = { retAddr1 = retSpec, retAddr2 = retSpec, ... } }
													--   with retSpec like argSpec, plus: { fnAddr, iscall = true }
			outFile = io.open(file:gsub('%.[aA][mM][xX]$', '.pwn'), 'w+')
			for i,include in ipairs({'a_samp', 'core', 'float'}) do
				outFile:write(('#include <%s>\n'):format(include))
			end
			outFile:write('\n')
			
			for pass=1,2 do
				amx.curPass = pass
				procStart = 8
				procEnd = procStart + 4
				while procEnd < amx.sizeCOD do
					procEnd = procStart + 4
					opcode = amx.memCOD[procEnd]
					while procEnd < amx.sizeCOD and opcode ~= 46 do
						procEnd = step(amx, procEnd, opcode)
						opcode = amx.memCOD[procEnd]
					end
					isReplaced = false
					for fn,replacer in pairs(g_FunctionReplace) do
						if fn.addr == procStart then
							isReplaced = true
							break
						end
					end
					if not isReplaced then
						fnName = amx.publics[procStart]
						if not fnName then
							if procStart == mainOffset then
								fnName = 'main'
							else
								fnName = ('function%X'):format(procStart)
							end
						end
						amx.frameVars = setmetatable({}, frameVarMT)
						amx.heapVars = {}
						argList = g_SAMPEventParamNames[fnName]
						if not argList and amx.learnedFunctionPrototypes[procStart] then
							argList = {}
							local name
							local nameUsageNum = {}
							for i,type in pairs(amx.learnedFunctionPrototypes[procStart]) do
								name = g_ParamTypeToName[type]
								if name then
									if nameUsageNum[name] then
										nameUsageNum[name] = nameUsageNum[name] + 1
										name = name .. nameUsageNum[name]
									else
										nameUsageNum[name] = 1
									end
									argList[i] = name
								end
							end
						end
						if argList then
							local stk
							for i,argname in pairs(argList) do
								if type(i) == 'number' then
									stk = 12 + (i-1)*4
									if(string.find(argname, "Text:") ~= nil) then argname = string.gsub(argname,"Text:","") end
									if(string.find(argname, "Playertext:") ~= nil) then argname = string.gsub(argname,"PlayerText:","") end
									if(string.find(argname, "Float:") ~= nil) then argname = string.gsub(argname,"Float:","") end
									if(string.find(argname, "%[%]") ~= nil) then argname = string.gsub(argname,"%[%]","") end
									if(string.find(argname, "Menu:") ~= nil) then argname = string.gsub(argname,"Menu:","") end
									if(string.find(argname, "File:") ~= nil) then argname = string.gsub(argname,"File:","") end
									amx.frameVars[stk] = { argname, stk = stk }
								end
							end
						end
						
						amx.STK = 0
						amx.HEA = 0
						amx.fnJumps, amx.fnBreaks = getOpcodeAddrs(amx, procStart, procEnd, 51, 137)
						amx.curProcStart = procStart
						funcBody = decompileBlock(amx, procStart+4, procEnd, 1)
						
						if pass == 2 then
							if not argList then
								argList = {}
							end
							if not g_SAMPEventParamNames[fnName] then
								local i = 1
								local framevar, framevarType
								while true do
									framevar = rawget(amx.frameVars, 12 + (i-1)*4)
									if not framevar then
										break
									end
									if not argList[i] then
										argList[i] = framevar[1]
									end
									framevarType = amx.learnedFunctionPrototypes[procStart] and amx.learnedFunctionPrototypes[procStart][i]
									if framevarType and g_TypeTags[(#framevarType > 1 and framevarType:sub(1, 1) or framevarType)] then
										argList[i] = g_TypeTags[(#framevarType > 1 and framevarType:sub(1, 1) or framevarType)] .. ':' .. argList[i]
									end
									if framevar.ref then
										argList[i] = '&' .. argList[i]
									end
									if framevar.dimensions or framevar.type == 's' then
										argList[i] = argList[i] .. ('[]'):rep(not framevar.dimensions and 1 or #framevar.dimensions)
									end
									i = i + 1
								end
							end
							if amx.learnedFunctionPrototypes[procStart] and amx.learnedFunctionPrototypes[procStart].returntype and g_TypeTags[amx.learnedFunctionPrototypes[procStart].returntype] then
								fnName = fnName
							end
							if amx.publics[procStart] then
								fnName = 'public ' .. fnName
							end
						
							outFile:write(fnName .. '(' .. table.concat(argList, ', ') .. ')\n' .. funcBody .. '\n')
						end
					end
					procStart = procEnd
				end
				if pass == 1 then
					local syscallName
					local prototype
					local newTypeInfoFound
					local scanNum = 1
					repeat
						newTypeInfoFound = false
						for callAddr,argInfo in pairs(amx.callVars) do
							if amx.memCOD[callAddr] == 123 then
								syscallName = amx.natives[amx.memCOD[callAddr+4]]
								prototype = g_SAMPSyscallPrototypes[syscallName]
							else
								prototype = amx.learnedFunctionPrototypes[amx.memCOD[callAddr+4]]
							end
							if prototype then
								--print(('Prototype found for call at %X'):format(callAddr))
								for argNum,argSpec in pairs(argInfo) do
									if argSpec.isglobvar then
										local globvar = amx.globalVars[argSpec[1]]
										if not globvar.type then
											local globtype = prototype[argNum] or 's'
											if globtype == 's' and globvar.dimensions then
												local addr = zeroIndexToDimension(amx, globvar.addr, #globvar.dimensions)
												if not readMemString(amx, addr) then
													if not amx.memDAT[addr] or not readMemString(amx, addr+amx.memDAT[addr]) then
														globtype = 'i'
													else
														table.insert(globvar.dimensions, 0)
													end
												end
											end
											globvar.type = globtype
											--print(('Globvar at %X is now of type %s'):format(argSpec[1], globtype))
											newTypeInfoFound = true
										end
									elseif argSpec.islocalvar then
										if not amx.learnedFrameVarTypes[argSpec[1]] then
											amx.learnedFrameVarTypes[argSpec[1]] = prototype[argNum]
											--print(('Framevar defined at %X is now of type %s'):format(argSpec[1], prototype[argNum]))
											newTypeInfoFound = true
										end
									elseif argSpec.isargvar then
										if not amx.learnedFunctionPrototypes[argSpec.procaddr] then
											amx.learnedFunctionPrototypes[argSpec.procaddr] = {}
										end
										if not amx.learnedFunctionPrototypes[argSpec.procaddr][argSpec[1]] then
											amx.learnedFunctionPrototypes[argSpec.procaddr][argSpec[1]] = prototype[argNum]
											--print(('Arg %d of function %X is now of type %s'):format(argSpec[1], argSpec.procaddr, prototype[argNum]))
											newTypeInfoFound = true
										end
									end
								end
							--else
								--print(('No prototype for call at %X'):format(callAddr))
							end
						end
						for fnAddr,returns in pairs(amx.returnVals) do
							if not amx.learnedFunctionPrototypes[fnAddr] then
								amx.learnedFunctionPrototypes[fnAddr] = {}
							end
							if not amx.learnedFunctionPrototypes[fnAddr].returntype then
								for retAddr,retSpec in pairs(returns) do
									if retSpec.isglobvar then
										local globvar = amx.globalVars[retSpec[1]]
										if globvar.type then
											amx.learnedFunctionPrototypes[fnAddr].returntype = globvar.type
											newTypeInfoFound = true
										end
									elseif retSpec.islocalvar then
										if amx.learnedFrameVarTypes[retSpec[1]] then
											amx.learnedFunctionPrototypes[fnAddr].returntype = amx.learnedFrameVarTypes[retSpec[1]]
											newTypeInfoFound = true
										end
									elseif retSpec.isargvar then
										if amx.learnedFunctionPrototypes[fnAddr][retSpec[1]] then
											amx.learnedFunctionPrototypes[fnAddr].returntype = amx.learnedFunctionPrototypes[fnAddr][retSpec[1]]
											newTypeInfoFound = true
										end
									elseif retSpec.iscall then
										if type(retSpec[1]) == 'number' then
											prototype = amx.learnedFunctionPrototypes[retSpec[1]]
										else
											prototype = g_SAMPSyscallPrototypes[retSpec[1]]
										end
										if prototype and prototype.returntype then
											amx.learnedFunctionPrototypes[fnAddr].returntype = prototype.returntype
											newTypeInfoFound = true
										end
									end
								end
							end
						end
						scanNum = scanNum + 1
					until not newTypeInfoFound or scanNum == 20
				
					outFile:write(listGlobalVars(amx) .. '\n')
				end
			end
			outFile:close()
		end
	end
end
