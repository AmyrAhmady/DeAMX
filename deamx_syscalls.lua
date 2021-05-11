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


	Streamer_GetTickRate = {},
	Streamer_SetTickRate = { 'i'}, 
	Streamer_GetPlayerTickRate = { 'p'}, 
	Streamer_SetPlayerTickRate = { 'p', 'i'}, 
	Streamer_ToggleChunkStream = { 'i'}, 
	Streamer_IsToggleChunkStream = {},
	Streamer_GetChunkTickRate = { 'i', 'i'}, 
	Streamer_SetChunkTickRate = { 'i', 'i', 'i'}, 
	Streamer_GetChunkSize = { 'i'}, 
	Streamer_SetChunkSize = { 'i', 'i'}, 
	Streamer_GetMaxItems = { 'i'}, 
	Streamer_SetMaxItems = { 'i', 'i'}, 
	Streamer_GetVisibleItems = { 'i', 'i'}, 
	Streamer_SetVisibleItems = { 'i', 'i', 'i'}, 
	Streamer_GetRadiusMultiplier = { 'i', 'f', 'i'}, 
	Streamer_SetRadiusMultiplier = { 'i', 'f', 'i'}, 
	Streamer_GetTypePriority = { 'i', 'i'}, 
	Streamer_SetTypePriority = { 'i', 'i'}, 
	Streamer_GetCellDistance = { 'f'}, 
	Streamer_SetCellDistance = { 'f'}, 
	Streamer_GetCellSize = { 'f'}, 
	Streamer_SetCellSize = { 'f'}, 
	Streamer_ToggleItemStatic = { 'i', 'i', 'i'}, 
	Streamer_IsToggleItemStatic = { 'i', 'i'}, 
	Streamer_ToggleItemInvAreas = { 'i', 'i', 'i'}, 
	Streamer_IsToggleItemInvAreas = { 'i', 'i'}, 
	Streamer_ToggleItemCallbacks = { 'i', 'i', 'i'}, 
	Streamer_IsToggleItemCallbacks = { 'i', 'i'}, 
	Streamer_ToggleErrorCallback = { 'i'}, 
	Streamer_IsToggleErrorCallback = {},
	Streamer_AmxUnloadDestroyItems = { 'i'}, 
	Streamer_ProcessActiveItems = {},
	Streamer_ToggleIdleUpdate = { 'p', 'i'}, 
	Streamer_IsToggleIdleUpdate = { 'p'}, 
	Streamer_ToggleCameraUpdate = { 'p', 'i'}, 
	Streamer_IsToggleCameraUpdate = { 'p'}, 
	Streamer_ToggleItemUpdate = { 'p', 'i', 'i'}, 
	Streamer_IsToggleItemUpdate = { 'p', 'i'}, 
	Streamer_GetLastUpdateTime = { 'f'}, 
	Streamer_Update = { 'p', 'i'}, 
	Streamer_UpdateEx = { 'p', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i'}, 
	Streamer_GetFloatData = { 'i', 'i', 'i', 'f'}, 
	Streamer_SetFloatData = { 'i', 'i', 'i', 'f'}, 
	Streamer_GetIntData = { 'i', 'i', 'i'}, 
	Streamer_SetIntData = { 'i', 'i', 'i', 'i'}, 
	Streamer_GetArrayData = { 'i', 'i', 'i', 'i', 'i'}, 
	Streamer_SetArrayData = { 'i', 'i', 'i', 'i', 'i'}, 
	Streamer_IsInArrayData = { 'i', 'i', 'i', 'i'}, 
	Streamer_AppendArrayData = { 'i', 'i', 'i', 'i'}, 
	Streamer_RemoveArrayData = { 'i', 'i', 'i', 'i'}, 
	Streamer_GetArrayDataLength = { 'i', 'i', 'i'}, 
	Streamer_GetUpperBound = { 'i'}, 
	Streamer_GetDistanceToItem = { 'f', 'f', 'f', 'i', 'i', 'f', 'i'}, 
	Streamer_ToggleItem = { 'p', 'i', 'i', 'i'}, 
	Streamer_IsToggleItem = { 'p', 'i', 'i'}, 
	Streamer_ToggleAllItems = { 'p', 'i', 'i', 'i', 'i'}, 
	Streamer_GetItemInternalID = { 'p', 'i', 'i'}, 
	Streamer_GetItemStreamerID = { 'p', 'i', 'i'}, 
	Streamer_IsItemVisible = { 'p', 'i', 'i'}, 
	Streamer_DestroyAllVisibleItems = { 'p', 'i', 'i'}, 
	Streamer_CountVisibleItems = { 'p', 'i', 'i'}, 
	Streamer_DestroyAllItems = { 'i', 'i'}, 
	Streamer_CountItems = { 'i', 'i'}, 
	Streamer_GetNearbyItems = { 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'i'}, 
	Streamer_GetAllVisibleItems = { 'p', 'i', 'i', 'i'}, 
	Streamer_GetItemPos = { 'i', 'i', 'f', 'f', 'f'}, 
	Streamer_SetItemPos = { 'i', 'i', 'f', 'f', 'f'}, 
	Streamer_GetItemOffset = { 'i', 'i', 'f', 'f', 'f'}, 
	Streamer_SetItemOffset = { 'i', 'i', 'f', 'f', 'f'}, 
	CreateDynamicObject = { 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'f', 'i', 'i'}, 
	DestroyDynamicObject = { 'i'}, 
	IsValidDynamicObject = { 'i'}, 
	GetDynamicObjectPos = { 'i', 'f', 'f', 'f'}, 
	SetDynamicObjectPos = { 'i', 'f', 'f', 'f'}, 
	GetDynamicObjectRot = { 'i', 'f', 'f', 'f'}, 
	SetDynamicObjectRot = { 'i', 'f', 'f', 'f'}, 
	GetDynamicObjectNoCameraCol = { 'i'}, 
	SetDynamicObjectNoCameraCol = { 'i'}, 
	MoveDynamicObject = { 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f'}, 
	StopDynamicObject = { 'i'}, 
	IsDynamicObjectMoving = { 'i'}, 
	AttachCameraToDynamicObject = { 'p', 'i'}, 
	AttachDynamicObjectToObject = { 'i', 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'i'}, 
	AttachDynamicObjectToPlayer = { 'i', 'p', 'f', 'f', 'f', 'f', 'f', 'f'}, 
	AttachDynamicObjectToVehicle = { 'i', 'v', 'f', 'f', 'f', 'f', 'f', 'f'}, 
	EditDynamicObject = { 'p', 'i'}, 
	IsDynamicObjectMaterialUsed = { 'i', 'i'}, 
	GetDynamicObjectMaterial = { 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	SetDynamicObjectMaterial = { 'i', 'i', 'i', 'i', 'i', 'i'}, 
	IsDynamicObjectMaterialTextUsed = { 'i', 'i'}, 
	GetDynamicObjectMaterialText = { 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	SetDynamicObjectMaterialText = { 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	GetPlayerCameraTargetDynObject = { 'p'}, 
	CreateDynamicPickup = { 'i', 'i', 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'i', 'i'}, 
	DestroyDynamicPickup = { 'i'}, 
	IsValidDynamicPickup = { 'i'}, 
	CreateDynamicCP = { 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'i', 'i'}, 
	DestroyDynamicCP = { 'i'}, 
	IsValidDynamicCP = { 'i'}, 
	IsPlayerInDynamicCP = { 'p', 'i'}, 
	GetPlayerVisibleDynamicCP = { 'p'}, 
	CreateDynamicRaceCP = { 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'i', 'i'}, 
	DestroyDynamicRaceCP = { 'i'}, 
	IsValidDynamicRaceCP = { 'i'}, 
	IsPlayerInDynamicRaceCP = { 'p', 'i'}, 
	GetPlayerVisibleDynamicRaceCP = { 'p'}, 
	CreateDynamicMapIcon = { 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'f', 'i', 'i', 'i'}, 
	DestroyDynamicMapIcon = { 'i'}, 
	IsValidDynamicMapIcon = { 'i'}, 
	CreateDynamic3DTextLabel = { 'i', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'f', 'i', 'i'}, 
	DestroyDynamic3DTextLabel = { 'i'}, 
	IsValidDynamic3DTextLabel = { 'i'}, 
	GetDynamic3DTextLabelText = { 'i', 'i', 'i'}, 
	UpdateDynamic3DTextLabelText = { 'i', 'i', 'i'}, 
	CreateDynamicCircle = { 'f', 'f', 'f', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCylinder = { 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'}, 
	CreateDynamicSphere = { 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'}, 
	CreateDynamicRectangle = { 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCuboid = { 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCube = { 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i'}, 
	CreateDynamicPolygon = { 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i'}, 
	DestroyDynamicArea = { 'i'}, 
	IsValidDynamicArea = { 'i'}, 
	GetDynamicAreaType = { 'i'}, 
	GetDynamicPolygonPoints = { 'i', 'f', 'i'}, 
	GetDynamicPolygonNumberPoints = { 'i'}, 
	IsPlayerInDynamicArea = { 'p', 'i', 'i'}, 
	IsPlayerInAnyDynamicArea = { 'p', 'i'}, 
	IsAnyPlayerInDynamicArea = { 'i', 'i'}, 
	IsAnyPlayerInAnyDynamicArea = { 'i'}, 
	GetPlayerDynamicAreas = { 'p', 'i', 'i'}, 
	GetPlayerNumberDynamicAreas = { 'p'}, 
	IsPointInDynamicArea = { 'i', 'f', 'f', 'f'}, 
	IsPointInAnyDynamicArea = { 'f', 'f', 'f'}, 
	IsLineInDynamicArea = { 'i', 'f', 'f', 'f', 'f', 'f', 'f'}, 
	IsLineInAnyDynamicArea = { 'f', 'f', 'f', 'f', 'f', 'f'}, 
	GetDynamicAreasForPoint = { 'f', 'f', 'f', 'i', 'i'}, 
	GetNumberDynamicAreasForPoint = { 'f', 'f', 'f'}, 
	GetDynamicAreasForLine = { 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i'}, 
	GetNumberDynamicAreasForLine = { 'f', 'f', 'f', 'f', 'f', 'f'}, 
	AttachDynamicAreaToObject = { 'i', 'i', 'i', 'i', 'f', 'f', 'f'}, 
	AttachDynamicAreaToPlayer = { 'i', 'p', 'f', 'f', 'f'}, 
	AttachDynamicAreaToVehicle = { 'i', 'v', 'f', 'f', 'f'}, 
	ToggleDynAreaSpectateMode = { 'i', 'i'}, 
	IsToggleDynAreaSpectateMode = { 'i'}, 
	CreateDynamicActor = { 'i', 'f', 'f', 'f', 'f', 'i', 'f', 'i', 'i', 'i', 'f', 'i', 'i'}, 
	DestroyDynamicActor = { 'i'}, 
	IsValidDynamicActor = { 'i'}, 
	IsDynamicActorStreamedIn = { 'i', 'i'}, 
	GetDynamicActorVirtualWorld = { 'i'}, 
	SetDynamicActorVirtualWorld = { 'i', 'i'}, 
	GetDynamicActorAnimation = { 'i', 'i', 'i', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	ApplyDynamicActorAnimation = { 'i', 'i', 'i', 'f', 'i', 'i', 'i', 'i', 'i'}, 
	ClearDynamicActorAnimations = { 'i'}, 
	GetDynamicActorFacingAngle = { 'i', 'f'}, 
	SetDynamicActorFacingAngle = { 'i', 'f'}, 
	GetDynamicActorPos = { 'i', 'f', 'f', 'f'}, 
	SetDynamicActorPos = { 'i', 'f', 'f', 'f'}, 
	GetDynamicActorHealth = { 'i', 'f'}, 
	SetDynamicActorHealth = { 'i', 'f'}, 
	SetDynamicActorInvulnerable = { 'i', 'i'}, 
	IsDynamicActorInvulnerable = { 'i'}, 
	GetPlayerTargetDynamicActor = { 'p'}, 
	GetPlayerCameraTargetDynActor = { 'p'}, 
	CreateDynamicObjectEx = { 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicPickupEx = { 'i', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCPEx = { 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicRaceCPEx = { 'i', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicMapIconEx = { 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamic3DTextLabelEx = { 'i', 'i', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCircleEx = { 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCylinderEx = { 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicSphereEx = { 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicRectangleEx = { 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCuboidEx = { 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicCubeEx = { 'f', 'f', 'f', 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicPolygonEx = { 'f', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	CreateDynamicActorEx = { 'i', 'f', 'f', 'f', 'f', 'i', 'f', 'f', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i', 'i'}, 
	Streamer_CallbackHook = { 'i', 'i', 'i'}, 
	Streamer_TickRate = { 'i'}, 
	Streamer_MaxItems = { 'i', 'i'}, 
	Streamer_VisibleItems = { 'i', 'i', 'i'}, 
	Streamer_CellDistance = { 'f'}, 
	Streamer_CellSize = { 'f'}, 
	DestroyAllDynamicObjects = {},
	CountDynamicObjects = {},
	DestroyAllDynamicPickups = {},
	CountDynamicPickups = {},
	DestroyAllDynamicCPs = {},
	CountDynamicCPs = {},
	DestroyAllDynamicRaceCPs = {},
	CountDynamicRaceCPs = {},
	DestroyAllDynamicMapIcons = {},
	CountDynamicMapIcons = {},
	DestroyAllDynamic3DTextLabels = {},
	CountDynamic3DTextLabels = {},
	DestroyAllDynamicAreas = {},
	CountDynamicAreas = {},
	TogglePlayerDynamicCP = { 'p', 'i', 'i'}, 
	TogglePlayerAllDynamicCPs = { 'p', 'i', 'i', 'i'}, 
	TogglePlayerDynamicRaceCP = { 'p', 'i', 'i'}, 
	TogglePlayerAllDynamicRaceCPs = { 'p', 'i', 'i', 'i'}, 
	TogglePlayerDynamicArea = { 'p', 'i', 'i'}, 
	TogglePlayerAllDynamicAreas = { 'p', 'i', 'i', 'i'}

}
