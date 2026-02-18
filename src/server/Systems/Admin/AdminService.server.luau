--[[
	AdminService
	Script del servidor que gestiona las peticiones de la consola de administrador.
	Solo responde a jugadores cuyo UserId esté en ADMIN_IDS.

	Ruta: ServerScriptService.Server.AdminService
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")


local DataManager = require(game:GetService("ServerScriptService").Server.Systems.Data.DataManager)

----- Configuración -----

-- Añade aquí los UserIds con permisos de admin
local ADMIN_IDS: { number } = {
	286176976,
}

----- Utilidades -----

local function isAdmin(player: Player): boolean
	for _, id in ADMIN_IDS do
		if player.UserId == id then
			return true
		end
	end
	return false
end

--- Serializa los datos del jugador para enviarlos al cliente.
--- Convierte tablas anidadas de forma segura.
local function deepCopy(value: any): any
	if type(value) == "table" then
		local copy = {}
		for k, v in value do
			copy[k] = deepCopy(v)
		end
		return copy
	end
	return value
end

----- RemoteFunctions -----

-- Carpeta contenedora
local adminFolder = Instance.new("Folder")
adminFolder.Name = "AdminConsole"
adminFolder.Parent = ReplicatedStorage

-- RF: Verificar si el jugador es admin
local isAdminRF = Instance.new("RemoteFunction")
isAdminRF.Name = "IsAdmin"
isAdminRF.Parent = adminFolder

isAdminRF.OnServerInvoke = function(player: Player)
	return isAdmin(player)
end

-- RF: Obtener lista de jugadores con resumen de datos
local getPlayersRF = Instance.new("RemoteFunction")
getPlayersRF.Name = "GetPlayers"
getPlayersRF.Parent = adminFolder

getPlayersRF.OnServerInvoke = function(player: Player)
	if not isAdmin(player) then
		warn("[AdminService] Acceso denegado a", player.Name)
		return {}
	end

	local result = {}
	for _, p in Players:GetPlayers() do
		local data = DataManager:Get(p)
		table.insert(result, {
			UserId = p.UserId,
			Name = p.Name,
			DisplayName = p.DisplayName,
			HasData = data ~= nil,
		})
	end
	return result
end

-- RF: Obtener datos completos de un jugador
local getPlayerDataRF = Instance.new("RemoteFunction")
getPlayerDataRF.Name = "GetPlayerData"
getPlayerDataRF.Parent = adminFolder

getPlayerDataRF.OnServerInvoke = function(player: Player, targetUserId: number)
	if not isAdmin(player) then
		warn("[AdminService] Acceso denegado a", player.Name)
		return nil
	end

	-- Buscar al jugador por UserId
	local targetPlayer = nil
	for _, p in Players:GetPlayers() do
		if p.UserId == targetUserId then
			targetPlayer = p
			break
		end
	end

	if not targetPlayer then
		return nil
	end

	local data = DataManager:Get(targetPlayer)
	if not data then
		return nil
	end

	return deepCopy(data)
end

-- RF: Actualizar un campo de datos de un jugador
local updateDataRF = Instance.new("RemoteFunction")
updateDataRF.Name = "UpdateData"
updateDataRF.Parent = adminFolder

updateDataRF.OnServerInvoke = function(player: Player, targetUserId: number, path: string, newValue: any)
	if not isAdmin(player) then
		warn("[AdminService] Acceso denegado a", player.Name)
		return false, "Acceso denegado"
	end

	-- Validar inputs
	if type(targetUserId) ~= "number" then
		return false, "UserId inválido"
	end
	if type(path) ~= "string" or path == "" then
		return false, "Path inválido"
	end

	-- Buscar al jugador
	local targetPlayer = nil
	for _, p in Players:GetPlayers() do
		if p.UserId == targetUserId then
			targetPlayer = p
			break
		end
	end

	if not targetPlayer then
		return false, "Jugador no encontrado"
	end

	local success = DataManager:Update(targetPlayer, path, newValue)
	if success then
		print("[AdminService]", player.Name, "actualizó", path, "=", tostring(newValue), "para", targetPlayer.Name)
		return true, "OK"
	else
		return false, "Error al actualizar"
	end
end

-- RF: Resetear todos los datos de un jugador al default
local resetDataRF = Instance.new("RemoteFunction")
resetDataRF.Name = "ResetData"
resetDataRF.Parent = adminFolder

resetDataRF.OnServerInvoke = function(player: Player, targetUserId: number)
	if not isAdmin(player) then
		warn("[AdminService] Acceso denegado a", player.Name)
		return false, "Acceso denegado"
	end

	-- Buscar al jugador
	local targetPlayer = nil
	for _, p in Players:GetPlayers() do
		if p.UserId == targetUserId then
			targetPlayer = p
			break
		end
	end

	if not targetPlayer then
		return false, "Jugador no encontrado"
	end

	-- Obtener el template por defecto
	local DataTemplate = require(ReplicatedStorage.Shared.Systems.Data.DataTemplate)

	-- Iterar y resetear cada clave principal para mantener la estructura
	-- Usamos DataManager:Update para asegurar replicación y validación
	for key, defaultValue in DataTemplate do
		DataManager:Update(targetPlayer, key, deepCopy(defaultValue))
	end

	print("[AdminService]", player.Name, "trazó RESET FULL DATA para", targetPlayer.Name)
	return true, "Datos reseteados al default"
end

print("[AdminService] Servicio de administrador cargado")
