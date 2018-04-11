function push(amx, ...)
	local varID = 0
	for offset,val in pairs(amx.frameVars) do
		if offset < 0 then
			varID = varID + 1
		end
	end
	local framevar
	for i,num in ipairs({...}) do
		amx.STK = amx.STK - 4
		framevar = type(num) == 'number' and { num } or table.shallowcopy(num)
		framevar.stk = amx.STK
		framevar.new = true
		framevar.value = framevar[1]
		--print('New frame var at ' .. amx.STK .. ', value ' .. tostring(framevar.value))
		framevar[1] = 'var' .. varID
		if not framevar.framevar then
			framevar.framevar = framevar
		end
		if amx.learnedFrameVarTypes[amx.CIP] then
			framevar.type = amx.learnedFrameVarTypes[amx.CIP]
			if framevar.type:sub(1, 1) == 'f' and type(framevar.value) == 'number' then
				framevar.value = cell2float(framevar.value)
				local ipart, fpart = math.modf(framevar.value)
				if fpart == 0 then
					framevar.value = tostring(framevar.value) .. '.0'
				end
			end
		end
		framevar.definedat = amx.CIP
		amx.frameVars[amx.STK] = framevar
		varID = varID + 1
	end
	return varID - 1
end

function pushMem(amx, ...)
	local framevar
	for i,mem in ipairs({...}) do
		push(amx, amx.globalVars[mem])
		amx.frameVars[amx.STK].globvar = amx.globalVars[mem]
	end
end

function pushFrameVar(amx, ...)
	for i,offset in ipairs({...}) do
		push(amx, amx.frameVars[sgn(offset)])
	end
end

function pushAddr(amx, ...)
	for i,offset in ipairs({...}) do
		push(amx, amx.frameVars[sgn(offset)])
		amx.frameVars[amx.STK].addr = true
	end
end

function pop(amx)
	local framevar = amx.frameVars[amx.STK]
	amx.frameVars[amx.STK] = nil
	amx.STK = amx.STK + 4
	framevar[1] = framevar.value
	framevar.value = nil
	--print('Popped ' .. tostring(framevar[1]))
	return framevar
end

local g_InverseComparisons = {
	[false] = '!',
	['!']  = false,
	['=='] = '!=',
	['!='] = '==',
	['<']  = '>=',
	['>='] = '<',
	['>']  = '<=',
	['<='] = '>'
}

function createTernaryOperator(amx, jmpaddr, condnode)
	--print('Found a ternary operator')
	decompileBlock(amx, amx.CIP, jmpaddr-8, false)
	local truePart = amx.PRI[1]
	decompileBlock(amx, jmpaddr, amx.memCOD[jmpaddr-4], false)
	local falsePart = amx.PRI[1]
	amx.PRI[1] = '(' .. condnode[1] .. ' ? ' .. truePart .. ' : ' .. falsePart .. ')'
end

