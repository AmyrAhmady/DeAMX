function syscall(amx, svcnum)
	createFunctionCall(amx, amx.natives[svcnum], g_SAMPSyscallPrototypes[amx.natives[svcnum]])
end

g_SyscallReplace = {
	float = function(a) return type(a[1]) == 'number' and { float2cell(a[1]) } or a end,
	floatadd = function(a, b) return applyCalcOp(amx, '+', a, b) end,
	floatsub = function(a, b) return applyCalcOp(amx, '-', a, b) end,
	floatmul = function(a, b) return applyCalcOp(amx, '*', a, b) end,
	floatdiv = function(a, b) return applyCalcOp(amx, '/', a, b) end
}

g_FunctionReplace = {
	[{
		body = { [0] = 46, 137, 41, 16, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 103, 48 },
		syscalls = { [9] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' > ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 103, 48 },
		syscalls = { [7] = 'float', [16] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' > ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 104, 48 },
		syscalls = { [9] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' >= ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 104, 48 },
		syscalls = { [7] = 'float', [16] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' >= ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 101, 48 },
		syscalls = { [9] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' < ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 101, 48 },
		syscalls = { [7] = 'float', [16] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' < ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 102, 48 },
		syscalls = { [9] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' <= ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 34, 89, 35, 102, 48 },
		syscalls = { [7] = 'float', [16] = 'floatcmp' }
	}] = function(a, b) return { a[1] .. ' <= ' .. b[1] } end,
	[{
		body = { [0] = 46, 137, 3, 12, 12, 2147483648, 83, 48 }
	}] = function(a) return applyCalcOp(false, '-', a, false) end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 48 },
		syscalls = { [7] = 'float', [16] = 'floatadd' }
	}] = function(a, b) return applyCalcOp(false, '+', a, b) end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 48 },
		syscalls = { [7] = 'float', [16] = 'floatsub' }
	}] = function(a, b) return applyCalcOp(false, '-', a, b) end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 48 },
		syscalls = { [7] = 'float', [16] = 'floatmul' }
	}] = function(a, b) return applyCalcOp(false, '*', a, b) end,
	[{
		body = { [0] = 46, 137, 41, 16, 39, 4, 123, 0, 44, 8, 36, 41, 12, 39, 8, 123, 0, 44, 12, 48 },
		syscalls = { [7] = 'float', [16] = 'floatdiv' }
	}] = function(a, b) return applyCalcOp(false, '/', a, b) end
}

