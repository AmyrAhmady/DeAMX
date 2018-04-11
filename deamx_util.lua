function readPrefixTable(hFile, offset, length, key)
	-- key can be 'offset' or 'index'
	-- build a name lookup table { offset = name } or { index = name }
	local entryOffset, entryNameOffset
	local result = {}
	for i=0,length/8-1 do
		entryOffset = readDWORDAt(hFile, offset)
		entryName = readString(hFile, readDWORD(hFile))
		if key == 'offset' then
			result[entryOffset] = entryName
		elseif key == 'index' then
			result[i] = entryName
		end
		offset = offset + 8
	end
	return result
end

function loadAMX(fileName)
	local hFile = io.open(fileName, 'rb')
	if not hFile then
		print('Error opening ' .. fileName)
		return
	end
	
	amx = { name = fileName:match('(.*)%.') }

	-- read header
	amx.PRI = {}
	amx.ALT = {}
	amx.flags = readWORDAt(hFile, 8)
	amx.COD = readDWORDAt(hFile, 0xC)
	amx.DAT = readDWORD(hFile)
	amx.HEA = readDWORD(hFile)
	amx.STP = readDWORD(hFile)
	amx.CIP = readDWORD(hFile)
	amx.publics = readDWORD(hFile)
	amx.natives = readDWORD(hFile)
	amx.libraries = readDWORD(hFile)		

	-- read tables with names of public and syscall functions
	amx.publics = readPrefixTable(hFile, amx.publics, amx.natives - amx.publics, 'offset')
	amx.natives = readPrefixTable(hFile, amx.natives, amx.libraries - amx.natives, 'index')
	amx.libraries = nil
	
	-- read code and data section
	local compacted = (amx.flags % 8) >= 4
	amx.sizeCOD = amx.DAT - amx.COD
	amx.sizeDAT = amx.HEA - amx.DAT
	if compacted then
		decompactCodeAndData(hFile, amx)
	else
		amx.memCOD = readDWORDs(hFile, amx.COD, amx.sizeCOD)
		amx.memDAT = readDWORDs(hFile, amx.DAT, amx.sizeDAT)
	end

	hFile:close()

	-- set up stack pointer
	amx.STK = amx.sizeDAT + (amx.STP - amx.HEA) - 4
	amx.STP = amx.STK + 4
	amx.HEA = amx.sizeDAT
	amx.FRM = 0
	return amx
end

function decompactCodeAndData(hFile, amx)
	local fileSize = hFile:seek('end')
	hFile:seek('set')
	local numRawBytes = fileSize - amx.COD
	local curByte
	local firstByteOfDWORD = true
	local curDWORDOffset = 0
	local curDWORD = 0
	local dwordsRead = 0
	
	local result = {}
	amx.memCOD = result
	local dwordsInCOD = (amx.DAT-amx.COD)/4
	
	hFile:seek('set', amx.COD)
	for i=1,numRawBytes do
		if dwordsRead == dwordsInCOD and not amx.memDAT then
			-- start filling up data if code is done
			result = {}
			amx.memDAT = result
			curDWORDOffset = 0
		end
		curByte = readBYTE(hFile)
		if firstByteOfDWORD then
			if (curByte % 0x80) >= 0x40 then
				curDWORD = 0xFFFFFFFF
			end
			firstByteOfDWORD = false
		end
		curDWORD = ((curDWORD * 128) % 4294967296) + (curByte % 0x80)
		if curByte < 0x80 then
			result[curDWORDOffset] = curDWORD
			curDWORD = 0
			curDWORDOffset = curDWORDOffset + 4
			dwordsRead = dwordsRead + 1
			firstByteOfDWORD = true
		end
	end
end

function readBYTE(hFile)
	local b0 = string.byte(hFile:read(1))
	return b0
end

function readBYTEAt(hFile, offset)
	hFile:seek('set', offset)
	return readBYTE(hFile)
end

function readWORD(hFile)
	local b0, b1 = string.byte(hFile:read(2), 1, 2)
	return b1*256 + b0
end

function readWORDAt(hFile, offset)
	hFile:seek('set', offset)
	return readWORD(hFile)
end

function readDWORD(hFile)
	local b0, b1, b2, b3 = string.byte(hFile:read(4), 1, 4)
	return b3*16777216 + b2*65536 + b1*256 + b0
end

function readDWORDAt(hFile, offset)
	hFile:seek('set', offset)
	return readDWORD(hFile)
end

function readDWORDs(hFile, offset, length)
	local result = {}
	hFile:seek('set', offset)
	for i=0,length-4,4 do
		result[i] = readDWORD(hFile)
	end
	return result
end

function readString(hFile, offset)
	local result = ""
	hFile:seek('set', offset)
	local curByte = readBYTE(hFile)
	while curByte ~= 0 do
		result = result .. string.char(curByte)
		curByte = readBYTE(hFile)
	end
	return result
end

