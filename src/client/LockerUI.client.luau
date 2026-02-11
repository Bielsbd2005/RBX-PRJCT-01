--[[
	Locker
	Script principal de la Locker GUI.
	Orquesta todos los componentes y gestiona el estado de la tienda.

	Ruta: StarterPlayerScripts > Client > LockerUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Fusion 0.3 imports
local Fusion = require(ReplicatedStorage.Packages.fusion)
local scoped = Fusion.scoped
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local peek = Fusion.peek

-- Componentes
local NavButton = require(script.Parent.Components.NavButton)
local ItemCard = require(script.Parent.Components.ItemCard)
local CloseButton = require(script.Parent.Components.CloseButton)
local TabButton = require(script.Parent.Components.TabButton)
local Constants = require(script.Parent.Components.StoreConstants)

-- Jugador local
local player = Players.LocalPlayer

--------------------------------------------------------------------------------
-- Scope principal (gestiona la memoria de toda la UI)
--------------------------------------------------------------------------------
local scope = scoped(Fusion)

--------------------------------------------------------------------------------
-- Estado reactivo
--------------------------------------------------------------------------------
local isStoreOpen = Value(scope, false)

-- Remotes
local shopFolder = ReplicatedStorage:WaitForChild("Shop", 10)
local equipItemRF = shopFolder and shopFolder:WaitForChild("EquipItem", 10)

-- Tab y opción seleccionados
local selectedTab = Value(scope, "Arsenal")
local selectedOption = Value(scope, "Weapons")

-- Resolución de referencia (la UI se diseñó en 1920x1080)
local REFERENCE_WIDTH = 1920
local REFERENCE_HEIGHT = 1080

-- Escala dinámica según viewport
local camera = workspace.CurrentCamera
local viewportSize = Value(scope, camera.ViewportSize)

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	viewportSize:set(camera.ViewportSize)
end)

local uiScale = Computed(scope, function(use)
	local viewport = use(viewportSize)
	local scaleX = viewport.X / REFERENCE_WIDTH
	local scaleY = viewport.Y / REFERENCE_HEIGHT
	return math.min(scaleX, scaleY)
end)

-- Gestor de Cámaras
local CameraManager = require(ReplicatedStorage.Shared.Modules.Camera.CameraManager)
local EffectsManager = require(script.Parent.Modules.EffectsManager)

--------------------------------------------------------------------------------
-- Funciones
--------------------------------------------------------------------------------
local function setStoreState(isOpen)
	isStoreOpen:set(isOpen)

	if isOpen then
		-- ABRIR
		local cameraPart = workspace:WaitForChild("Cameras"):FindFirstChild("Locker")
		if cameraPart then
			CameraManager.setTarget(cameraPart, true, nil, 10)
		end
	else
		-- CERRAR
		task.spawn(function()
			EffectsManager.fadeToBlack(0.2)
			CameraManager.reset(true) -- Instantáneo
			EffectsManager.fadeFromBlack(0.2)
		end)
	end
end

local function toggleStore()
	setStoreState(not peek(isStoreOpen))
end

local function closeStore()
	if peek(isStoreOpen) then
		setStoreState(false)
	end
end

--------------------------------------------------------------------------------
-- Selección de tab
--------------------------------------------------------------------------------
local function selectTab(tabName: string)
	selectedTab:set(tabName)
	-- Resetear la opción a la primera del nuevo tab
	local options = Constants.NavOptions[tabName]
	if options and options[1] then
		selectedOption:set(options[1].Name)
	end
end

--------------------------------------------------------------------------------
-- Navegación lateral (Option buttons) — generados dinámicamente
--------------------------------------------------------------------------------
local function createNavSection(scope: Fusion.Scope<typeof(Fusion)>)
	-- Children reactivos que cambian cuando cambia el tab seleccionado
	local navChildren = Computed(scope, function(use)
		local tabName = use(selectedTab)
		local options = Constants.NavOptions[tabName] or {}
		local children = {}

		-- UIListLayout siempre presente
		table.insert(children, scope:New "UIListLayout" {
			Name = "UIListLayout",
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0.08, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		for i, optionData in options do
			local optName = optionData.Name
			table.insert(children, NavButton(scope, {
				name = optName,
				title = optionData.Title or optName,
				image = optionData.Image,
				layoutOrder = i,
				isSelected = Computed(scope, function(use)
					return use(selectedOption) == optName
				end),
				onClick = function()
					selectedOption:set(optName)
				end,
			}))
		end

		return children
	end)

	return scope:New "Frame" {
		Name = "Nav",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.574, 0.22),
		Size = UDim2.fromScale(0.052, 0.308),

		[Children] = navChildren,
	}
end

--------------------------------------------------------------------------------
-- Grid de items (ScrollingFrame con tarjetas)
--------------------------------------------------------------------------------
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)
local DataController = require(ReplicatedStorage.Shared.Modules.DataController)

local function createItemGrid(scope: Fusion.Scope<typeof(Fusion)>)
	-- Estado reactivo de los datos del jugador
	local playerData = Value(scope, DataController:Get() or {})

	-- Escuchar cambios en los datos (simplificado: cualquier cambio actualiza todo por ahora)
	-- Idealmente escucharíamos solo inventory/equipped, pero DataController:OnChanged es por path específico.
	-- Para asegurar consistencia rápida, usamos OnRawChange o un polling/evento si fuera necesario.
	-- Dado que DataController tiene OnRawChange, usémoslo para mantener sincronía.

	-- Carga inicial si los datos ya están listos o cuando lo estén
	DataController:OnReady(function()
		playerData:set(DataController:Get())
	end)

	local conn = DataController:OnRawChange(function()
		playerData:set(DataController:Get())
	end)

	-- Limpieza al destruir el scope (aunque en este script LockerUI vive siempre, es buena práctica)
	table.insert(scope, {
		Destroy = function()
			conn.Disconnect()
		end
	})

	-- Lista de items reactiva según tab/opción
	local currentItems = Computed(scope, function(use)
		local tab = use(selectedTab)
		local option = use(selectedOption)

		local categoryData = ItemsData[tab]
		if not categoryData then return {} end

		local optionData = categoryData[option]
		if not optionData then return {} end

		return optionData
	end)

	local itemCards = Computed(scope, function(use)
		local items = use(currentItems)
		local data = use(playerData)
		local _currentTab = use(selectedTab)   -- "Cosmetics" (Unused but kept for reactivity if needed, prefixed with _)
		local currentOption = use(selectedOption) -- "Faces"

		local cards = {}

		-- UIListLayout / UIGridLayout siempre necesario
		table.insert(cards, scope:New "UIGridLayout" {
			Name = "UIGridLayout",
			CellPadding = UDim2.fromScale(0.04, 0.03),
			CellSize = UDim2.fromScale(0.3, 0.27),
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		table.insert(cards, scope:New "UIPadding" {
			Name = "UIPadding",
			PaddingBottom = UDim.new(0, 25),
			PaddingLeft = UDim.new(0, 25),
			PaddingRight = UDim.new(0, 25),
			PaddingTop = UDim.new(0.006, 0),
		})

		-- Helper para verificar propiedad
		local function checkOwnership(itemName: string): boolean
			if not data.inventory then return false end
			local categoryInv = data.inventory[currentOption] -- e.g. inventory.Faces
			if not categoryInv then return false end

			-- Si es una lista de strings (nombres)
			for _, ownedName in categoryInv do
				if ownedName == itemName then
					return true
				end
			end
			return false
		end

		-- Helper para verificar equipado
		local function checkEquipped(itemName: string): boolean
			if not data.equipped then return false end
			local equippedItem = data.equipped[currentOption] -- e.g. equipped.Faces
			return equippedItem == itemName
		end

		for i, item in items do
			local isOwned = checkOwnership(item.Name)
			local isEquipped = checkEquipped(item.Name)

			-- Hack temporal por si el Inventory no tiene "Default" explícito en listas vacías
			if item.Name == "Default" then isOwned = true end

			-- Pre-calcular estado para ordenamiento estable luego si es necesario
			item._isOwned = isOwned
			item._isEquipped = isEquipped
		end

		-- Clonar y ordenar
		local sortedItems = table.clone(items)
		table.sort(sortedItems, function(a, b)
			-- 1. Dueño primero
			if a._isOwned ~= b._isOwned then
				return a._isOwned -- true > false
			end

			-- 2. Por precio (menor a mayor)
			if a.Price ~= b.Price then
				return a.Price < b.Price
			end

			-- 3. Fallback por nombre
			return a.Name < b.Name
		end)

		for i, item in sortedItems do
			local isOwned = item._isOwned
			local isEquipped = item._isEquipped

			-- Verificar bloqueo por nivel
			local requiredLevel = item.Level or 0
			local playerLevel = data.level or 0
			local isLevelLocked = requiredLevel > 0 and playerLevel < requiredLevel

			table.insert(cards, ItemCard(scope, {
				itemName = item.Name,
				price = tostring(item.Price),
				rarity = item.Rarity,
				itemImage = item.Image,
				layoutOrder = i,
				isOwned = isOwned,
				isEquipped = isEquipped,
				isLevelLocked = isLevelLocked,
				requiredLevel = requiredLevel,
				onClick = function()
					if isLevelLocked then
						return -- Bloqueado por nivel
					end

					if isEquipped then
						return -- Ya equipado
					end

					if isOwned then
						-- Equipar
						if equipItemRF then
							task.spawn(function()
								local success, msg = equipItemRF:InvokeServer(currentOption, item.Name)
								if not success then
									warn("Error al equipar:", msg)
								end
							end)
						else
							warn("Remote EquipItem no encontrado")
						end
					else
						-- Comprar (futuro)
						print("Click en item NO comprado:", item.Name)
					end
				end,
			}))
		end

		return cards
	end)

	return scope:New "ScrollingFrame" {
		Name = "ItemGrid",
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		BottomImage = "",
		Position = UDim2.fromScale(0, 0.014),
		ScrollBarThickness = 10,
		ScrollBarImageColor3 = Color3.new(1, 1, 1),
		Size = UDim2.fromScale(0.987, 0.986),
		TopImage = "",

		[Children] = itemCards,
	}
end

--------------------------------------------------------------------------------
-- Container principal (panel derecho)
--------------------------------------------------------------------------------
local function createContainer(scope: Fusion.Scope<typeof(Fusion)>)
	return scope:New "Frame" {
		Name = "Container",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Constants.Colors.Background,
		Position = UDim2.fromScale(0.809, 0.586),
		Size = UDim2.fromScale(0.356, 0.773),

		[Children] = {
			scope:New "UICorner" {
				Name = "UICorner",
				CornerRadius = UDim.new(0.05, 0),
			},

			scope:New "UIStroke" {
				Name = "UIStroke",
				Enabled = false,
				Thickness = 8,
			},

			createItemGrid(scope),
		},
	}
end

--------------------------------------------------------------------------------
-- Tabs de la tienda (Arsenal, Cosmetics) — con color reactivo
--------------------------------------------------------------------------------
local function createTabs(scope: Fusion.Scope<typeof(Fusion)>)
	local tabs = {}

	-- Posiciones predefinidas (Ajustadas para AnchorPoint 0.5)
	local positions = {
		UDim2.fromScale(0.7095, 0.1455),
		UDim2.fromScale(0.8585, 0.1455),
	}

	for i, tabData in Constants.Tabs do
		-- Color reactivo: azul si activo, gris si inactivo
		local tabColor = Computed(scope, function(use)
			if use(selectedTab) == tabData.Name then
				return Constants.Colors.TabActive
			else
				return Constants.Colors.TabInactive
			end
		end)

		table.insert(tabs, TabButton(scope, {
			text = tabData.Text,
			color = tabColor,
			position = positions[i] or UDim2.fromScale(0, 0),
			layoutOrder = tabData.LayoutOrder,
			onClick = function()
				selectTab(tabData.Name)
			end,
		}))
	end

	return tabs
end

-- Posición X del Root: 0 (abierto, centrado) vs 1.5 (cerrado, desplazado a la derecha fuera de pantalla)
local rootXOffset = Spring(scope, Computed(scope, function(use)
	return use(isStoreOpen) and 0 or 1.5 -- 1.5 lo saca completamente
end), 30, 0.8)

--------------------------------------------------------------------------------
-- ScreenGui principal
--------------------------------------------------------------------------------
local storeGui = scope:New "ScreenGui" {
	Name = "Locker",
	Parent = player.PlayerGui,
	Enabled = isStoreOpen, -- Vinculado: True al abrir (vemos anim), False al cerrar (desaparece)
	IgnoreGuiInset = true,
	ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,

	[Children] = {
		scope:New "UIScale" {
			Scale = uiScale,
		},

		-- Frame Raíz que mueve TODO el conjunto
		scope:New "Frame" {
			Name = "Root",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),

			-- Animamos la posición del Root entero
			Position = Computed(scope, function(use)
				return UDim2.fromScale(use(rootXOffset), 0)
			end),

			[Children] = {
				createContainer(scope),

				CloseButton(scope, {
					onClose = closeStore,
				}),

				createNavSection(scope),

				-- Tabs
				createTabs(scope),
			}
		}
	},
}

-- Abrir/cerrar con una tecla
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleStore()
		storeGui.Enabled = peek(isStoreOpen)
	end
end)
print("[StoreUI] Cargado correctamente")