function createFunctionCall(amx, fnName, prototype, replaceFn)
	local numArgs = amx.frameVars[amx.STK].value/4
	local args = {}
	local arg, argval, argtype, default, isRef
	if prototype and numArgs <= #prototype then
		for i=numArgs,1,-1 do
			if prototype[i] then
				default = prototype[i]:match('^%a=(%d+)$')
				if default and tonumber(default) == amx.frameVars[amx.STK+i*4].value then
					numArgs = numArgs - 1
				else
					break
				end
			else
				break
			end
		end
	end
	if amx.curPass == 1 then
		amx.callVars[amx.CIP-8] = {}
	end
	local fmt
	for i=1,numArgs do
		arg = amx.frameVars[amx.STK+i*4]
		argval = arg.value
		
		if amx.curPass == 1 then
			if arg.globvar then
				amx.callVars[amx.CIP-8][i] = { arg.globvar.addr, isglobvar = true }
				--print(('Call at %X has globvar as arg %d'):format(amx.CIP-8, i))
			elseif arg.framevar then
				if arg.framevar.stk >= 12 then
					amx.callVars[amx.CIP-8][i] = { (arg.framevar.stk-12)/4 + 1, isargvar = true, procaddr = amx.curProcStart }
					--print(('Call at %X has arg %d as arg %d'):format(amx.CIP-8, (arg.framevar.stk-12)/4 + 1, i))
				else
					amx.callVars[amx.CIP-8][i] = { arg.framevar.definedat, islocalvar = true }
					--print(('Call at %X has local var defined at %X as arg %d'):format(amx.CIP-8, arg.framevar.definedat, i))
				end
			end
		end
				
		if prototype then
			argtype = prototype[i]
			if not argtype and fmt then
				argtype = fmt[i]
				if argtype ~= 's' then
					if arg.globvar then
						arg.globvar.type = argtype
					end
					if arg.framevar then
						arg.framevar.type = argtype
					end
				end
				if arg.globvar then
					argval = dereference(arg)[1]
				end
			end
			if argtype then
				isRef = argtype:sub(2, 2) == 'r'
				argtype = argtype:match('^(%a+)')
				
				if arg.framevar and arg.framevar.stk >= 12 then
					arg.framevar.ref = isRef
				end
				
				if #argtype > 1 then
					argtype = argtype:sub(1, 1)
				end
				if type(argval) == 'number' then
					if argtype == 'b' then
						argval = argval == 1 and 'true' or 'false'
					elseif argtype == 'c' then
						argval = ('0x%08X'):format(argval)
					elseif argtype == 's' or argtype == 'm' then
						if rawget(amx.globalVars, argval) then
							argval = amx.globalVars[argval][1]
						else
							local str = readMemString(amx, argval)
							if str and #str > 0 then
								if argtype == 'm' then
									fmt = {}
									local n = 1
									for argtype in str:gmatch('%%(%a)') do
										if argtype == 'd' then
											argtype = 'i'
										end
										fmt[i+n] = argtype
										n = n + 1
									end
								end
								argval = '"' .. str .. '"'
							else
								argval = amx.globalVars[argval][1]
							end
						end
					elseif argtype == 'r' then
						argval = amx.globalVars[argval][1]
					elseif argtype == 'i' then
						argval = sgn(argval)
					end
				elseif arg.hea then
					argval = amx.heapVars[arg.hea][1]
				--elseif (argtype == 'r' or argtype == 's') and not (arg.framevar and not arg.globvar and not arg.framevar.dimensions) and arg.index then
				--	argval = dereference(arg)[1]
				end
			end
		end
		table.insert(args, argval)
	end
	replaceFn = replaceFn or g_SyscallReplace[fnName]
	if replaceFn then
		for i=1,#args do
			args[i] = { args[i], outerop = amx.frameVars[amx.STK+4*i].outerop }
		end
		amx.PRI = replaceFn(unpack(args))
		return numArgs
	end
	amx.PRI = { fnName .. '(' .. table.concat(args, ', ') .. ')' }
	if amx.memCOD[amx.CIP-8] == 49 then
		amx.PRI.outercall = amx.memCOD[amx.CIP-4]
	else
		amx.PRI.outercall = fnName
	end
	amx.PRI.type = prototype and prototype.returntype
	if amx.STK < -4*(numArgs+1) and amx.frameVars[amx.STK+4*(numArgs+1)].hea then
		amx.heapVars[amx.frameVars[amx.STK+4*(numArgs+1)].hea][1] = amx.PRI[1]
	end
	amx.statement = amx.PRI[1]
	return numArgs
end