function readMemString(amx, offset)
	local result = ''
	local curByte = amx.memDAT[offset]
	local numReadBytes = 0
	while curByte ~= 0 do
		if not curByte or curByte > 255 then
			return false
		end
		result = result .. string.char(curByte)
		offset = offset + 4
		curByte = amx.memDAT[offset]
	end
	return result:gsub('(["\\])', '\\%1'):gsub('\r', '\\r'):gsub('\n', '\\n'):gsub('\t', '\\t')
end


function step(amx, cip, opcode)
	if not opcode then
		opcode = amx.memCOD[cip]
	end
	if opcode == 130 then
		cip = cip + 4 + 8*(amx.memCOD[cip+4]+1)
	else
		cip = cip + 4 + g_AMXOpcodes[opcode][1]*4
	end
	return cip
end

function findClosestInstrsBefore(amx, instr, start, furthest, num)
	local result = {}
	if not num then
		num = 1
	end
	local cip = furthest
	local step = step
	while cip < start do
		if amx.memCOD[cip] == instr then
			table.insert(result, 1, cip)
			if #result > num then
				result[num+1] = nil
			end
		end
		cip = step(amx, cip)
	end
	return result
end

function findClosestInstrsAfter(amx, instr, start, furthest, num)
	local result = {}
	if not num then
		num = 1
	end
	local cip = start
	local opcode
	local step = step
	while cip < furthest do
		opcode = amx.memCOD[cip]
		if opcode == instr then
			table.insert(result, cip)
			if #result == num then
				return result
			end
		end
		if not g_AMXOpcodes[opcode] then
			print(('%X'):format(cip) .. ': Invalid opcode ' .. tostring(amx.memCOD[cip]))
		end
		cip = step(amx, cip)
	end
	return result
end

function getArrayMaxDimensionIndices(amx, headerStart, headerLength)
	local dimensions = {}
	local offset = headerStart
	local divideBy = 4
	local dimOffset
	local prevOffset
	while offset < headerStart + headerLength do
		dimOffset = amx.memDAT[offset]
		table.insert(dimensions, dimOffset/divideBy - 1)
		divideBy = dimOffset
		prevOffset = offset
		offset = offset + dimOffset
	end
	table.insert(dimensions, (amx.memDAT[prevOffset+4] - amx.memDAT[prevOffset])/4)
	return dimensions
end

function zeroIndexToDimension(amx, start, num)
	for i=1,num-1 do
		start = start + amx.memDAT[start]
	end
	return start
end

function dimensionsToString(dimensions)
	local dimlist = ''
	for i,dim in ipairs(dimensions) do
		dimlist = dimlist .. '[' .. (dim + 1) .. ']'
	end
	return dimlist
end

