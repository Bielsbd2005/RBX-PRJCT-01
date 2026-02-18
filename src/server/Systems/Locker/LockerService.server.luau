--[[
	ShopService
	Servicio servidor para gestionar la tienda y el inventario.
	Maneja compras y equipamiento de items.

	Ruta: ServerScriptService.Server.ShopService
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")


local DataManager = require(game:GetService("ServerScriptService").Server.Systems.Data.DataManager)

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

-- Comprar un item
local buyItemRF = shopFolder:FindFirstChild("BuyItem") or Instance.new("RemoteFunction")
buyItemRF.Name = "BuyItem"
buyItemRF.Parent = shopFolder

local ItemsData = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Systems"):WaitForChild("Locker"):WaitForChild("Data"):WaitForChild("ItemsData"))

buyItemRF.OnServerInvoke = function(player: Player, tab: string, category: string, itemName: string)
	if type(tab) ~= "string" or type(category) ~= "string" or type(itemName) ~= "string" then
		return false, "Argumentos inválidos"
	end

	local data = DataManager:Get(player)
	if not data then return false, "Datos no cargados" end

	-- 1. Validar item existe en ItemsData
	local tabData = ItemsData[tab]
	if not tabData then return false, "Tab no existe" end

	local categoryData = tabData[category]
	if not categoryData then return false, "Categoría no existe" end

	local itemStats = nil
	for _, item in categoryData do
		if item.Name == itemName then
			itemStats = item
			break
		end
	end

	if not itemStats then return false, "Item no existe" end

	-- 2. Validar que NO lo tiene
	local inventory = data.inventory[category] or {}
	for _, owned in inventory do
		if owned == itemName then
			return false, "Ya tienes este item"
		end
	end

	-- 3. Validar precio y dinero
	local price = itemStats.Price or 0
	local playerMoney = data.cash or 0

	if playerMoney < price then
		return false, "Dinero insuficiente"
	end

	-- 4. Validar Nivel
	local requiredLevel = itemStats.Level or 0
	local playerLevel = data.level or 0
	if requiredLevel > 0 and playerLevel < requiredLevel then
		return false, "Nivel insuficiente"
	end

	-- REALIZAR TRANSACCIÓN

	-- Restar dinero
	local newMoney = playerMoney - price
	DataManager:Update(player, "cash", newMoney)

	-- Añadir a inventario
	-- DataManager update para arrays podría ser complicado si no soportan push.
	-- Asumimos que debemos pasar la tabla entera nueva.
	local newInventory = table.clone(inventory)
	table.insert(newInventory, itemName)
	DataManager:Update(player, "inventory." .. category, newInventory)

	return true, "Compra exitosa"
end

print("[ShopService] Servicio de tienda iniciado")
