--[[
	DataManager
	Módulo servidor para gestionar datos de jugadores.
	Usa ProfileStore para persistencia y ReplicaService para replicación al cliente.

	Ruta: ServerStorage.Modules.DataManager

	API:
		DataManager:Start()                           — Inicializa todo (llamar una vez)
		DataManager:Get(player)                       — Devuelve profile.Data o nil
		DataManager:Update(player, path, value)       — Actualiza valor anidado (ej: "stats.kills")
		DataManager:Increment(player, path, amount)   — Incrementa un valor numérico
]]

local Players = game:GetService("Players")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ProfileStore = require(ReplicatedStorage.Packages.profilestore)
local ReplicaService = require(ReplicatedStorage.Packages.replicaservice)

-- Template compartido
local DataTemplate = require(ReplicatedStorage.Shared.Systems.Data.DataTemplate)

----- Configuración -----

local STORE_NAME = "PlayerData"
local PROFILE_KEY_PREFIX = "Player_"

----- Variables privadas -----

local PlayerDataStore = ProfileStore.New(STORE_NAME, DataTemplate)
local PlayerClassToken = ReplicaService.NewClassToken("PlayerData")

-- Cache de perfiles y réplicas activos
local Profiles = {} -- [Player] = Profile
local Replicas = {} -- [Player] = Replica

local IsInited = false

----- Módulo -----

local DataManager = {}

--------------------------------------------------------------------------------
-- Utilidades internas
--------------------------------------------------------------------------------

--- Dado un path como "stats.kills", devuelve (parentTable, leafKey) en la tabla data.
local function resolvePath(data, path: string)
	local keys = string.split(path, ".")
	local pointer = data
	for i = 1, #keys - 1 do
		pointer = pointer[keys[i]]
		if type(pointer) ~= "table" then
			warn("[DataManager] Path inválido:", path, "- no se encontró:", keys[i])
			return nil, nil
		end
	end
	return pointer, keys[#keys]
end

--------------------------------------------------------------------------------
-- Carga y liberación de perfiles
--------------------------------------------------------------------------------

local function onPlayerAdded(player: Player)
	print("[DataManager] Intentando cargar perfil para:", player.Name)
	local profileKey = PROFILE_KEY_PREFIX .. tostring(player.UserId)

	-- Intentar cargar el perfil con session locking
	local profile = PlayerDataStore:StartSessionAsync(profileKey, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- El jugador se fue antes de que cargara
	if profile == nil then
		warn("[DataManager] StartSessionAsync devolvió nil (posible lock) para:", player.Name)
		player:Kick("[DataManager] No se pudo cargar tu perfil. Inténtalo de nuevo.")
		return
	end

	-- Si el jugador se desconectó mientras cargábamos
	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	-- Reconciliar datos
	profile:Reconcile()
	profile:AddUserId(player.UserId)

	if profile.Data.meta.createdAt == 0 then
		profile.Data.meta.createdAt = os.time()
	end
	profile.Data.meta.updatedAt = os.time()

	profile.OnSessionEnd:Connect(function()
		Profiles[player] = nil
		if Replicas[player] then
			Replicas[player]:Destroy()
			Replicas[player] = nil
		end
		player:Kick("[DataManager] Tu sesión fue reclamada por otro servidor.")
	end)

	Profiles[player] = profile

	local replica = ReplicaService.NewReplica({
		ClassToken = PlayerClassToken,
		Tags = { Player = player },
		Data = profile.Data,
		Replication = player,
	})
	Replicas[player] = replica

	print("[DataManager] Perfil cargado EXITOSAMENTE para", player.Name)
end

local function onPlayerRemoving(player: Player)
	local profile = Profiles[player]
	if profile then
		profile:EndSession()
	end
	if Replicas[player] then
		Replicas[player]:Destroy()
		Replicas[player] = nil
	end
	Profiles[player] = nil
	print("[DataManager] Perfil liberado para", player.Name)
end

--------------------------------------------------------------------------------
-- API Pública
--------------------------------------------------------------------------------

function DataManager:Start()
	if IsInited then return end
	IsInited = true

	print("[DataManager] Iniciando servicio...")

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)

	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	game:BindToClose(function()
		for _, player in Players:GetPlayers() do
			task.spawn(onPlayerRemoving, player)
		end
		task.wait(3)
	end)

	print("[DataManager] Servicio DataManager INICIADO")
end

function DataManager:Get(player: Player)
	if not IsInited then warn("[DataManager] ERROR: DataManager no ha sido iniciado con :Start()") end
	local profile = Profiles[player]
	if profile then return profile.Data end
	return nil
end

function DataManager:Update(player: Player, path: string, value: any)
	if not IsInited then warn("[DataManager] ERROR: DataManager no ha sido iniciado con :Start()") end
	local profile = Profiles[player]
	if not profile then
		warn("[DataManager] Update: perfil no cargado para", player.Name)
		return false
	end
	-- ... (resto igual)

	local parent, key = resolvePath(profile.Data, path)
	if parent == nil then
		return false
	end

	parent[key] = value

	-- Sincronizar con el cliente via Réplica
	local replica = Replicas[player]
	if replica then
		replica:SetValue(path, value)
	end

	return true
end

--- Incrementa un valor numérico en la ruta especificada.
--- Ejemplo: DataManager:Increment(player, "cash", 100)
function DataManager:Increment(player: Player, path: string, amount: number)
	local profile = Profiles[player]
	if not profile then
		warn("[DataManager] Increment: perfil no cargado para", player.Name)
		return false
	end

	local parent, key = resolvePath(profile.Data, path)
	if parent == nil then
		return false
	end

	local currentValue = parent[key]
	if type(currentValue) ~= "number" then
		warn("[DataManager] Increment: el valor en", path, "no es numérico:", type(currentValue))
		return false
	end

	local newValue = currentValue + amount
	parent[key] = newValue

	-- Sincronizar con el cliente
	local replica = Replicas[player]
	if replica then
		replica:SetValue(path, newValue)
	end

	return true
end

--- Obtiene la Réplica de un jugador (para uso avanzado en otros módulos servidor).
function DataManager:GetReplica(player: Player)
	return Replicas[player]
end

--- Devuelve el diccionario completo de perfiles cargados [Player] = Profile.
--- Uso exclusivo para herramientas de admin.
function DataManager:GetAllProfiles()
	return Profiles
end

return DataManager
