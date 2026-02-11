print("[Server] Init script starting...")
--[[
	Server Entry Point
	Inicializa todos los módulos del servidor.
]]

local ServerStorage = game:GetService("ServerStorage")

-- Inicializar sistema de datos
local DataManager = require(ServerStorage.Modules.DataManager)
DataManager:Start()

print("[Server] Todos los módulos inicializados")
