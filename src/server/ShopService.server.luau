--[[
	ShopService
	Servicio servidor para gestionar la tienda y el inventario.
	Maneja compras y equipamiento de items.

	Ruta: ServerScriptService.Server.ShopService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local DataManager = require(ServerStorage.Modules.DataManager)

-- Crear carpeta para Remotes si no existe
local shopFolder = ReplicatedStorage:FindFirstChild("Shop") or Instance.new("Folder")
shopFolder.Name = "Shop"
shopFolder.Parent = ReplicatedStorage

----- RemoteFunctions -----

-- Equipar un item
local equipItemRF = shopFolder:FindFirstChild("EquipItem") or Instance.new("RemoteFunction")
equipItemRF.Name = "EquipItem"
equipItemRF.Parent = shopFolder

equipItemRF.OnServerInvoke = function(player: Player, category: string, itemName: string)
	if type(category) ~= "string" or type(itemName) ~= "string" then
		return false, "Argumentos inválidos"
	end

	local data = DataManager:Get(player)
	if not data then return false, "Datos no cargados" end

	-- Verificar que la categoría existe en inventory
	if not data.inventory[category] then
		return false, "Categoría inválida: " .. category
	end

	-- Verificar propiedad (es un array de nombres)
	local isOwned = false
	for _, ownedName in data.inventory[category] do
		if ownedName == itemName then
			isOwned = true
			break
		end
	end

	-- Hack temporal: Default siempre es owned
	if not isOwned and itemName == "Default" then
		isOwned = true
	end

	if not isOwned then
		return false, "No tienes este item"
	end

	-- Actualizar equipado
	local success = DataManager:Update(player, "equipped." .. category, itemName)
	if success then
		return true, "Equipado"
	else
		return false, "Error al guardar"
	end
end

print("[ShopService] Servicio de tienda iniciado")