function applyCondition(amx, jmpaddr, comparison)
	local isTernaryOp = false
	if isCondOpcode(amx.memCOD[amx.CIP-8]) and amx.memCOD[amx.CIP] ~= 137 and amx.memCOD[jmpaddr] ~= 137 and amx.memCOD[jmpaddr-8] == 51 then
		local checkEnd = amx.memCOD[jmpaddr-4]
		isTernaryOp = not ((amx.memCOD[jmpaddr] == 89 and amx.memCOD[jmpaddr-16] == 11 and amx.memCOD[jmpaddr-12] == 1) or (amx.memCOD[jmpaddr] == 11 and amx.memCOD[jmpaddr+4] == 1 and amx.memCOD[jmpaddr-12] == 89))
			--(amx.memCOD[jmpaddr] ~= 89 and (amx.memCOD[jmpaddr] ~= 11 or amx.memCOD[jmpaddr+4] ~= 1) and amx.memCOD[jmpaddr-4] ~= 89 and (amx.memCOD[jmpaddr-8] ~= 11 or amx.memCOD[)
	end
	if amx.memCOD[amx.CIP-8] == 53 or amx.memCOD[amx.CIP-8] == 54 then
		local node
		local newNode
		local operator
		if amx.memCOD[amx.CIP-12] == 89 then
			operator = ' && '
		elseif amx.memCOD[amx.CIP-16] == 11 and amx.memCOD[amx.CIP-12] == 1 then
			operator = ' || '
		end
		local i = 1
		while i <= #amx.condnodes do
			node = amx.condnodes[i]
			if node.endpoint == amx.CIP-8 then
				if not newNode then
					newNode = { '' }
				end
				if #newNode[1] > 0 then
					newNode[1] = newNode[1] .. operator
				end
				newNode[1] = newNode[1] .. (node.leaf and node[1] or ('(' .. node[1] .. ')'))
				table.remove(amx.condnodes, i)
			else
				i = i + 1
			end
		end
		if newNode then
			if amx.memCOD[jmpaddr] == 89 then
				newNode.endpoint = jmpaddr + 4
			elseif amx.memCOD[jmpaddr] == 11 and amx.memCOD[jmpaddr+4] == 1 then
				newNode.endpoint = jmpaddr + 8
			else
				newNode.endpoint = jmpaddr
			end
			if isTernaryOp then
				createTernaryOperator(amx, jmpaddr, newNode)
			else
				table.insert(amx.condnodes, newNode)
			end
			return
		end
	end
	
	local newNode = { leaf = true }
	if amx.memCOD[amx.CIP] ~= 137 and amx.memCOD[amx.CIP] ~= 51 then
		if isTernaryOp then
			comparison = g_InverseComparisons[comparison]
		elseif amx.memCOD[jmpaddr] == 89 then
			-- &&
			comparison = g_InverseComparisons[comparison]
			newNode.endpoint = jmpaddr + 4
		elseif amx.memCOD[jmpaddr] == 11 and amx.memCOD[jmpaddr+4] == 1 then
			-- ||
			newNode.endpoint = jmpaddr + 8
		end
	else
		newNode.endpoint = jmpaddr
		comparison = g_InverseComparisons[comparison]
	end
	if not comparison then
		newNode[1] = amx.PRI[1]
	elseif comparison == '!' then
		newNode[1] = amx.PRI.outerop and ('!(' .. amx.PRI[1] .. ')') or ('!' .. amx.PRI[1])
	elseif comparison == '==' or comparison == '!=' then
		newNode[1] = amx.ALT[1] .. ' ' .. comparison .. ' ' .. amx.PRI[1]
	else
		newNode[1] = amx.PRI[1] .. ' ' .. comparison .. ' ' .. amx.ALT[1]
	end
	if isTernaryOp then
		createTernaryOperator(amx, jmpaddr, newNode)
	else
		table.insert(amx.condnodes, newNode)
	end
end

function isCondOpcode(opcode)
	return opcode >= 53 and opcode <= 64
end

function applyCalcOp(amx, op, one, two, out)
	if one == nil then
		one = amx.PRI
	end
	local oneText
	if type(one) == 'table' then
		if one.outerop and not (op == '*' and one.outerop == '*') and not (op == '+' and one.outerop == '+') then
			oneText = '(' .. one[1] .. ')'
		else
			oneText = one[1]
		end
	else
		oneText = one
	end
	
	if two == nil then
		two = amx.ALT
	end
	local twoText
	if two then
		if type(two) == 'table' then
			if two.outerop and not (op == '*' and two.outerop == '*') and not (op == '+' and two.outerop == '+') then
				twoText = '(' .. two[1] .. ')'
			else
				twoText = two[1]
			end
		elseif type(two) == 'number' then
			twoText = sgn(two)
			if twoText < 0 then
				if op == '+' then
					twoText = -twoText
					op = '-'
				elseif op == '-' then
					twoText = -twoText
					op = '+'
				else
					twoText = '(' .. twoText .. ')'
				end
			end
		else
			twoText = two
		end
	end
	if type(one) == 'table' then
		out = out or one
		if twoText then
			out[1] = oneText .. ' ' .. op .. ' ' .. twoText
		else
			out[1] = op .. oneText
			if amx then
				amx.statement = oneText .. op
			end
		end
		out.outerop = op
	end
	return out
end

function dereference(var)
	if type(var[1]) == 'number' then
		var.globvar = amx.globalVars[var[1]]
		var[1] = var.globvar[1]
		if not var.index and not var.globvar.dimensions then
			var.dim = (var.dim or 0) + 1
			return
		end
	end
	if not var.index then
		var.index = 0
	end
	var.dim = (var.dim or 0) + 1
	if var.index ~= 0 or (var.framevar and var.framevar.dimensions and var.dim <= #var.framevar.dimensions) or
	  (var.globvar and var.globvar.dimensions and (var.dim <= #var.globvar.dimensions or amx.memDAT[zeroIndexToDimension(amx, var.globvar.addr, var.dim-1)] == 4*((var.globvar.dimensions[var.dim-1] or 0)+1))) then
		var[1] = (var.value or var[1]) .. '[' .. var.index .. ']'
		if var.globvar then
			if not var.globvar.dimensions then
				var.globvar.dimensions = {}
			end
			if var.bound then
				var.globvar.dimensions[var.dim] = var.bound
			elseif type(var.index) == 'number' and (not var.globvar.dimensions[var.dim] or var.index > var.globvar.dimensions[var.dim]) then
				var.globvar.dimensions[var.dim] = var.index
			end
		end
	end
	var.index = nil
	var.bound = nil
	var.addr = nil
	return var
end

g_AMXOpcodes = {
	--   1 LOAD.pri
	{ 1,
		function(amx, addr)
			amx.PRI = table.shallowcopy(amx.globalVars[addr])
			amx.PRI.globvar = amx.globalVars[addr]
			local i = table.find(amx.incrementedGlobalVars, amx.PRI.globvar)
			if i then
				amx.PRI[1] = '++' .. amx.PRI[1]
				table.remove(amx.incrementedGlobalVars, i)
			else
				i = table.find(amx.decrementedGlobalVars, amx.PRI.globvar)
				if i then
					amx.PRI[1] = '--' .. amx.PRI[1]
					table.remove(amx.decrementedGlobalVars, i)
				end
			end
		end
	},
	--   2 LOAD.alt
	{ 1,
		function(amx, addr)
			amx.ALT = table.shallowcopy(amx.globalVars[addr])
			amx.ALT.globvar = amx.globalVars[addr]
			local i = table.find(amx.incrementedGlobalVars, amx.ALT.globvar)
			if i then
				amx.ALT[1] = '++' .. amx.ALT[1]
				table.remove(amx.incrementedGlobalVars, i)
			else
				i = table.find(amx.decrementedGlobalVars, amx.ALT.globvar)
				if i then
					amx.ALT[1] = '--' .. amx.ALT[1]
					table.remove(amx.decrementedGlobalVars, i)
				end
			end
		end
	},
	--   3 LOAD.S.pri
	{ 1,
		function(amx, offset)
			amx.PRI = table.shallowcopy(amx.frameVars[sgn(offset)])
			if amx.PRI.incremented then
				-- pre-increment
				amx.PRI[1] = '++' .. amx.PRI[1]
				amx.PRI.incremented = nil
			elseif amx.PRI.decremented then
				-- pre-decrement
				amx.PRI[1] = '--' .. amx.PRI[1]
				amx.PRI.decremented = nil
			end
		end
	},
	--   4 LOAD.S.alt
	{ 1,
		function(amx, offset)
			amx.ALT = table.shallowcopy(amx.frameVars[sgn(offset)])
			if amx.ALT.incremented then
				-- pre-increment
				amx.ALT[1] = '++' .. amx.ALT[1]
				amx.ALT.incremented = nil
			elseif amx.ALT.decremented then
				-- pre-decrement
				amx.ALT[1] = '--' .. amx.ALT[1]
				amx.ALT.decremented = nil
			end
		end
	},
	--   5 LREF.pri
	{ 1, function(amx, addr) amx.PRI = { amx.globalVars[addr][1] } end },
	--   6 LREF.alt
	{ 1, function(amx, addr) amx.ALT = { amx.globalVars[addr][1] } end },
	--   7 LREF.S.pri
	{ 1,
		function(amx, offset)
			amx.frameVars[sgn(offset)].ref = true
			g_AMXOpcodes[3][2](amx, offset)
		end
	},
	--   8 LREF.S.alt
	{ 1,
		function(amx, offset)
			amx.frameVars[sgn(offset)].ref = true
			g_AMXOpcodes[4][2](amx, offset)
		end
	},
	--   9 LOAD.I
	{ 0,
		function(amx)
			dereference(amx.PRI)
		end
	},
	--  10 LODB.I
	{ 1,
		function(amx, size)
			
		end
	},
	--  11 CONST.pri
	{ 1, function(amx, val) amx.PRI = { sgn(val) } end },
	--  12 CONST.alt
	{ 1, function(amx, val) amx.ALT = { sgn(val) } end },
	--  13 ADDR.pri
	{ 1,
		function(amx, offset)
			offset = sgn(offset)
			amx.PRI = { amx.frameVars[offset][1], framevar = amx.frameVars[offset], globvar = amx.frameVars[offset].globvar, addr = true }
		end
	},
	--  14 ADDR.alt
	{ 1,
		function(amx, offset)
			offset = sgn(offset)
			amx.ALT = { amx.frameVars[offset][1], framevar = amx.frameVars[offset], globvar = amx.frameVars[offset].globvar, addr = true }
		end
	},
	--  15 STOR.pri
	{ 1,
		function(amx, addr)
			amx.PRI[1] = amx.globalVars[addr][1] .. ' = ' .. amx.PRI[1]
			amx.PRI.type = amx.globalVars[addr].type
			amx.statement = amx.PRI[1]
		end
	},
	--  16 STOR.alt
	{ 1,
		function(amx, addr)
			amx.ALT[1] = amx.globalVars[addr][1] .. ' = ' .. amx.ALT[1]
			amx.ALT.type = amx.globalVars[addr].type
			amx.statement = amx.ALT[1]
		end
	},
	--  17 STOR.S.pri
	{ 1,
		function(amx, offset)
			offset = sgn(offset)
			if (amx.PRI.outerop == '++' or amx.PRI.outerop == '--') and amx.PRI[1]:sub(3) == amx.frameVars[offset][1] then
				amx.frameVars[offset][amx.PRI.outerop == '++' and 'incremented' or 'decremented'] = true
				amx.statement = amx.frameVars[offset][1] .. amx.PRI.outerop
				amx.PRI[1] = amx.statement
			elseif amx.frameVars[offset].new then
				amx.frameVars[offset].value = amx.PRI[1]
			else
				amx.PRI[1] = amx.frameVars[offset][1] .. ' = ' .. amx.PRI[1]
				amx.statement = amx.PRI[1]
			end
			if amx.PRI.type then
				amx.frameVars[offset].type = amx.PRI.type
				if amx.frameVars[offset].definedat then
					amx.learnedFrameVarTypes[amx.frameVars[offset].definedat] = amx.PRI.type
				end
			end
		end
	},
	--  18 STOR.S.alt
	{ 1,
		function(amx, offset)
			offset = sgn(offset)
			if (amx.ALT.outerop == '++' or amx.ALT.outerop == '--') and amx.ALT[1]:sub(3) == amx.frameVars[offset][1] then
				amx.statement = amx.frameVars[offset][1] .. amx.ALT.outerop
			elseif amx.frameVars[offset].new then
				amx.frameVars[offset].value = amx.ALT[1]
			else
				amx.ALT[1] = amx.frameVars[offset][1] .. ' = ' .. amx.ALT[1]
				amx.statement = amx.ALT[1]
			end
			if amx.ALT.type then
				amx.frameVars[offset].type = amx.ALT.type
				amx.learnedFrameVarTypes[amx.frameVars[offset].definedat] = amx.ALT.type
			end
		end
	},
	--  19 SREF.pri
	{ 1,
		function(amx, addr)
			amx.statement = amx.globalVars[addr][1] .. ' = ' .. amx.PRI[1]
			if amx.PRI.type then
				amx.globalVars[addr].type = amx.PRI.type
			end
		end 
	},
	--  20 SREF.alt
	{ 1,
		function(amx, addr)
			amx.statement = amx.globalVars[addr][1] .. ' = ' .. amx.ALT[1]
			if amx.ALT.type then
				amx.globalVars[addr].type = amx.ALT.type
			end
		end
	},
	--  21 SREF.S.pri
	{ 1,
		function(amx, offset)
			amx.frameVars[sgn(offset)].ref = true
			g_AMXOpcodes[17][2](amx, offset)
		end
	},
	--  22 SREF.S.alt
	{ 1,
		function(amx, offset)
			amx.frameVars[sgn(offset)].ref = true
			g_AMXOpcodes[18][2](amx, offset)
		end
	},
	--  23 STOR.I
	{ 0,
		function(amx)
			if amx.ALT.hea then
				amx.heapVars[amx.ALT.hea] = table.shallowcopy(amx.PRI)
			elseif amx.ALT.addr or (type(amx.ALT[1]) == 'number' and amx.globalVars[amx.ALT[1]].dimensions) then
				dereference(amx.ALT)
				amx.statement = amx.ALT[1] .. ' = ' .. amx.PRI[1]
				if amx.PRI.type and type(amx.ALT[1]) == 'number' then
					amx.globalVars[amx.ALT[1]].type = amx.PRI.type
				end
				amx.PRI[1] = amx.statement
			elseif type(amx.ALT[1]) == 'number' then
				amx.statement = amx.globalVars[amx.ALT[1]][1] .. ' = ' .. amx.PRI[1]
				amx.PRI[1] = amx.statement
			else
				amx.statement = amx.ALT[1] .. ' = ' .. amx.PRI[1]
				amx.PRI[1] = amx.statement
			end
		end
	},
	--  24 STRB.I
	{ 1, false },
	--  25 LIDX
	{ 0,
		function(amx)
			local bound, index = amx.PRI.bound, amx.PRI[1]
			amx.PRI = table.shallowcopy(amx.ALT)
			amx.PRI.bound, amx.PRI.index = bound, index
			dereference(amx.PRI)
		end
	},
	--  26 LIDX.B
	{ 1, function(amx, shift) end },
	--  27 IDXADDR
	{ 0,
		function(amx)
			local bound, index = amx.PRI.bound, amx.PRI[1]
			amx.PRI = table.shallowcopy(amx.ALT)
			amx.PRI.bound, amx.PRI.index = bound, index
			amx.PRI.addr = true
		end
	},
	--  28 IDXADDR.B
	{ 1, function(amx, shift) end },
	--  29 ALIGN.pri
	{ 1, function(amx, num) end },
	--  30 ALIGN.alt
	{ 1, function(amx, num) end },
	--  31 LCTRL
	{ 1, function(amx, index) end },
	--  32 SCTRL
	{ 1, function(amx, index) end },
	--  33 MOVE.pri
	{ 0, function(amx) amx.PRI = table.shallowcopy(amx.ALT) end },
	--  34 MOVE.alt
	{ 0,
		function(amx)
			if amx.memCOD[amx.CIP] == 9 and amx.memCOD[amx.CIP+4] == 78 then
				dereference(amx.PRI)
				amx.PRI.addr = true
				amx.CIP = amx.CIP + 8
			else
				amx.ALT = table.shallowcopy(amx.PRI)
			end
		end
	},
	--  35 XCHG
	{ 0,
		function(amx)
			local temp = amx.PRI
			amx.PRI = amx.ALT
			amx.ALT = temp
		end
	},
	--  36 PUSH.pri
	{ 0, function(amx) push(amx, amx.PRI) end },
	--  37 PUSH.alt
	{ 0, function(amx) push(amx, amx.ALT) end },
	--  38 PUSH.R
	false,		-- obsolete
	--  39 PUSH.C
	{ 1, push },
	--  40 PUSH
	{ 1, pushMem },
	--  41 PUSH.S
	{ 1, pushFrameVar },
	--  42 POP.pri
	{ 0,
		function(amx)
			amx.PRI = pop(amx)
			if amx.PRI.framevar then
				if amx.PRI.framevar.incremented then
					amx.PRI[1] = amx.PRI[1] .. '++'
					amx.PRI.framevar.incremented = nil
				elseif amx.PRI.framevar.decremented then
					amx.PRI[1] = amx.PRI[1] .. '--'
					amx.PRI.framevar.decremented = nil
				end
			elseif amx.PRI.globvar then
				local i = table.find(amx.incrementedGlobalVars, amx.PRI.globvar)
				if i then
					amx.PRI[1] = amx.PRI[1] .. '++'
					table.remove(amx.incrementedGlobalVars, i)
				else
					i = table.find(amx.decrementedGlobalVars, amx.PRI.globvar)
					if i then
						amx.PRI[1] = amx.PRI[1] .. '--'
						table.remove(amx.decrementedGlobalVars, i)
					end
				end
			end
		end
	},
	--  43 POP.alt
	{ 0,
		function(amx)
			amx.ALT = pop(amx)
			if amx.ALT.framevar then
				if amx.ALT.framevar.incremented then
					amx.ALT[1] = amx.ALT[1] .. '++'
					amx.ALT.framevar.incremented = nil
				elseif amx.ALT.framevar.decremented then
					amx.ALT[1] = amx.ALT[1] .. '--'
					amx.ALT.framevar.decremented = nil
				end
			elseif amx.ALT.globvar then
				local i = table.find(amx.incrementedGlobalVars, amx.ALT.globvar)
				if i then
					amx.ALT[1] = amx.ALT[1] .. '++'
					table.remove(amx.incrementedGlobalVars, i)
				else
					i = table.find(amx.decrementedGlobalVars, amx.ALT.globvar)
					if i then
						amx.ALT[1] = amx.ALT[1] .. '--'
						table.remove(amx.decrementedGlobalVars, i)
					end
				end
			end
		end
	},
	--  44 STACK
	{ 1,
		function(amx, dist)
			dist = sgn(dist)
			amx.ALT = { amx.STK }
			amx.STK = amx.STK + dist
			if dist < 0 then
				-- local var allocation
				local varID = 0
				for offset,val in pairs(amx.frameVars) do
					if offset < 0 then
						varID = varID + 1
					end
				end
				local framevar
				framevar = { 'var' .. varID, new = true }
				if dist < -4 then
					framevar.dimensions = { -dist/4 - 1 }
				end
				framevar.framevar = framevar
				if amx.learnedFrameVarTypes[amx.CIP] then
					framevar.type = amx.learnedFrameVarTypes[amx.CIP]
				else
					framevar.definedat = amx.CIP
				end
				framevar.stk = amx.STK
				amx.frameVars[amx.STK] = framevar
				--print('New local var ' .. varID .. ' at STK ' .. amx.STK)
			else
				-- local var destruction
				for offset,val in pairs(amx.frameVars) do
					if offset < amx.STK then
						amx.frameVars[offset] = nil
						--print('Var at STK ' .. offset .. ' deleted')
					end
				end
			end
		end
	},
	--  45 HEAP
	{ 1,
		function(amx, dist)
			dist = sgn(dist)
			if dist > 0 then
				-- heap var allocation
				amx.heapVars[amx.HEA] = { hea = amx.HEA }
				amx.ALT = table.shallowcopy(amx.heapVars[amx.HEA])
				amx.HEA = amx.HEA + dist
				--print('New heap var at ' .. amx.ALT.hea .. ', HEA is now ' .. amx.HEA)
			else
				-- heap var destruction
				amx.HEA = amx.HEA + dist
				for offset,var in pairs(amx.heapVars) do
					if offset >= amx.HEA then
						amx.heapVars[amx.HEA] = nil
						--print('Destroyed heap var at ' .. offset)
					end
				end
			end
		end
	},
	--  46 PROC
	{ 0, function(amx) end },
	--  47 RET
	{ 0, function(amx) amx.statement = 'return ' .. amx.PRI[1] end },
	--  48 RETN
	{ 0, function(amx) amx.statement = 'return ' .. amx.PRI[1] end },
	--  49 CALL
	{ 1,
		function(amx, addr)
			local replaceFn
			for fn,replacer in pairs(g_FunctionReplace) do
				if not fn.addr then
					if fn.syscalls then
						for offset,svcname in pairs(fn.syscalls) do
							fn.body[offset] = table.find0(amx.natives, svcname)
						end
						fn.syscalls = nil
					end
					local different = false
					for i,dword in pairs(fn.body) do
						if dword ~= amx.memCOD[addr+i*4] then
							different = true
							break
						end
					end
					if not different then
						fn.addr = addr
					end
				end
				if fn.addr == addr then
					replaceFn = replacer
					break
				end
			end
			local fnName = amx.publics[addr] or ('function%X'):format(addr)
			local numArgs = createFunctionCall(amx, fnName, amx.learnedFunctionPrototypes[addr], replaceFn)
			g_AMXOpcodes[44][2](amx, (numArgs + 1)*4)
		end
	},
	--  50 CALL.pri
	{ 0, function(amx) end },
	--  51 JUMP
	{ 1, function(amx, addr) end },
	--  52 JREL
	{ 1, function(amx, offset) end },
	--  53 JZER
	{ 1, function(amx, addr) applyCondition(amx, addr, '!') end },
	--  54 JNZ
	{ 1, function(amx, addr) applyCondition(amx, addr, false) end },
	--  55 JEQ
	{ 1, function(amx, addr) applyCondition(amx, addr, '==') end },
	--  56 JNEQ
	{ 1, function(amx, addr) applyCondition(amx, addr, '!=') end },
	--  57 JLESS
	{ 1, function(amx, addr) applyCondition(amx, addr, '<') end },
	--  58 JLEQ
	{ 1, function(amx, addr) applyCondition(amx, addr, '<=') end },
	--  59 JGRTR
	{ 1, function(amx, addr) applyCondition(amx, addr, '>') end },
	--  60 JGEQ
	{ 1, function(amx, addr) applyCondition(amx, addr, '>=') end },
	--  61 JSLESS
	{ 1, function(amx, addr) applyCondition(amx, addr, '<') end },
	--  62 JSLEQ
	{ 1, function(amx, addr) applyCondition(amx, addr, '<=') end },
	--  63 JSGRTR
	{ 1, function(amx, addr) applyCondition(amx, addr, '>') end },
	--  64 JSGEQ
	{ 1, function(amx, addr) applyCondition(amx, addr, '>=') end },
	--  65 SHL
	{ 0, function(amx) applyCalcOp(amx, '<<') end },
	--  66 SHR
	{ 0, function(amx) applyCalcOp(amx, '>>') end },
	--  67 SSHR
	{ 0, function(amx) applyCalcOp(amx, '>>>') end },
	--  68 SHL.C.pri
	{ 1, function(amx, shift) applyCalcOp(amx, '<<', amx.PRI, shift) end },
	--  69 SHL.C.alt
	{ 1, function(amx, shift) applyCalcOp(amx, '<<', amx.ALT, shift) end },
	--  70 SHR.C.pri
	{ 1, function(amx, shift) applyCalcOp(amx, '>>', amx.PRI, shift) end },
	--  71 SHR.C.alt
	{ 1, function(amx, shift) applyCalcOp(amx, '>>', amx.ALT, shift) end },
	--  72 SMUL
	{ 0, function(amx) applyCalcOp(amx, '*', amx.ALT, amx.PRI, amx.PRI) end },
	--  73 SDIV
	{ 0, function(amx)
			local pri = table.shallowcopy(amx.PRI)
			applyCalcOp(amx, '/')
			applyCalcOp(amx, '%', pri, amx.ALT, amx.ALT)
		end
	},
	--  74 SDIV.alt
	{ 0,
		function(amx)
			local pri = table.shallowcopy(amx.PRI)
			applyCalcOp(amx, '/', amx.ALT, amx.PRI, amx.PRI)
			applyCalcOp(amx, '%', amx.ALT, pri)
		end
	},
	--  75 UMUL
	{ 0, function(amx) applyCalcOp(amx, '*', amx.ALT, amx.PRI, amx.PRI) end },
	--  76 UDIV
	{ 0,
		function(amx)
			local pri = table.shallowcopy(amx.PRI)
			applyCalcOp(amx, '/')
			applyCalcOp(amx, '%', pri, amx.ALT, amx.ALT)
		end
	},
	--  77 UDIV.alt
	{ 0,
		function(amx)
			local pri = table.shallowcopy(amx.PRI)
			applyCalcOp(amx, '/', amx.ALT, amx.PRI, amx.PRI)
			applyCalcOp(amx, '%', amx.ALT, pri)
		end
	},
	--  78 ADD
	{ 0,
		function(amx)
			if not amx.ALT.addr then
				amx.PRI.beforealtadd = amx.PRI[1]
				applyCalcOp(amx, '+', amx.ALT, amx.PRI, amx.PRI)
			else
				amx.PRI.addr = true
				amx.PRI.globvar = amx.ALT.globvar
			end
		end
	},
	--  79 SUB
	{ 0, function(amx) applyCalcOp(amx, '-') end },
	--  80 SUB.alt
	{ 0, function(amx) applyCalcOp(amx, '-', amx.ALT, amx.PRI, amx.PRI) end },
	--  81 AND
	{ 0, function(amx) applyCalcOp(amx, '&') end },
	--  82 OR
	{ 0, function(amx) applyCalcOp(amx, '|') end },
	--  83 XOR
	{ 0, function(amx) applyCalcOp(amx, '^') end },
	--  84 NOT
	{ 0, function(amx) applyCalcOp(amx, '!', amx.PRI, false) end },
	--  85 NEG
	{ 0, function(amx) applyCalcOp(amx, '-', amx.PRI, false) end },
	--  86 INVERT
	{ 0, function(amx) applyCalcOp(amx, '~', amx.PRI, false) end },
	--  87 ADD.C
	{ 1,
		function(amx, val)
			if amx.memCOD[amx.CIP] == 34 and amx.memCOD[amx.CIP+4] == 9 and amx.memCOD[amx.CIP+8] == 78 then
				-- immediate array index (more indexations following)
				amx.PRI.index = val/4
				dereference(amx.PRI)
				amx.PRI.addr = true
				amx.CIP = amx.CIP + 12
			elseif type(amx.PRI[1]) == 'number' or amx.PRI.addr then
				-- first indexation of global var or final indexation
				amx.PRI.index = val/4
				amx.PRI.addr = true
			else
				-- normal addition
				applyCalcOp(amx, '+', amx.PRI, val)
			end
		end
	},
	--  88 SMUL.C
	{ 1, function(amx, val) applyCalcOp(amx, '*', amx.PRI, val) end },
	--  89 ZERO.pri
	{ 0, function(amx) amx.PRI = { 0 } end },
	--  90 ZERO.alt
	{ 0, function(amx) amx.ALT = { 0 } end },
	--  91 ZERO
	{ 1, function(amx, addr) amx.statement = amx.globalVars[addr][1] .. ' = 0' end },
	--  92 ZERO.S
	{ 1, function(amx, offset) amx.statement = amx.frameVars[sgn(offset)][1] .. ' = 0' end },
	--  93 SIGN.pri
	{ 0, function(amx) end },
	--  94 SIGN.alt
	{ 0, function(amx) end },
	--  95 EQ
	{ 0, function(amx) applyCalcOp(amx, '==') end },
	--  96 NEQ
	{ 0, function(amx) applyCalcOp(amx, '!=') end },
	--  97 LESS
	{ 0, function(amx) applyCalcOp(amx, '<') end },
	--  98 LEQ
	{ 0, function(amx) applyCalcOp(amx, '<=') end },
	--  99 GRTR
	{ 0, function(amx) applyCalcOp(amx, '>') end },
	-- 100 GEQ
	{ 0, function(amx) applyCalcOp(amx, '>=') end },
	-- 101 SLESS
	{ 0, function(amx) applyCalcOp(amx, '<') end },
	-- 102 SLEQ
	{ 0, function(amx) applyCalcOp(amx, '<=') end },
	-- 103 SGRTR
	{ 0, function(amx) applyCalcOp(amx, '>') end },
	-- 104 SGEQ
	{ 0, function(amx) applyCalcOp(amx, '>=') end },
	-- 105 EQ.C.pri
	{ 1, function(amx, val) amx.PRI[1] = amx.PRI[1] .. ' == ' .. sgn(val) end },
	-- 106 EQ.C.alt
	{ 1, function(amx, val) amx.PRI[1] = amx.ALT[1] .. ' == ' .. sgn(val) end },
	-- 107 INC.pri
	{ 0, function(amx) applyCalcOp(amx, '++', amx.PRI, false) end },
	-- 108 INC.alt
	{ 0, function(amx) applyCalcOp(amx, '++', amx.ALT, false) end },
	-- 109 INC
	{ 1,
		function(amx, addr)
			local globvar = amx.globalVars[addr]
			if amx.PRI[1] == globvar[1] then
				amx.PRI[1] = amx.PRI[1] .. '++'
			elseif amx.ALT[1] == globvar[1] then
				amx.ALT[1] = amx.ALT[1] .. '++'
			else
				amx.statement = globvar[1] .. '++'
				table.insert(amx.incrementedGlobalVars, globvar)
			end
		end
	},
	-- 110 INC.S
	{ 1,
		function(amx, offset)
			offset = sgn(offset)
			if amx.PRI[1] == amx.frameVars[offset][1] then
				-- post increment
				amx.PRI[1] = amx.PRI[1] .. '++'
			elseif amx.ALT[1] == amx.frameVars[offset][1] then
				-- post increment
				amx.ALT[1] = amx.ALT[1] .. '++'
			else
				-- standalone increment
				amx.statement = amx.frameVars[offset][1] .. '++'
				amx.frameVars[offset].incremented = true
			end
		end
	},
	-- 111 INC.I
	{ 0,
		function(amx)
			applyCalcOp(amx, '++', dereference(amx.PRI), false)
			if amx.PRI.globvar then
				table.insert(amx.incrementedGlobalVars, amx.PRI.globvar)
			elseif amx.PRI.framevar then
				amx.PRI.framevar.incremented = true
			end
		end
	},
	-- 112 DEC.pri
	{ 0, function(amx) applyCalcOp(amx, '--', amx.PRI, false) end },
	-- 113 DEC.alt
	{ 0, function(amx) applyCalcOp(amx, '--', amx.ALT, false) end },
	-- 114 DEC
	{ 1,
		function(amx, addr)
			local globvar = amx.globalVars[addr]
			if amx.PRI[1] == globvar[1] then
				amx.PRI[1] = amx.PRI[1] .. '--'
			elseif amx.ALT[1] == globvar[1] then
				amx.ALT[1] = amx.ALT[1] .. '--'
			else
				amx.statement = globvar[1] .. '--'
				table.insert(amx.decrementedGlobalVars, globvar)
			end
		end
	},
	-- 115 DEC.S
	{ 1,
		function(amx, offset)
			offset = sgn(offset)
			if amx.PRI[1] == amx.frameVars[offset][1] then
				-- post decrement
				amx.PRI[1] = amx.PRI[1] .. '--'
			elseif amx.ALT[1] == amx.frameVars[offset][1] then
				-- post decrement
				amx.ALT[1] = amx.ALT[1] .. '--'
			else
				-- standalone decrement
				amx.statement = amx.frameVars[offset][1] .. '--'
				amx.frameVars[offset].decremented = true
			end
		end
	},
	-- 116 DEC.I
	{ 0,
		function(amx)
			applyCalcOp(amx, '--', dereference(amx.PRI), false)
			if amx.PRI.globvar then
				table.insert(amx.decrementedGlobalVars, amx.PRI.globvar)
			elseif amx.PRI.framevar then
				amx.PRI.framevar.decremented = true
			end
		end
	},
	-- 117 MOVS
	{ 1,
		function(amx, num)
			if amx.ALT.stk and amx.ALT.stk >= 12 and amx.memCOD[amx.CIP] == 44 and (amx.memCOD[amx.CIP+8] == 47 or amx.memCOD[amx.CIP+8] == 48) then
				-- delete hidden argument for functions that return arrays/strings
				amx.frameVars[amx.ALT.stk] = nil
			elseif type(amx.PRI[1]) == 'number' and amx.ALT.framevar and amx.ALT.addr then
				if amx.ALT.framevar.dimensions and num == 4*(amx.ALT.framevar.dimensions[1]+1) then
					-- load immediate array into local var
					local globvar = amx.globalVars[amx.PRI[1]]
					globvar.immediate = true
					if globvar.dimensions then
						local value = dumpGlobalArray(amx, amx.PRI[1], globvar.type, globvar.dimensions, 1, amx.indent):gsub('^%s+', ''):gsub('\n$', '')
						if amx.ALT.framevar.new then
							amx.ALT.framevar.dimensions = globvar.dimensions
							amx.ALT.framevar.value = value
						else
							amx.statement = amx.ALT[1] .. ' = ' .. value
						end
					end
					amx.ALT.framevar.globvar = globvar
				elseif amx.ALT.framevar.new then
					-- set up multidimensional array in local var
					amx.ALT.framevar.dimensions = getArrayMaxDimensionIndices(amx, amx.PRI[1], num)
				end
			elseif amx.PRI.hea then
				-- return value from function that returns an array/string
				amx.statement = amx.ALT[1] .. ' = ' .. amx.heapVars[amx.PRI.hea][1]
			end
		end
	},
	-- 118 CMPS
	{ 1,
		function(amx, num)
			
		end
	},
	-- 119 FILL
	{ 1,
		function(amx, num)
			if amx.PRI[1] ~= 0 and amx.ALT.framevar and amx.ALT.framevar.new then
				amx.ALT.framevar.dimensions = table.rep(1, num/4 + 1)
			end
		end
	},
	-- 120 HALT
	{ 1, function(amx, exitcode) end },
	-- 121 BOUNDS
	{ 1, function(amx, maxval) amx.PRI.bound = maxval end },
	-- 122 SYSREQ.pri
	{ 0, function(amx) syscall(amx, amx.PRI[1]) end },
	-- 123 SYSREQ.C
	{ 1, function(amx, svcnum) syscall(amx, svcnum) end },
	-- 124 FILE
	false,		-- obsolete
	-- 125 LINE
	false,		-- obsolete
	-- 126 SYMBOL
	false,		-- obsolete
	-- 127 SRANGE
	false,		-- obsolete
	-- 128 JUMP.pri
	{ 0, function(amx) end },
	-- 129 SWITCH
	{ 1, function(amx, casetbl) end },
	-- 130 CASETBL
	{ 0,
		function(amx)
			amx.CIP = amx.CIP + 8*(amx.memCOD[amx.CIP]+1)
		end
	},
	-- 131 SWAP.pri
	{ 0,
		function(amx)
			local temp = amx.frameVars[amx.STK]
			amx.frameVars[amx.STK] = amx.PRI
			amx.frameVars[amx.STK].value = amx.PRI[1]
			amx.PRI = temp
			amx.PRI[1] = temp.value
			amx.PRI.value = nil
		end
	},
	-- 132 SWAP.alt
	{ 0,
		function(amx)
			local temp = amx.frameVars[amx.STK]
			amx.frameVars[amx.STK] = amx.ALT
			amx.frameVars[amx.STK].value = amx.ALT[1]
			amx.ALT = temp
			amx.ALT[1] = temp.value
			amx.ALT.value = nil
		end
	},
	-- 133 PUSH.ADR
	{ 1, pushAddr },
	-- 134 NOP
	{ 0, function(amx) end },
	-- 135 SYSREQ.N
	{ 2,
		function(amx, svcnum, size)
			push(amx, size)
			syscall(amx, svcnum)
			amxOpcodes[44][2](amx, size+4)
		end
	},
	-- 136 SYMTAG
	false,		-- obsolete
	-- 137 BREAK
	{ 0, function(amx) end },
	-- 138 PUSH2.C
	{ 2, push },
	-- 139 PUSH2
	{ 2, pushMem },
	-- 140 PUSH2.S
	{ 2, pushFrameVar },
	-- 141 PUSH2.ADR
	{ 2, pushAddr },
	-- 142 PUSH3.C
	{ 3, push },
	-- 143 PUSH3
	{ 3, pushMem },
	-- 144 PUSH3.S
	{ 3, pushFrameVar },
	-- 145 PUSH3.ADR
	{ 3, pushAddr },
	-- 146 PUSH4.C
	{ 4, push },
	-- 147 PUSH4
	{ 4, pushMem },
	-- 148 PUSH4.S
	{ 4, pushFrameVar },
	-- 149 PUSH4.ADR
	{ 4, pushAddr },
	-- 150 PUSH5.C
	{ 5, push },
	-- 151 PUSH5
	{ 5, pushMem },
	-- 152 PUSH5.S
	{ 5, pushFrameVar },
	-- 153 PUSH5.ADR
	{ 5, pushAddr },
	-- 154 LOAD.both
	{ 2,
		function(amx, pri, alt)
			amx.PRI = { amx.memDAT[pri] }
			amx.ALT = { amx.memDAT[alt] }
		end
	},
	-- 155 LOAD.S.both
	{ 2,
		function(amx, pri, alt)
			amx.PRI = { amx.memDAT[amx.FRM + sgn(pri)] }
			amx.ALT = { amx.memDAT[amx.FRM + sgn(alt)] }
		end
	},
	-- 156 CONST
	{ 2, function(amx, addr, val) amx.statement = amx.globalVars[addr][1] .. ' = ' .. tostring(sgn(val)) end },
	-- 157 CONST.S
	{ 2, function(amx, offset, val) amx.statement = amx.frameVars[sgn(offset)][1] .. ' = ' .. tostring(sgn(val)) end }
}