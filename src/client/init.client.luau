--[[
	Client Entry Point
	Inicializa todos los módulos del cliente.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Inicializar sistema de datos (cliente)
local DataController = require(ReplicatedStorage.Shared.Systems.Data.DataController)
DataController:Start()

-- Debug: escuchar cualquier cambio de datos (solo en Studio)
local RunService = game:GetService("RunService")
if RunService:IsStudio() then
	DataController:OnRawChange(function(action, pathArray, ...)
		print("[DataController Debug]", action, table.concat(pathArray, "."), ...)
	end)
end

print("[Client] Todos los módulos inicializados")
