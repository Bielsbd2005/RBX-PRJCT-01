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
-- Navegación lateral (Option buttons)
--------------------------------------------------------------------------------
local function createNavSection(scope: Fusion.Scope<typeof(Fusion)>)
	return scope:New "Frame" {
		Name = "Nav",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.574, 0.22),
		Size = UDim2.fromScale(0.052, 0.308),

		[Children] = {
			scope:New "UIListLayout" {
				Name = "UIListLayout",
				HorizontalAlignment = Enum.HorizontalAlignment.Right,
				Padding = UDim.new(0.02, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			NavButton(scope, {
				name = "Option1",
				layoutOrder = 1,
			}),

			NavButton(scope, {
				name = "Option2",
				layoutOrder = 2,
			}),

			NavButton(scope, {
				name = "Option3",
				layoutOrder = 3,
			}),
		},
	}
end

--------------------------------------------------------------------------------
-- Grid de items (ScrollingFrame con tarjetas)
--------------------------------------------------------------------------------
local function createItemGrid(scope: Fusion.Scope<typeof(Fusion)>)
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

		[Children] = {
			scope:New "UIGridLayout" {
				Name = "UIGridLayout",
				CellPadding = UDim2.fromScale(0.04, 0.03),
				CellSize = UDim2.fromScale(0.3, 0.27),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			scope:New "UIPadding" {
				Name = "UIPadding",
				PaddingBottom = UDim.new(0, 25),
				PaddingLeft = UDim.new(0, 25),
				PaddingRight = UDim.new(0, 25),
				PaddingTop = UDim.new(0.006, 0),
			},

			-- Items de prueba
			ItemCard(scope, {
				itemName = "ShadowBlade",
				price = "1,908",
				rarity = "EPIC",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 1,
			}),

			ItemCard(scope, {
				itemName = "FrostRifle",
				price = "3,250",
				rarity = "LEGENDARY",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 2,
			}),

			ItemCard(scope, {
				itemName = "IronShield",
				price = "750",
				rarity = "COMMON",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 3,
			}),

			ItemCard(scope, {
				itemName = "PlasmaPistol",
				price = "2,100",
				rarity = "RARE",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 4,
			}),

			ItemCard(scope, {
				itemName = "VoidArmor",
				price = "5,500",
				rarity = "LEGENDARY",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 5,
			}),

			ItemCard(scope, {
				itemName = "StormDagger",
				price = "980",
				rarity = "RARE",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 6,
			}),
			ItemCard(scope, {
				itemName = "PlasmaPistol",
				price = "2,100",
				rarity = "RARE",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 4,
			}),

			ItemCard(scope, {
				itemName = "VoidArmor",
				price = "5,500",
				rarity = "LEGENDARY",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 5,
			}),

			ItemCard(scope, {
				itemName = "StormDagger",
				price = "980",
				rarity = "RARE",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 6,
			}),
			ItemCard(scope, {
				itemName = "PlasmaPistol",
				price = "2,100",
				rarity = "RARE",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 4,
			}),

			ItemCard(scope, {
				itemName = "VoidArmor",
				price = "5,500",
				rarity = "LEGENDARY",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 5,
			}),

			ItemCard(scope, {
				itemName = "StormDagger",
				price = "980",
				rarity = "RARE",
				itemImage = "rbxassetid://79175047578893",
				layoutOrder = 6,
			}),

		},
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
-- Tabs de la tienda (Arsenal, Cosmetics, etc.)
--------------------------------------------------------------------------------
local function createTabs(scope: Fusion.Scope<typeof(Fusion)>)
	local tabs = {}

	-- Posiciones predefinidas (se pueden calcular dinámicamente con UIListLayout en el futuro)
	local positions = {
		UDim2.fromScale(0.64, 0.11),
		UDim2.fromScale(0.789, 0.11),
	}

	for i, tabData in Constants.Tabs do
		table.insert(tabs, TabButton(scope, {
			text = tabData.Text,
			color = tabData.Color,
			position = positions[i] or UDim2.fromScale(0, 0),
			layoutOrder = tabData.LayoutOrder,
			onClick = function()
				-- TODO: Lógica de cambio de pestaña
				print("Tab seleccionado:", tabData.Name)
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

-- Ejemplo: abrir la tienda (conectar después a tu sistema de botones)
-- toggleStore()
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