function getOpcodeAddrs(amx, from, to, ...)
	local opcodesToSearch = { ... }
	local results = {}
	for i=1,#opcodesToSearch do
		results[i] = {}
	end
	local cip = from
	local opcode
	local i
	while cip < to do
		opcode = amx.memCOD[cip]
		i = table.find(opcodesToSearch, opcode)
		if i then
			results[i][#results[i]+1] = cip
		end
		cip = step(amx, cip, opcode)
	end
	return unpack(results)
end

-----------------------------
-- Table extensions

function table.deepcopy(t)
	local known = {}
	local function _deepcopy(t)
		local result = {}
		for k,v in pairs(t) do
			if type(v) == 'table' then
				if not known[v] then
					known[v] = _deepcopy(v)
				end
				result[k] = known[v]
			else
				result[k] = v
			end
		end
		return result
	end
	return _deepcopy(t)
end

function table.shallowcopy(t)
	local result = {}
	for k,v in pairs(t) do
		result[k] = v
	end
	return result
end

function table.removevalue(t, val)
	for i,v in ipairs(t) do
		if v == val then
			table.remove(t, i)
			return i
		end
	end
	return false
end

function table.filter(t, callback, cmpval)
	if cmpval == nil then
		cmpval = true
	end
	for k,v in pairs(t) do
		if callback(v) ~= cmpval then
			t[k] = nil
		end
	end
	return t
end

function table.rep(val, num)
	local result = {}
	for i=1,num do
		result[i] = val
	end
	return result
end

function table.map(t, callback, ...)
	for k,v in ipairs(t) do
		t[k] = callback(v, ...)
	end
	return t
end

function table.each(t, index, callback, ...)
	if type(index) == 'function' then
		table.insert(arg, 1, callback)
		callback = index
		index = false
	end
	for k,v in pairs(t) do
		callback(index and v[index] or v, unpack(arg))
	end
	return t
end

function table.find0(t, val)
	if t[0] == val then
		return 0
	end
	for k,v in pairs(t) do
		if v == val then
			return k
		end
	end
	return false
end

function table.find(t, ...)
	local args = { ... }
	if #args == 0 then
		for k,v in pairs(t) do
			if v then
				return k
			end
		end
		return false
	end
	
	local value = table.remove(args)
	if value == '[nil]' then
		value = nil
	end
	for k,v in pairs(t) do
		for i,index in ipairs(args) do
			if type(index) == 'function' then
				v = index(v)
			else
				if index == '[last]' then
					index = #v
				end
				v = v[index]
			end
		end
		if v == value then
			return k
		end
	end
	return false
end

function table.findall(t, ...)
	local args = { ... }
	local result = {}
	if #args == 0 then
		for k,v in pairs(t) do
			if v then
				result[k] = v
			end
		end
		return result
	end
	
	local value = table.remove(args)
	if value == '[nil]' then
		value = nil
	end
	for k,v in pairs(t) do
		for i,index in ipairs(args) do
			if type(index) == 'function' then
				v = index(v)
			else
				if index == '[last]' then
					index = #v
				end
				v = v[index]
			end
		end
		if v == value then
			result[#result+1] = v
		end
	end
	return result
end

function table.merge(t1, t2)
	local l = #t1
	for i,v in ipairs(t2) do
		t1[l+i] = v
	end
	return t1
end

function table.insert0(t, d)
	if t[0] then
		local i = #t+1
		t[i] = d
		return i
	else
		t[0] = d
		return 0
	end
end

function table.slice(t, from, to)
	if not to then
		to = #t
	end
	local result = {}
	for i=from,to do
		result[#result+1] = t[i]
	end
	return result
end

function table.clear(t)
	for k,v in pairs(t) do
		t[k] = nil
	end
end

-----------------------------
-- Binary operations

function cell2color(val)
	local binshr = binshr
	return binshr(val, 24), binshr(val, 16) % 0x100, binshr(val, 8) % 0x100, val % 0x1000
end

function cell2float(cell)
	if cell == 0 then
		return 0
	end
	local binshr = binshr
	
	local sign = binshr(cell, 31) == 0 and 1 or -1
	local exp = (binshr(cell, 23) % (2^8)) - 127
	local mantissa = cell % (2^23)
	local fpmantissa = 0
	for i=-23,-1 do
		if mantissa % 2 == 1 then
			fpmantissa = fpmantissa + 2^i
		end
		mantissa = binshr(mantissa, 1)
	end
	return math.floor((sign * (2^exp) * (1+fpmantissa))*10000)/10000
end

function float2cell(float)
	if float == 0 then
		return 0
	end
	local binshl = binshl
	
	-- sign bit
	local sign = 0
	if float < 0 then
		sign = 2^31
		float = -float
	end
	local ipart, fpart = math.modf(float)
	-- exponent
	local exp = 0
	while ipart > 2^exp do
		exp = exp + 1
	end
	if 2^exp > ipart then
		exp = exp - 1
	end
	-- mantissa
	local numFPartBits = 0
	local fpartBits = 0
	while fpart ~= 0 and numFPartBits < 23 do
		fpart = 2*fpart
		if fpart >= 1 then
			fpart = fpart - 1
			fpartBits = binshl(fpartBits, 1) + 1
		else
			fpartBits = binshl(fpartBits, 1)
		end
		numFPartBits = numFPartBits + 1
	end
	ipart = ipart - 2^exp
	local mantissa = binshl(ipart, numFPartBits) + fpartBits

	-- build
	return sign + binshl(exp+127, 23) + binshl(mantissa, 23 - (exp+numFPartBits))
end

function binand(val1, val2)
	local i, result = 0, 0
	while val1 ~= 0 and val2 ~= 0 do
		result = result + ( ((val1 % 2) == 1 and (val2 % 2) == 1) and (2^i) or 0 )
		val1 = math.floor(val1/2)
		val2 = math.floor(val2/2)
		i = i + 1
	end
	return result
end

function binor(val1, val2)
	local i, result = 0, 0
	while val1 ~= 0 or val2 ~= 0 do
		result = result + ( ((val1 % 2) == 1 or (val2 % 2) == 1) and (2^i) or 0 )
		val1 = math.floor(val1/2)
		val2 = math.floor(val2/2)
		i = i + 1
	end
	return result
end

function binxor(val1, val2)
	local i, result = 0, 0
	local b1, b2
	while val1 ~= 0 or val2 ~= 0 do
		b1 = val1 % 2
		b2 = val2 % 2
		result = result + ( ((b1 == 1 and b2 == 0) or (b1 == 0 and b2 == 1)) and (2^i) or 0 )
		val1 = math.floor(val1/2)
		val2 = math.floor(val2/2)
		i = i + 1
	end
	return result
end

function binnot(val)
	local result = 0
	for i=0,31 do
		if (val % 2) == 0 then
			result = result + 2^i
		end
		val = math.floor(val/2)
	end
	return result
end

function binshl(val, dist)
	return val * (2^dist)
end

function binshr(val, dist)
	return math.floor(val / (2^dist))
end

function binsar(val, dist)
	local signext = 0
	if val >= 0x80000000 then
		for i=31,31-dist,-1 do
			signext = signext + 2^i
		end
	end
	return signext + math.floor(val / (2^dist))
end

function sgn(val, amx)
	if val >= 0x80000000 then
		val = -(binnot(val) + 1)
	end
	return val
end

function unsgn(val)
	if val < 0 then
		val = binnot(-val) + 1
	end
	return val
end
