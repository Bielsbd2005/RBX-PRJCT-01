--[[
	ItemsDataUtils
	Utility functions for querying ItemsData and player data.
	Consolidates ownership checks, level-lock checks, and item lookups
	previously duplicated 4× across LockerUI.

	Ruta: ReplicatedStorage.Shared.ItemsDataUtils
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemsDataUtils = {}

-- Lazy-load ItemsData to avoid circular dependency
local _itemsData = nil
local function getItemsData()
	if not _itemsData then
		_itemsData = require(ReplicatedStorage.Shared.ItemsData)
	end
	return _itemsData
end

--------------------------------------------------------------------------------
-- Find an item by name within a category/section
-- e.g. findByName("Arsenal", "WeaponSkins", "PinkDream")
--------------------------------------------------------------------------------
function ItemsDataUtils.findByName(category: string, section: string, name: string): { [string]: any }?
	if not name or name == "" then return nil end

	local data = getItemsData()
	local categoryData = data[category]
	if not categoryData then return nil end

	local sectionData = categoryData[section]
	if not sectionData then return nil end

	for _, item in sectionData do
		if item.Name == name then
			return item
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- Check if a player owns an item (includes "Default" special case)
--------------------------------------------------------------------------------
function ItemsDataUtils.isItemOwned(playerData: { [string]: any }, section: string, itemName: string): boolean
	if itemName == "Default" then return true end
	if not playerData or not playerData.inventory then return false end

	local categoryInv = playerData.inventory[section]
	if not categoryInv then return false end

	for _, ownedName in categoryInv do
		if ownedName == itemName then
			return true
		end
	end

	return false
end

--------------------------------------------------------------------------------
-- Check if an item is locked by level requirement
--------------------------------------------------------------------------------
function ItemsDataUtils.isLevelLocked(item: { [string]: any }, playerData: { [string]: any }): boolean
	local requiredLevel = item.Level or 0
	local playerLevel = (playerData and playerData.level) or 0

	return requiredLevel > 0 and playerLevel < requiredLevel
end

return ItemsDataUtils
