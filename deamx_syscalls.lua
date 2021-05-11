function syscall(amx, svcnum)
	pcall(createFunctionCall,amx, amx.natives[svcnum], g_SAMPSyscallPrototypes[amx.natives[svcnum]])
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
	
	print = {'s'},

	printf = {'s', 'm'},

	format = {'s', 'i', 's', 'm'},

	SendClientMessage = {'p', 'i', 's'},

	SendClientMessageToAll = {'i', 's'},

	SendPlayerMessageToPlayer = {'p', 'i', 's'},

	SendPlayerMessageToAll = {'i', 's'},

	SendDeathMessage = {'i', 'i', 'i'},

	SendDeathMessageToPlayer = {'p', 'i', 'i', 'i'},

	GameTextForAll = {'s', 'i', 'i'},

	GameTextForPlayer = {'p', 's', 'i', 'i'},

	SetTimer = {'s', 'i', 'i'},

	SetTimerEx = {'s', 'i', 'i', 's', 'm'},

	KillTimer = {'i'},

	GetTickCount = {},

	GetMaxPlayers = {},

	CallRemoteFunction = {'s', 's', 'm'},

	CallLocalFunction = {'s', 's', 'm'},

	VectorSize = {'f', 'f', 'f', returntype='f'},

	asin = {'f', returntype='f'},

	acos = {'f', returntype='f'},

	atan = {'f', returntype='f'},

	atan2 = {'f', 'f', returntype='f'},

	GetPlayerPoolSize = {},

	GetVehiclePoolSize = {},

	GetActorPoolSize = {},

	SHA256_PassHash = {'s', 's', 's', 'i'},

	SetSVarInt = {'s', 'i'},

	GetSVarInt = {'s'},

	SetSVarString = {'s', 's'},

	GetSVarString = {'s', 's', 'i'},

	SetSVarFloat = {'s', 'f'},

	GetSVarFloat = {'s', returntype='f'},

	DeleteSVar = {'s'},

	GetSVarsUpperIndex = {},

	GetSVarNameAtIndex = {'i', 's', 'i'},

	GetSVarType = {'s'},

	SetGameModeText = {'s'},

	SetTeamCount = {'i'},

	AddPlayerClass = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},

	AddPlayerClassEx = {'i', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},

	AddStaticVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i'},

	AddStaticVehicleEx = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'},

	AddStaticPickup = {'i', 'i', 'f', 'f', 'f', 'i'},

	CreatePickup = {'i', 'i', 'f', 'f', 'f', 'i'},

	DestroyPickup = {'i'},

	ShowNameTags = {'i'},

	ShowPlayerMarkers = {'i'},

	GameModeExit = {},

	SetWorldTime = {'i'},

	GetWeaponName = {'i', 's', 'i'},

	EnableTirePopping = {'i'},

	EnableVehicleFriendlyFire = {},

	AllowInteriorWeapons = {'i'},

	SetWeather = {'i'},

	SetGravity = {'f'},

	AllowAdminTeleport = {'i'},

	SetDeathDropAmount = {'i'},

	CreateExplosion = {'f', 'f', 'f', 'i', 'f'},

	EnableZoneNames = {'i'},

	UsePlayerPedAnims = {'i'},

	DisableInteriorEnterExits = {'i'},

	SetNameTagDrawDistance = {'f'},

	DisableNameTagLOS = {'i'},

	LimitGlobalChatRadius = {'f'},

	LimitPlayerMarkerRadius = {'f'},

	ConnectNPC = {'s', 's'},

	IsPlayerNPC = {'p'},

	IsPlayerAdmin = {'p'},

	Kick = {'p'},

	Ban = {'p'},

	BanEx = {'p', 's'},

	SendRconCommand = {'s'},

	GetPlayerNetworkStats = {'p', 's', 'i'},

	GetNetworkStats = {'s', 'i'},

	GetPlayerVersion = {'p', 's', 'i'},

	BlockIpAddress = {'s', 'i'},

	UnBlockIpAddress = {'s'},

	GetServerVarAsString = {'s', 's', 'i'},

	GetServerVarAsInt = {'s'},

	GetServerVarAsBool = {'s'},

	GetConsoleVarAsString = {'s', 's', 'i'},

	GetConsoleVarAsInt = {'s'},

	GetConsoleVarAsBool = {'s'},

	GetServerTickRate = {},

	NetStats_GetConnectedTime = {'p'},

	NetStats_MessagesReceived = {'p'},

	NetStats_BytesReceived = {'p'},

	NetStats_MessagesSent = {'p'},

	NetStats_BytesSent = {'p'},

	NetStats_MessagesRecvPerSecond = {'p'},

	NetStats_PacketLossPercent = {'p', returntype='f'},

	NetStats_ConnectionStatus = {'p'},

	NetStats_GetIpPort = {'p', 's', 'i'},

	CreateMenu = {'s', 'i', 'f', 'f', 'f', 'f', returntype='n'},

	DestroyMenu = {'n'},

	AddMenuItem = {'n', 's'},

	SetMenuColumnHeader = {'n', 's'},

	ShowMenuForPlayer = {'n', 'p'},

	HideMenuForPlayer = {'n', 'p'},

	IsValidMenu = {'n'},

	DisableMenu = {'n'},

	DisableMenuRow = {'n'},

	GetPlayerMenu = {'p'},

	TextDrawCreate = {'f', 'f', 's', returntype='x'},

	TextDrawDestroy = {'x'},

	TextDrawLetterSize = {'x', 'f', 'f'},

	TextDrawTextSize = {'x', 'f', 'f'},

	TextDrawAlignment = {'x', 'i'},

	TextDrawColor = {'x', 'i'},

	TextDrawUseBox = {'x', 'i'},

	TextDrawBoxColor = {'x', 'i'},

	TextDrawSetShadow = {'x', 'i'},

	TextDrawSetOutline = {'x', 'i'},

	TextDrawBackgroundColor = {'x', 'i'},

	TextDrawFont = {'x', 'i'},

	TextDrawSetProportional = {'x', 'i'},

	TextDrawSetSelectable = {'x', 'i'},

	TextDrawShowForPlayer = {'p', 'x'},

	TextDrawHideForPlayer = {'p', 'x'},

	TextDrawShowForAll = {'x'},

	TextDrawHideForAll = {'x'},

	TextDrawSetString = {'x', 's'},

	TextDrawSetPreviewModel = {'x', 'i'},

	TextDrawSetPreviewRot = {'x', 'f', 'f', 'f', 'f'},

	TextDrawSetPreviewVehCol = {'x', 'i', 'i'},

	GangZoneCreate = {'f', 'f', 'f', 'f'},

	GangZoneDestroy = {'i'},

	GangZoneShowForPlayer = {'p', 'i', 'i'},

	GangZoneShowForAll = {'i', 'i'},

	GangZoneHideForPlayer = {'p', 'i'},

	GangZoneHideForAll = {'i'},

	GangZoneFlashForPlayer = {'p', 'i', 'i'},

	GangZoneFlashForAll = {'i', 'i'},

	GangZoneStopFlashForPlayer = {'p', 'i'},

	GangZoneStopFlashForAll = {'i'},

	Create3DTextLabel = {'s', 'i', 'f', 'f', 'f', 'f', 'i', 'i', returntype='d'},

	Delete3DTextLabel = {'d'},

	Attach3DTextLabelToPlayer = {'d', 'p', 'f', 'f', 'f'},

	Attach3DTextLabelToVehicle = {'d', 'v', 'f', 'f', 'f'},

	Update3DTextLabelText = {'d', 'i', 's'},

	CreatePlayer3DTextLabel = {'p', 's', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', returntype='dp'},

	DeletePlayer3DTextLabel = {'p', 'dp'},

	UpdatePlayer3DTextLabelText = {'p', 'dp', 'i', 's'},

	ShowPlayerDialog = {'p', 'i', 'i', 's', 's', 's', 's'},

	SetSpawnInfo = {'p', 'i', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},

	SpawnPlayer = {'p'},

	SetPlayerPos = {'p', 'f', 'f', 'f'},

	SetPlayerPosFindZ = {'p', 'f', 'f', 'f'},

	GetPlayerPos = {'p', 'fr', 'fr', 'fr'},

	SetPlayerFacingAngle = {'p', 'f'},

	GetPlayerFacingAngle = {'p', 'fr'},

	IsPlayerInRangeOfPoint = {'p', 'f', 'f', 'f', 'f'},

	GetPlayerDistanceFromPoint = {'p', 'f', 'f', 'f', returntype='f'},

	IsPlayerStreamedIn = {'p', 'p'},

	SetPlayerInterior = {'p', 'i'},

	GetPlayerInterior = {'p'},

	SetPlayerHealth = {'p', 'f'},

	GetPlayerHealth = {'p', 'fr'},

	SetPlayerArmour = {'p', 'f'},

	GetPlayerArmour = {'p', 'fr'},

	SetPlayerAmmo = {'p', 'i', 'i'},

	GetPlayerAmmo = {'p'},

	GetPlayerWeaponState = {'p'},

	GetPlayerTargetPlayer = {'p'},

	GetPlayerTargetActor = {'p'},

	SetPlayerTeam = {'p', 'i'},

	GetPlayerTeam = {'p'},

	SetPlayerScore = {'p', 'i'},

	GetPlayerScore = {'p'},

	GetPlayerDrunkLevel = {'p'},

	SetPlayerDrunkLevel = {'p', 'i'},

	SetPlayerColor = {'p', 'i'},

	GetPlayerColor = {'p'},

	SetPlayerSkin = {'p', 'i'},

	GetPlayerSkin = {'p'},

	GivePlayerWeapon = {'p', 'i', 'i'},

	ResetPlayerWeapons = {'p'},

	SetPlayerArmedWeapon = {'p', 'i'},

	GetPlayerWeaponData = {'p', 'i', 'r', 'r'},

	GivePlayerMoney = {'p', 'i'},

	ResetPlayerMoney = {'p'},

	SetPlayerName = {'p', 's'},

	GetPlayerMoney = {'p'},

	GetPlayerState = {'p'},

	GetPlayerIp = {'p', 's', 'i'},

	GetPlayerPing = {'p'},

	GetPlayerWeapon = {'p'},

	GetPlayerKeys = {'p', 'r', 'r', 'r'},

	GetPlayerName = {'p', 's', 'i'},

	SetPlayerTime = {'p', 'i', 'i'},

	GetPlayerTime = {'p', 'r', 'r'},

	TogglePlayerClock = {'p', 'i'},

	SetPlayerWeather = {'p', 'i'},

	ForceClassSelection = {'p'},

	SetPlayerWantedLevel = {'p', 'i'},

	GetPlayerWantedLevel = {'p'},

	SetPlayerFightingStyle = {'p', 'i'},

	GetPlayerFightingStyle = {'p'},

	SetPlayerVelocity = {'p', 'f', 'f', 'f'},

	GetPlayerVelocity = {'p', 'fr', 'fr', 'fr'},

	PlayCrimeReportForPlayer = {'p', 'i', 'i'},

	PlayAudioStreamForPlayer = {'p', 's', 'f', 'f', 'f', 'f', 'i'},

	StopAudioStreamForPlayer = {'p'},

	SetPlayerShopName = {'p', 's'},

	SetPlayerSkillLevel = {'p', 'i', 'i'},

	GetPlayerSurfingVehicleID = {'p'},

	GetPlayerSurfingObjectID = {'p'},

	RemoveBuildingForPlayer = {'p', 'i', 'f', 'f', 'f', 'f'},

	GetPlayerLastShotVectors = {'p', 'fr', 'fr', 'fr', 'fr', 'fr', 'fr'},

	SetPlayerAttachedObject = {'p', 'i', 'i', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},

	RemovePlayerAttachedObject = {'p', 'i'},

	IsPlayerAttachedObjectSlotUsed = {'p', 'i'},

	EditAttachedObject = {'p', 'i'},

	CreatePlayerTextDraw = {'p', 'f', 'f', 's', returntype='xp'},

	PlayerTextDrawDestroy = {'p', 'xp'},

	PlayerTextDrawLetterSize = {'p', 'xp', 'f', 'f'},

	PlayerTextDrawTextSize = {'p', 'xp', 'f', 'f'},

	PlayerTextDrawAlignment = {'p', 'xp', 'i'},

	PlayerTextDrawColor = {'p', 'xp', 'i'},

	PlayerTextDrawUseBox = {'p', 'xp', 'i'},

	PlayerTextDrawBoxColor = {'p', 'xp', 'i'},

	PlayerTextDrawSetShadow = {'p', 'xp', 'i'},

	PlayerTextDrawSetOutline = {'p', 'xp', 'i'},

	PlayerTextDrawBackgroundColor = {'p', 'xp', 'i'},

	PlayerTextDrawFont = {'p', 'xp', 'i'},

	PlayerTextDrawSetProportional = {'p', 'xp', 'i'},

	PlayerTextDrawSetSelectable = {'p', 'xp', 'i'},

	PlayerTextDrawShow = {'p', 'xp'},

	PlayerTextDrawHide = {'p', 'xp'},

	PlayerTextDrawSetString = {'p', 'xp', 's'},

	PlayerTextDrawSetPreviewModel = {'p', 'xp', 'i'},

	PlayerTextDrawSetPreviewRot = {'p', 'xp', 'f', 'f', 'f', 'f'},

	PlayerTextDrawSetPreviewVehCol = {'p', 'xp', 'i', 'i'},

	SetPVarInt = {'p', 's', 'i'},

	GetPVarInt = {'p', 's'},

	SetPVarString = {'p', 's', 's'},

	GetPVarString = {'p', 's', 's', 'i'},

	SetPVarFloat = {'p', 's', 'f'},

	GetPVarFloat = {'p', 's', returntype='f'},

	DeletePVar = {'p', 's'},

	GetPVarsUpperIndex = {'p'},

	GetPVarNameAtIndex = {'p', 'i', 's', 'i'},

	GetPVarType = {'p', 's'},

	SetPlayerChatBubble = {'p', 's', 'i', 'f', 'i'},

	PutPlayerInVehicle = {'p', 'v', 'i'},

	GetPlayerVehicleID = {'p'},

	GetPlayerVehicleSeat = {'p'},

	RemovePlayerFromVehicle = {'p'},

	TogglePlayerControllable = {'p', 'i'},

	PlayerPlaySound = {'p', 'i', 'f', 'f', 'f'},

	ApplyAnimation = {'p', 's', 's', 'f', 'i', 'i', 'i', 'i', 'i', 'i'},

	ClearAnimations = {'p', 'i'},

	GetPlayerAnimationIndex = {'p'},

	GetAnimationName = {'i', 's', 'i', 's', 'i'},

	GetPlayerSpecialAction = {'p'},

	SetPlayerSpecialAction = {'p', 'i'},

	DisableRemoteVehicleCollisions = {'p', 'i'},

	SetPlayerCheckpoint = {'p', 'f', 'f', 'f', 'f'},

	DisablePlayerCheckpoint = {'p'},

	SetPlayerRaceCheckpoint = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	DisablePlayerRaceCheckpoint = {'p'},

	SetPlayerWorldBounds = {'p', 'f', 'f', 'f', 'f'},

	SetPlayerMarkerForPlayer = {'p', 'p', 'i'},

	ShowPlayerNameTagForPlayer = {'p', 'p', 'i'},

	SetPlayerMapIcon = {'p', 'i', 'f', 'f', 'f', 'i', 'i', 'i'},

	RemovePlayerMapIcon = {'p', 'i'},

	AllowPlayerTeleport = {'p', 'i'},

	SetPlayerCameraPos = {'p', 'f', 'f', 'f'},

	SetPlayerCameraLookAt = {'p', 'f', 'f', 'f', 'i'},

	SetCameraBehindPlayer = {'p'},

	GetPlayerCameraPos = {'p', 'fr', 'fr', 'fr'},

	GetPlayerCameraFrontVector = {'p', 'fr', 'fr', 'fr'},

	GetPlayerCameraMode = {'p'},

	EnablePlayerCameraTarget = {'p', 'i'},

	GetPlayerCameraTargetObject = {'p'},

	GetPlayerCameraTargetVehicle = {'p'},

	GetPlayerCameraTargetPlayer = {'p'},

	GetPlayerCameraTargetActor = {'p'},

	GetPlayerCameraAspectRatio = {'p', returntype='f'},

	GetPlayerCameraZoom = {'p', returntype='f'},

	AttachCameraToObject = {'p', 'o'},

	AttachCameraToPlayerObject = {'p', 'o'},

	InterpolateCameraPos = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},

	InterpolateCameraLookAt = {'p', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'},

	IsPlayerConnected = {'p'},

	IsPlayerInVehicle = {'p', 'v'},

	IsPlayerInAnyVehicle = {'p'},

	IsPlayerInCheckpoint = {'p'},

	IsPlayerInRaceCheckpoint = {'p'},

	SetPlayerVirtualWorld = {'p', 'i'},

	GetPlayerVirtualWorld = {'p'},

	EnableStuntBonusForPlayer = {'p', 'i'},

	EnableStuntBonusForAll = {'i'},

	TogglePlayerSpectating = {'p', 'i'},

	PlayerSpectatePlayer = {'p', 'p', 'i'},

	PlayerSpectateVehicle = {'p', 'v', 'i'},

	StartRecordingPlayerData = {'p', 'i', 's'},

	StopRecordingPlayerData = {'p'},

	SelectTextDraw = {'p', 'i'},

	CancelSelectTextDraw = {'p'},

	CreateExplosionForPlayer = {'p', 'f', 'f', 'f', 'i', 'f'},

	CreateActor = {'i', 'f', 'f', 'f', 'f'},

	DestroyActor = {'i'},

	IsActorStreamedIn = {'i', 'p'},

	SetActorVirtualWorld = {'i', 'i'},

	GetActorVirtualWorld = {'i'},

	ApplyActorAnimation = {'i', 's', 's', 'f', 'i', 'i', 'i', 'i', 'i'},

	ClearActorAnimations = {'i'},

	SetActorPos = {'i', 'f', 'f', 'f'},

	GetActorPos = {'i', 'fr', 'fr', 'fr'},

	SetActorFacingAngle = {'i', 'f'},

	GetActorFacingAngle = {'i', 'fr'},

	SetActorHealth = {'i', 'f'},

	GetActorHealth = {'i', 'fr'},

	SetActorInvulnerable = {'i', 'i'},

	IsActorInvulnerable = {'i'},

	IsValidActor = {'i'},

	HTTP = {'i', 'i', 's', 's', 's'},

	CreateObject = {'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	AttachObjectToVehicle = {'o', 'v', 'f', 'f', 'f', 'f', 'f', 'f'},

	AttachObjectToObject = {'o', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'i'},

	AttachObjectToPlayer = {'o', 'p', 'f', 'f', 'f', 'f', 'f', 'f'},

	SetObjectPos = {'o', 'f', 'f', 'f'},

	GetObjectPos = {'o', 'fr', 'fr', 'fr'},

	SetObjectRot = {'o', 'f', 'f', 'f'},

	GetObjectRot = {'o', 'fr', 'fr', 'fr'},

	GetObjectModel = {'o'},

	SetObjectNoCameraCol = {'o'},

	IsValidObject = {'o'},

	DestroyObject = {'o'},

	MoveObject = {'o', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	StopObject = {'o'},

	IsObjectMoving = {'o'},

	EditObject = {'p', 'o'},

	EditPlayerObject = {'p', 'o'},

	SelectObject = {'p'},

	CancelEdit = {'p'},

	CreatePlayerObject = {'p', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	AttachPlayerObjectToVehicle = {'p', 'o', 'v', 'f', 'f', 'f', 'f', 'f', 'f'},

	SetPlayerObjectPos = {'p', 'o', 'f', 'f', 'f'},

	GetPlayerObjectPos = {'p', 'o', 'fr', 'fr', 'fr'},

	SetPlayerObjectRot = {'p', 'o', 'f', 'f', 'f'},

	GetPlayerObjectRot = {'p', 'o', 'fr', 'fr', 'fr'},

	GetPlayerObjectModel = {'p', 'o'},

	SetPlayerObjectNoCameraCol = {'p', 'o'},

	IsValidPlayerObject = {'p', 'o'},

	DestroyPlayerObject = {'p', 'o'},

	MovePlayerObject = {'p', 'o', 'f', 'f', 'f', 'f', 'f', 'f', 'f'},

	StopPlayerObject = {'p', 'o'},

	IsPlayerObjectMoving = {'p', 'o'},

	AttachPlayerObjectToPlayer = {'i', 'o', 'i', 'f', 'f', 'f', 'f', 'f', 'f'},

	SetObjectMaterial = {'o', 'i', 'i', 's', 's', 'i'},

	SetPlayerObjectMaterial = {'p', 'o', 'i', 'i', 's', 's', 'i'},

	SetObjectMaterialText = {'o', 's', 'i', 'i', 's', 'i', 'i', 'i', 'i', 'i'},

	SetPlayerObjectMaterialText = {'p', 'o', 's', 'i', 'i', 's', 'i', 'i', 'i', 'i', 'i'},

	SetObjectsDefaultCameraCol = {'i'},

	CreateVehicle = {'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'},

	DestroyVehicle = {'v'},

	IsVehicleStreamedIn = {'v', 'p'},

	GetVehiclePos = {'v', 'fr', 'fr', 'fr'},

	SetVehiclePos = {'v', 'f', 'f', 'f'},

	GetVehicleZAngle = {'v', 'fr'},

	GetVehicleRotationQuat = {'v', 'fr', 'fr', 'fr', 'fr'},

	GetVehicleDistanceFromPoint = {'v', 'f', 'f', 'f', returntype='f'},

	SetVehicleZAngle = {'v', 'f'},

	SetVehicleParamsForPlayer = {'v', 'p', 'i', 'i'},

	ManualVehicleEngineAndLights = {},

	SetVehicleParamsEx = {'v', 'i', 'i', 'i', 'i', 'i', 'i', 'i'},

	GetVehicleParamsEx = {'v', 'r', 'r', 'r', 'r', 'r', 'r', 'r'},

	GetVehicleParamsSirenState = {'v'},

	SetVehicleParamsCarDoors = {'v', 'i', 'i', 'i', 'i'},

	GetVehicleParamsCarDoors = {'v', 'r', 'r', 'r', 'r'},

	SetVehicleParamsCarWindows = {'v', 'i', 'i', 'i', 'i'},

	GetVehicleParamsCarWindows = {'v', 'r', 'r', 'r', 'r'},

	SetVehicleToRespawn = {'v'},

	LinkVehicleToInterior = {'v', 'i'},

	AddVehicleComponent = {'v', 'i'},

	RemoveVehicleComponent = {'v', 'i'},

	ChangeVehicleColor = {'v', 'i', 'i'},

	ChangeVehiclePaintjob = {'v', 'i'},

	SetVehicleHealth = {'v', 'f'},

	GetVehicleHealth = {'v', 'fr'},

	AttachTrailerToVehicle = {'i', 'v'},

	DetachTrailerFromVehicle = {'v'},

	IsTrailerAttachedToVehicle = {'v'},

	GetVehicleTrailer = {'v'},

	SetVehicleNumberPlate = {'v', 's'},

	GetVehicleModel = {'v'},

	GetVehicleComponentInSlot = {'v', 'i'},

	GetVehicleComponentType = {'i'},

	RepairVehicle = {'v'},

	GetVehicleVelocity = {'v', 'fr', 'fr', 'fr'},

	SetVehicleVelocity = {'v', 'f', 'f', 'f'},

	SetVehicleAngularVelocity = {'v', 'f', 'f', 'f'},

	GetVehicleDamageStatus = {'v', 'r', 'r', 'r', 'r'},

	UpdateVehicleDamageStatus = {'v', 'i', 'i', 'i', 'i'},

	GetVehicleModelInfo = {'i', 'i', 'fr', 'fr', 'fr'},

	SetVehicleVirtualWorld = {'v', 'i'},

	GetVehicleVirtualWorld = {'v'},

	heapspace = {},

	funcidx = {'s'},

	numargs = {},

	getarg = {'i', 'i'},

	setarg = {'i', 'i', 'i'},

	tolower = {'i'},

	toupper = {'i'},

	swapchars = {'i'},

	random = {'i'},

	min = {'i', 'i'},

	max = {'i', 'i'},

	clamp = {'i', 'i', 'i'},

	getproperty = {'i', 's', 'i', 's'},

	setproperty = {'i', 's', 'i', 's'},

	deleteproperty = {'i', 's', 'i'},

	existproperty = {'i', 's', 'i'},

	sendstring = {'s', 's'},

	sendpacket = {'s', 'i', 's'},

	listenport = {'i'},

	fopen = {'s', 'i', returntype='h'},

	fclose = {'h'},

	ftemp = {returntype='h'},

	fremove = {'s'},

	fwrite = {'h', 's'},

	fread = {'h', 's', 'i', 'b'},

	fputchar = {'h', 'i', 'b'},

	fgetchar = {'h', 'i', 'b'},

	fblockwrite = {'h', 's', 'i'},

	fblockread = {'h', 's', 'i'},

	fseek = {'h', 'i', 'i'},

	flength = {'h'},

	fexist = {'s'},

	fmatch = {'s', 's', 'i', 'i'},

	float = {'i', returntype='f'},

	floatstr = {'s', returntype='f'},

	floatmul = {'f', 'f', returntype='f'},

	floatdiv = {'f', 'f', returntype='f'},

	floatadd = {'f', 'f', returntype='f'},

	floatsub = {'f', 'f', returntype='f'},

	floatfract = {'f', returntype='f'},

	floatround = {'f', 'i'},

	floatcmp = {'f', 'f'},

	floatsqroot = {'f', returntype='f'},

	floatpower = {'f', 'f', returntype='f'},

	floatlog = {'f', 'f', returntype='f'},

	floatsin = {'f', 'i', returntype='f'},

	floatcos = {'f', 'i', returntype='f'},

	floattan = {'f', 'i', returntype='f'},

	floatabs = {'f', returntype='f'},

	strlen = {'s'},

	strpack = {'s', 's', 'i'},

	strunpack = {'s', 's', 'i'},

	strcat = {'s', 's', 'i'},

	strmid = {'s', 's', 'i', 'i', 'i'},

	strins = {'s', 's', 'i', 'i'},

	strdel = {'s', 'i', 'i'},

	strcmp = {'s', 's', 'b', 'i'},

	strfind = {'s', 's', 'b', 'i'},

	strval = {'s'},

	valstr = {'s', 'i', 'b'},

	ispacked = {'s'},

	uudecode = {'s', 's', 'i'},

	uuencode = {'s', 's', 'i', 'i'},

	memcpy = {'s', 's', 'i', 'i', 'i'},

	gettime = {'r', 'r', 'r'},

	getdate = {'r', 'r', 'r'},

	tickcount = {'r'},


	CreateDynamicObject = { 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'p', 'f', 'f', 'i', 'i' },
	DestroyDynamicObject = { 'o' },
	IsValidDynamicObject = { 'o' },
	GetDynamicObjectPos = { 'o', 'f', 'f', 'f' },
	SetDynamicObjectPos = { 'o', 'f', 'f', 'f' },
	GetDynamicObjectRot = { 'o', 'f', 'f', 'f' },
	SetDynamicObjectRot = { 'o', 'f', 'f', 'f' },
	MoveDynamicObject = { 'o', 'f', 'f', 'f', 'f', 'f', 'f', 'f' },
	StopDynamicObject = { 'o' },
	IsDynamicObjectMoving = { 'o' },
	AttachCameraToDynamicObject = { 'p', 'o' },
	AttachDynamicObjectToObject = { 'o', 'o', 'f', 'f', 'f', 'f', 'f', 'f', 'i' },
	AttachDynamicObjectToVehicle = { 'o', 'v', 'f', 'f', 'f', 'f', 'f', 'f' },
	EditDynamicObject = { 'p', 'o' },
	IsDynamicObjectMaterialUsed = { 'o', 'i' },
	RemoveDynamicObjectMaterial = { 'o', 'i' },
	GetDynamicObjectMaterial = { 'o', 'i', 'i', 's', 's', 'i', 'i', 'i' },
	SetDynamicObjectMaterial = { 'o', 'i', 'i', 's', 's', 'i' },
	IsDynamicObjectMaterialTextUsed = { 'o', 'i' },
	RemoveDynamicObjectMaterialText = { 'o', 'i' },
	GetDynamicObjectMaterialText = { 'o', 'i', 's', 'i', 's', 'i', 'i', 'i', 'i', 'i', 'i', 'i' },
	SetDynamicObjectMaterialText = { 'o', 'i', 's', 'i', 's', 'i', 'i', 'i', 'i', 'i' },
	GetPlayerCameraTargetDynObject = { 'p' }


}
