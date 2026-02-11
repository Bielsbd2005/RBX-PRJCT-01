--[[
	DataController
	Módulo cliente para acceder a los datos del jugador replicados por el servidor.
	Recibe la Réplica de ReplicaService y expone una API reactiva para la UI.

	Ruta: ReplicatedStorage.Shared.Modules.DataController

	API:
		DataController:Start()                         — Inicializa (llamar una vez desde el cliente)
		DataController:Get(path?)                      — Obtiene un valor (o toda la tabla si no se pasa path)
		DataController:OnChanged(path, callback)       — Escucha cambios en una ruta específica → callback(newValue, oldValue)
		DataController:IsReady()                       — true si la Réplica ya fue recibida
		DataController:OnReady(callback)               — callback() se ejecuta cuando los datos estén listos
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ReplicaController = require(ReplicatedStorage.Packages.replicaservice)

----- Variables privadas -----

local PlayerReplica = nil -- Se llena cuando el servidor replica los datos
local IsDataReady = false

-- Callbacks esperando a que los datos estén listos
local ReadyCallbacks = {}

-- Conexiones de listeners activas (para cleanup si fuera necesario)
local ActiveConnections = {}

----- Módulo -----

local DataController = {}

--------------------------------------------------------------------------------
-- Utilidades internas
--------------------------------------------------------------------------------

--- Dado un path como "stats.kills", navega la tabla data y devuelve el valor.
local function getValueAtPath(data, path: string)
	local keys = string.split(path, ".")
	local pointer = data
	for _, key in keys do
		if type(pointer) ~= "table" then
			return nil
		end
		pointer = pointer[key]
	end
	return pointer
end

--------------------------------------------------------------------------------
-- API Pública
--------------------------------------------------------------------------------

--- Inicializa DataController. Llamar una vez desde un LocalScript.
function DataController:Start()
	-- Escuchar cuando el servidor cree una Réplica de tipo "PlayerData" para nosotros
	ReplicaController.ReplicaOfClassCreated("PlayerData", function(replica)
		PlayerReplica = replica

		print("[DataController] Réplica recibida — datos listos")

		-- Marcar como listo y ejecutar callbacks pendientes
		IsDataReady = true
		for _, callback in ReadyCallbacks do
			task.spawn(callback)
		end
		table.clear(ReadyCallbacks)

		-- Cleanup cuando la réplica sea destruida (ej: kick por session stealing)
		replica:AddCleanupTask(function()
			PlayerReplica = nil
			IsDataReady = false
			-- Desconectar todos los listeners
			for _, connection in ActiveConnections do
				connection:Disconnect()
			end
			table.clear(ActiveConnections)
			print("[DataController] Réplica destruida — datos no disponibles")
		end)
	end)

	-- Pedir datos al servidor (DEBE llamarse DESPUÉS de conectar ReplicaOfClassCreated)
	ReplicaController.RequestData()

	print("[DataController] Inicializado — esperando datos del servidor...")
end

--- Obtiene datos del jugador.
--- Si no se pasa path, devuelve toda la tabla. Si se pasa, navega a esa ruta.
--- @param path string? — Ruta con puntos, ej: "stats.kills", "cash", "inventory.Weapons"
--- @return any — El valor en esa ruta, o nil si no está listo
function DataController:Get(path: string?)
	if not PlayerReplica then
		return nil
	end

	if path == nil or path == "" then
		return PlayerReplica.Data
	end

	return getValueAtPath(PlayerReplica.Data, path)
end

--- Registra un callback que se ejecuta cada vez que el valor en `path` cambia.
--- Devuelve una conexión que puede desconectarse con :Disconnect()
--- @param path string — Ruta con puntos, ej: "cash", "stats.kills"
--- @param callback function — callback(newValue, oldValue)
--- @return ScriptConnection
function DataController:OnChanged(path: string, callback: (newValue: any, oldValue: any) -> ())
	if PlayerReplica then
		local connection = PlayerReplica:ListenToChange(path, callback)
		table.insert(ActiveConnections, connection)
		return connection
	end

	-- Si la réplica aún no llegó, almacenar para conectar después
	local pendingConnection = nil

	local function connectWhenReady()
		if PlayerReplica then
			pendingConnection = PlayerReplica:ListenToChange(path, callback)
			table.insert(ActiveConnections, pendingConnection)
		end
	end

	if IsDataReady then
		connectWhenReady()
	else
		table.insert(ReadyCallbacks, connectWhenReady)
	end

	-- Devolver un wrapper que permite desconectar incluso antes de estar listo
	return {
		Disconnect = function()
			if pendingConnection then
				pendingConnection:Disconnect()
			end
		end,
	}
end

--- ¿Los datos ya están disponibles?
function DataController:IsReady(): boolean
	return IsDataReady
end

--- Ejecuta callback cuando los datos estén listos (inmediatamente si ya lo están).
function DataController:OnReady(callback: () -> ())
	if IsDataReady then
		task.spawn(callback)
	else
		table.insert(ReadyCallbacks, callback)
	end
end

--- Escucha CUALQUIER cambio en la réplica (útil para debugging).
--- callback(actionName, pathArray, params...)
function DataController:OnRawChange(callback)
	if PlayerReplica then
		local connection = PlayerReplica:ListenToRaw(callback)
		table.insert(ActiveConnections, connection)
		return connection
	end

	local pendingConnection = nil
	local function connectWhenReady()
		if PlayerReplica then
			pendingConnection = PlayerReplica:ListenToRaw(callback)
			table.insert(ActiveConnections, pendingConnection)
		end
	end

	if IsDataReady then
		connectWhenReady()
	else
		table.insert(ReadyCallbacks, connectWhenReady)
	end

	return {
		Disconnect = function()
			if pendingConnection then
				pendingConnection:Disconnect()
			end
		end,
	}
end

return DataController