g_SAMPSyscallPrototypes = {
	AddMenuItem = {'m', 'i', 's'},
	AddPlayerClass = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddPlayerClassEx = {'t', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	AddStaticPickup = {'i', 'i', 'f', 'f', 'f'},
	AddStaticVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i'},
	AddStaticVehicleEx = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i'},
	AddVehicleComponent = {'v', 'i'},
	AllowAdminTeleport = {'b'},
	AllowInteriorWeapons = {'b'},
	AllowPlayerTeleport = {'p', 'b'},
	ApplyAnimation = {'p', 's', 's', 'f', 'i', 'i', 'i', 'i', 'i'},
	AttachObjectToPlayer = {'o', 'p', 'f', 'f', 'f', 'f', 'f', 'f'},
	AttachPlayerObjectToPlayer = {'p', 'i', 'p', 'f', 'f', 'f', 'f', 'f', 'f'},
	AttachTrailerToVehicle = {'v', 'v'},
	
	Ban = {'p'},
	BanEx = {'p', 's'},
	
	ChangeVehicleColor = {'v', 'i', 'i'},
	ChangeVehiclePaintjob = {'v', 'i'},
	ClearAnimations = {'p'},
	CreateExplosion = {'f', 'f', 'f', 'i', 'f'},
	CreateMenu = {'s', 'i', 'f', 'f', 'f', 'f'},
	CreateObject = {'i', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreatePickup = {'i', 'i', 'f', 'f', 'f'},
	CreatePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f'},
	CreateVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i'},
	
	DestroyObject = {'o',},
	DestroyPickup = {'o'},
	DestroyPlayerObject = {'p', 'i'},
	DestroyVehicle = {'v'},
	DetachTrailerFromVehicle = {'v'},
	DisableInteriorEnterExits = {},
	DisablePlayerCheckpoint = {'p'},
	DisablePlayerRaceCheckpoint = {'p'},
	
	EnableStuntBonusForAll = {'b'},
	EnableStuntBonusForPlayer = {'p', 'b'},
	EnableTirePopping = {'b'},
	EnableZoneNames = {'b'},
	
	ForceClassSelection = {'i'},
	
	GameModeExit = {},
	GameTextForAll = {'s', 'i', 'i'},
	GameTextForPlayer = {'p', 's', 'i', 'i'},
	GetMaxPlayers = {},
	GetObjectPos = {'o', 'fr', 'fr', 'fr'},
	GetObjectRot = {'o', 'fr', 'fr', 'fr'},
	GetPlayerAmmo = {'p'},
	GetPlayerArmour = {'p', 'fr'},
	GetPlayerColor = {'p'},
	GetPlayerFacingAngle = {'p', 'fr'},
	GetPlayerHealth = {'p', 'fr'},
	GetPlayerInterior = {'p'},
	GetPlayerIp = {'p', 'r', 'i'},
	GetPlayerKeys = {'p', 'r', 'r', 'r'},
	GetPlayerMoney = {'p'},
	GetPlayerName = {'p', 'r', 'i'},
	GetPlayerObjectPos = {'p', 'o', 'fr', 'fr', 'fr'},
	GetPlayerObjectRot = {'p', 'o', 'fr', 'fr', 'fr'},
	GetPlayerPing = {'p'},
	GetPlayerPos = {'p', 'fr', 'fr', 'fr'},
	GetPlayerScore = {'p'},
	GetPlayerSkin = {'p'},
	GetPlayerSpecialAction = {'p'},
	GetPlayerState = {'p'},
	GetPlayerTeam = {'p'},
	GetPlayerTime = {'p', 'r', 'r'},
	GetPlayerVehicleID = {'p'},
	GetPlayerVirtualWorld = {'p'},
	GetPlayerWantedLevel = {'p'},
	GetPlayerWeapon = {'p'},
	GetPlayerWeaponData = {'p', 'i', 'r', 'r'},
	GetServerVarAsBool = {'s'},
	GetServerVarAsInt = {'s'},
	GetServerVarAsString = {'s', 'r', 'i'},
	GetTickCount = {},
	GetVehicleHealth = {'v', 'r'},
	GetVehicleModel = {'v'},
	GetVehiclePos = {'v', 'fr', 'fr', 'fr'},
	GetVehicleTrailer = {'v'},
	GetVehicleVirtualWorld = {'v'},
	GetVehicleZAngle = {'v', 'fr'},
	GetWeaponName = {'i', 'r', 'i'},
	GivePlayerMoney = {'p', 'i'},
	GivePlayerWeapon = {'p', 'i', 'i'},
	
	IsPlayerAdmin = {'p'},
	IsPlayerConnected = {'p'},
	IsPlayerInAnyVehicle = {'p'},
	IsPlayerInCheckpoint = {'p'},
	IsPlayerInRaceCheckpoint = {'p'},
	IsPlayerInVehicle = {'p', 'v'},
	IsTrailerAttachedToVehicle = {'v'},
	IsValidObject = {'i'},
	IsValidPlayerObject = {'p', 'o'},
	
	Kick = {'p'},
	KillTimer = {'i'},
	
	LimitGlobalChatRadius = {'f'},
	LinkVehicleToInterior = {'v', 'i'},
	
	MoveObject = {'o', 'f', 'f', 'f', 'f'},
	MovePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f'},
	
	PlayerPlaySound = {'p', 'i', 'f', 'f', 'f'},
	PlayerSpectatePlayer = {'p', 'p', 'i'},
	PlayerSpectateVehicle = {'p', 'i', 'i=1'},
	PutPlayerInVehicle = {'p', 'v', 'i'},
	
	RemovePlayerFromVehicle = {'p'},
	RemovePlayerMapIcon = {'p', 'i'},
	RemoveVehicleComponent = {'v', 'i'},
	ResetPlayerMoney = {'p'},
	ResetPlayerWeapons = {'p'},
	
	SendClientMessage = {'p', 'c', 's'},
	SendClientMessageToAll = {'c', 's'},
	SendDeathMessage = {'p', 'p', 'i'},
	SendPlayerMessageToAll = {'p', 's'},
	SendPlayerMessageToPlayer = {'p', 'p', 's'},
	SendRconCommand = {'s'},
	SetCameraBehindPlayer = {'p'},
	SetDisabledWeapons = {},
	SetGameModeText = {'s'},
	SetGravity = {'f'},
	SetNameTagDrawDistance = {'f'},
	SetObjectPos = {'o', 'f', 'f', 'f'},
	SetObjectRot = {'o', 'f', 'f', 'f'},
	SetPlayerAmmo = {'p', 'i', 'i'},
	SetPlayerArmour = {'p', 'f'},
	SetPlayerCameraLookAt = {'p', 'f', 'f', 'f'},
	SetPlayerCameraPos = {'p', 'f', 'f', 'f'},
	SetPlayerCheckpoint = {'p', 'f', 'f', 'f', 'f'},
	SetPlayerColor = {'p', 'c'},
	SetPlayerFacingAngle = {'p', 'f'},
	SetPlayerHealth = {'p', 'f'},
	SetPlayerInterior = {'p', 'i'},
	SetPlayerMapIcon = {'p', 'i', 'f', 'f', 'f', 'i', 'c'},
	SetPlayerMarkerForPlayer = {'p', 'p', 'c'},
	SetPlayerName = {'p', 's'},
	SetPlayerObjectPos = {'p', 'i', 'f', 'f', 'f'},
	SetPlayerObjectRot = {'p', 'i', 'f', 'f', 'f'},
	SetPlayerPos = {'p', 'f', 'f', 'f'},
	SetPlayerPosFindZ = {'p', 'f', 'f', 'f'},
	SetPlayerRaceCheckpoint = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},
	SetPlayerScore = {'p', 'i'},
	SetPlayerSkin = {'p', 'i'},
	SetPlayerSpecialAction = {'p', 'i'},
	SetPlayerTeam = {'p', 't'},
	SetPlayerTime = {'p', 'i', 'i'},
	SetPlayerVirtualWorld = {'p', 'i'},
	SetPlayerWantedLevel = {'p', 'i'},
	SetPlayerWeather = {'p', 'i'},
	SetPlayerWorldBounds = {'p', 'f', 'f', 'f', 'f'},
	SetSpawnInfo = {'p', 't', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},
	SetTeamCount = {'i'},
	SetTimer = {'s', 'i', 'b'},
	SetTimerEx = {'s', 'i', 'b', 's'},
	SetVehicleHealth = {'v', 'f'},
	SetVehicleNumberPlate = {'v', 's'},
	SetVehicleParamsForPlayer = {'v', 'p', 'b', 'b'},
	SetVehiclePos = {'v', 'f', 'f', 'f'},
	SetVehicleToRespawn = {'v'},
	SetVehicleVirtualWorld = {'v', 'i'},
	SetVehicleZAngle = {'v', 'f'},
	SetWeather = {'i'},
	SetWorldTime = {'i'},
	ShowNameTags = {'b'},
	ShowPlayerMarkers = {'b'},
	ShowPlayerNameTagForPlayer = {'p', 'p', 'b'},
	SpawnPlayer = {'p'},
	StopObject = {'o'},
	StopPlayerObject = {'p', 'i'},
	
	TextDrawAlignment = {'x', 'i'},
	TextDrawBackgroundColor = {'x', 'c'},
	TextDrawBoxColor = {'x', 'c'},
	TextDrawColor = {'x', 'c'},
	TextDrawCreate = {'f', 'f', 's', returntype='x'},
	TextDrawDestroy = {'i'},
	TextDrawFont = {'x', 'i'},
	TextDrawHideForAll = {'i'},
	TextDrawHideForPlayer = {'p', 'i'},
	TextDrawLetterSize = {'x', 'f', 'f'},
	TextDrawSetOutline = {'x', 'i'},
	TextDrawSetProportional = {'x', 'b'},
	TextDrawSetShadow = {'x', 'i'},
	TextDrawSetString = {'x', 's'},
	TextDrawShowForAll = {'x'},
	TextDrawShowForPlayer = {'p', 'i'},
	TextDrawTextSize = {'x', 'f', 'f'},
	TextDrawUseBox = {'x', 'b'},
	TogglePlayerClock = {'p', 'b'},
	TogglePlayerControllable = {'p', 'b'},
	TogglePlayerSpectating = {'p', 'b'},
	
	UsePlayerPedAnims = {},
	
	deleteproperty = {'i', 's', 'i'},
	
	existproperty = {'i', 's', 'i'},
	
	fblockread = {'h', 'r', 'i'},
	fblockwrite = {'h', 'r', 'i'},
	fclose = {'h'},
	fexist = {'s'},
	fgetchar = {'h', 'r', 'b'},
	flength = {'h'},
	float = {'i', returntype='f'},
	floatabs = {'f', returntype='f'},
	floatadd = {'f', 'f', returntype='f'},
	floatcmp = {'f', 'f'},
	floatcos = {'f', 'i', returntype='f'},
	floatdiv = {'f', 'f', returntype='f'},
	floatfract = {'f'},
	floatlog = {'f', 'f', returntype='f'},
	floatmul = {'f', 'f', returntype='f'},
	floatpower = {'f', 'f', returntype='f'},
	floatround = {'f', 'i', returntype='f'},
	floatsin = {'f', 'i', returntype='f'},
	floatsub = {'f', 'f', returntype='f'},
	floatsqroot = {'f', returntype='f'},
	floattan = {'f', 'i', returntype='f'},
	floatstr = {'s', returntype='f'},	
	fmatch = {'s', 's', 'i', 'i'},
	fopen = {'s', 'i'},
	format = {'r', 'i', 'm'},
	fputchar = {'h', 'i', 'b'},
	fread = {'h', 'r', 'i=256', 'b=0'},
	fremove = {'s'},
	fseek = {'h', 'i', 'i'},
	ftemp = {},
	fwrite = {'h', 's'},
	
	getarg = {'i'},
	getdate = {'r', 'r', 'r'},
	getproperty = {'i', 's', 'i', 'r'},
	gettime = {'r', 'r', 'r'},
	
	ispacked = {'r'},
	
	memcpy = {'r', 'r', 'i', 'i', 'i'},
	
	numargs = {},
	
	print = {'s'},
	printf = {'m'},
	
	random = {'i'},
	
	setarg = {'i', 'i', 'i'},
	setproperty = {'i', 's', 'i', 's'},
	strcat = {'r', 's', 'i'},
	strcmp = {'s', 's', 'b=0', 'i=2147483647'},
	strdel = {'r', 'i', 'i'},
	strfind = {'s', 's', 'b', 'i'},
	strins = {'r', 's', 'i', 'i'},
	strlen = {'s'},
	strmid = {'r', 's', 'i', 'i', 'i'},
	strpack = {'r', 's', 'i'},
	strunpack = {'r', 's', 'i'},
	strval = {'s'},
	
	tickcount = {'i'},
	
	uudecode = {'r', 's', 'i'},
	uuencode = {'r', 's', 'i', 'i'},
	
	valstr = {'r', 'i', 'b'},
}