--[[
	Locker
	Script principal de la Locker GUI.
	Orquesta todos los componentes y gestiona el estado de la tienda.

	Ruta: StarterPlayerScripts > Client > LockerUI
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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
local ActionFrame = require(script.Parent.Components.ActionFrame)
local SkinCard = require(script.Parent.Components.SkinCard)
local OutfitCard = require(script.Parent.Components.OutfitCard)
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
local buyItemRF = shopFolder and shopFolder:WaitForChild("BuyItem", 10)

-- Tab y opción seleccionados
local selectedTab = Value(scope, "Arsenal")
local selectedOption = Value(scope, "Weapons")
local selectedItem = Value(scope, nil) -- { Name = string, Price = number } or nil
local previewCharacter = Value(scope, nil) -- Character instance
local previewWeapon = Value(scope, nil) -- Weapon model instance

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

local skinAnimationConnection: RBXScriptConnection? = nil
local TILE_SIZE = 2
local TEXTURE_SPEED_U = 0.5
local TEXTURE_SPEED_V = 0

local previewKillEffectDummy = Value(scope, nil)
local killEffectDebounce = false

local function cleanupPreview()
	local char = peek(previewCharacter)
	if char then char:Destroy(); previewCharacter:set(nil) end

	if skinAnimationConnection then
		skinAnimationConnection:Disconnect()
		skinAnimationConnection = nil
	end

	local weap = peek(previewWeapon)
	if weap then weap:Destroy(); previewWeapon:set(nil) end

	local killDummy = peek(previewKillEffectDummy)
	if killDummy then killDummy:Destroy(); previewKillEffectDummy:set(nil) end
end

local function spawnCharacter()
	-- Si ya existe, no recrear (optimización), pero asegurar que es visible
	if peek(previewCharacter) then return peek(previewCharacter) end

	local template = ReplicatedStorage:WaitForChild("CharacterTemplate", 5)
	if not template then warn("CharacterTemplate no encontrado"); return end

	local lockerFolder = workspace:WaitForChild("Locker", 5)
	local spawnLocation = lockerFolder and lockerFolder:WaitForChild("CharacterSpawn", 5)
	if not spawnLocation then warn("CharacterSpawn no encontrado"); return end

	local char = template:Clone()
	char.Parent = spawnLocation
	char:PivotTo(spawnLocation.CFrame)

	-- Animación Idle
	local humanoid = char:WaitForChild("Humanoid", 5)
	local animator = humanoid and humanoid:WaitForChild("Animator", 5)
	if animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://77576237797818"
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end

	previewCharacter:set(char)
	return char
end

local function spawnKillEffectDummy(forceRespawn)
	if peek(previewKillEffectDummy) and not forceRespawn then return peek(previewKillEffectDummy) end

	-- Cleanup existing if forcing respawn
	local existing = peek(previewKillEffectDummy)
	if existing then existing:Destroy(); previewKillEffectDummy:set(nil) end

	local template = ReplicatedStorage:FindFirstChild("Dummy") or ReplicatedStorage:FindFirstChild("CharacterTemplate") -- Fallback
	if not template then warn("Dummy/CharacterTemplate not found for KillEffect"); return end

	local lockerFolder = workspace:WaitForChild("Locker", 5)
	local spawnLocation = lockerFolder and lockerFolder:FindFirstChild("KillEffectSpawn")

	if not spawnLocation then
		warn("KillEffectSpawn not found")
		-- Fallback to a position near Locker camera if spawn doesn't exist
		spawnLocation = { CFrame = CFrame.new(0, 5, 0) }
	end

	-- Aggressive orphan cleanup
    local parentFolder = lockerFolder or workspace
    for _, child in parentFolder:GetChildren() do
        if child.Name == "KillEffectDummy" and child ~= peek(previewKillEffectDummy) then
            child:Destroy()
        end
    end

	local char = template:Clone()
	char.Name = "KillEffectDummy"
	char.Parent = lockerFolder or workspace
	char:PivotTo(spawnLocation.CFrame)

	-- Animation Idle (reuse same id)
	local humanoid = char:WaitForChild("Humanoid", 5)
	local animator = humanoid and humanoid:WaitForChild("Animator", 5)
	if animator then
		local animation = Instance.new("Animation")
		animation.AnimationId = "rbxassetid://77576237797818"
		local track = animator:LoadAnimation(animation)
		track.Looped = true
		track:Play()
	end

	previewKillEffectDummy:set(char)
	return char
end

local function playKillEffectPreview(effectItem)
	if killEffectDebounce then return end

	local dummy = peek(previewKillEffectDummy)
	if not dummy then
		dummy = spawnKillEffectDummy(true)
	end

	if not dummy then return end

	killEffectDebounce = true

	-- 1. Apply Effect Logic (Placeholder / Asset lookup)
    -- Assuming effects are particles/scripts in a folder or just a visual cue
    print("Playing Kill Effect:", effectItem.Name)

    local killEffectsFolder = ReplicatedStorage:FindFirstChild("Shared") and ReplicatedStorage.Shared:FindFirstChild("Modules") and ReplicatedStorage.Shared.Modules:FindFirstChild("KillEffects")
    local effectTemplate = killEffectsFolder and killEffectsFolder:FindFirstChild(effectItem.Name)

    if effectTemplate then
	    local effectModule = require(effectTemplate)
		if effectModule.applyDefaultRagdoll then
			effectModule.applyDefaultRagdoll(dummy)
		end
    else
        -- Fallback if no module found
        warn("KillEffect module not found for:", effectItem.Name)
    end

    -- Trigger Death to activate the effect
	local humanoid = dummy:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Health = 0
	end

	-- 2. Wait
	task.wait(2)

	-- 3. Fade Out
	local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
	local parts = {}

    for _, part in dummy:GetDescendants() do
        if part:IsA("BasePart") or part:IsA("Decal") then
            table.insert(parts, part)
        end
    end

    for _, part in parts do
        TweenService:Create(part, tweenInfo, {Transparency = 1}):Play()
    end

    task.wait(1)

    -- 4. Cleanup and Respawn
    if dummy then dummy:Destroy() end
    previewKillEffectDummy:set(nil)

    -- Only respawn if the store is still OPEN
    if peek(isStoreOpen) then
        spawnKillEffectDummy(true)
    end

    killEffectDebounce = false
end

local function applySkin(weapon: Model, skinData: { [string]: any })
	if not weapon or not skinData then return end

	-- Clean up previous animation connection if any (though usually managed by spawnWeapon/cleanup)
	-- We don't disconnect here because spawnWeapon handles the global connection var

	local textures = {} -- Keep track of textures for animation

	for _, part in weapon:GetDescendants() do
		if part:IsA("BasePart") then
			-- Skip invisible parts (hitboxes, etc.) to save memory/draw calls
			if part.Transparency == 1 then
				continue
			end

			-- Logic for SecondaryPart
			if part.Name == "SecondaryPart" then
				part.Color = skinData.SecondaryPartColor or part.Color

				if skinData.SecondaryMaterial then
					part.Material = skinData.SecondaryMaterial
				end

				if part:IsA("MeshPart") then
					part.TextureID = skinData.SecondaryPartTexture or ""
				elseif skinData.SecondaryPartTexture and skinData.SecondaryPartTexture ~= "" then
					for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
						local t = Instance.new("Texture")
						t.Name = "SecondaryTexture_" .. face.Name
						t.Face = face
						t.Texture = skinData.SecondaryPartTexture
						t.Transparency = skinData.TextureTransparency or 0
						t.StudsPerTileU = skinData.StudsPerTile or TILE_SIZE
						t.StudsPerTileV = skinData.StudsPerTile or TILE_SIZE
						t.Color3 = Color3.new(1,1,1)
						t.Parent = part
						table.insert(textures, t)
					end
				end

			-- Logic for other parts (Primary Style)
			else
				part.Color = skinData.BaseColor
				part.Material = skinData.Material or Enum.Material.Plastic

				-- Apply textures to all faces if TextureID exists
				if skinData.TextureID and skinData.TextureID ~= "" then
					for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
						local t = Instance.new("Texture")
						t.Name = "SkinTexture_" .. face.Name
						t.Face = face
						t.Texture = skinData.TextureID
						t.Transparency = skinData.TextureTransparency or 0
						t.StudsPerTileU = skinData.StudsPerTile or TILE_SIZE
						t.StudsPerTileV = skinData.StudsPerTile or TILE_SIZE
						t.Color3 = skinData.TextureColor or Color3.new(1,1,1)
						t.Parent = part
						table.insert(textures, t)
					end
				end

				-- Particles (ADDITION to SkinCard logic)
				if part == weapon.PrimaryPart and skinData.Particles and skinData.Particles.Enabled then
					local p = Instance.new("ParticleEmitter")
					p.Name = "SkinParticles"
					p.Texture = skinData.Particles.Texture
					p.Color = skinData.Particles.Color
					p.Size = skinData.Particles.Size
					p.Lifetime = skinData.Particles.Lifetime
					p.Rate = skinData.Particles.Rate
					p.Speed = skinData.Particles.Speed
					p.Parent = part
				end
			end
		end
	end

	-- Animation Logic
	if skinData.Animated or (skinData.TextureID and skinData.TextureID ~= "") or (skinData.SecondaryPartTexture and skinData.SecondaryPartTexture ~= "") then
		if skinAnimationConnection then skinAnimationConnection:Disconnect() end

		-- Loop state
		local currentU = 0
		local currentV = 0

		skinAnimationConnection = RunService.RenderStepped:Connect(function(dt)
			if not weapon or not weapon.Parent then
				if skinAnimationConnection then skinAnimationConnection:Disconnect() end
				skinAnimationConnection = nil
				return
			end

            -- Only animate if Animated flag is true
            if skinData.Animated then
			    currentU = (currentU + TEXTURE_SPEED_U * dt) % (skinData.StudsPerTile or TILE_SIZE)
			    currentV = (currentV + TEXTURE_SPEED_V * dt) % (skinData.StudsPerTile or TILE_SIZE)

			    for _, t in textures do
				    t.OffsetStudsU = currentU
				    t.OffsetStudsV = currentV
			    end
            end
		end)
	end
end

local function spawnWeapon(weaponName: string, skinData: { [string]: any }?)
	-- NO limpiar personaje aquí para permitir dual preview
	-- local char = peek(previewCharacter)
	-- if char then char:Destroy(); previewCharacter:set(nil) end

	-- Limpiar arma anterior
	-- Limpiar arma anterior
	local currentWeap = peek(previewWeapon)
	if currentWeap then currentWeap:Destroy() end

	if skinAnimationConnection then
		skinAnimationConnection:Disconnect()
		skinAnimationConnection = nil
	end

	local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 5)
	local weaponTemplate = weaponsFolder and weaponsFolder:FindFirstChild(weaponName)

	if not weaponTemplate then
		-- Fallback a Default si no existe la específica (para evitar vacío)
		weaponTemplate = weaponsFolder:FindFirstChild("Default") or weaponsFolder:FindFirstChild("Weapon1")
	end

	if not weaponTemplate then warn("Weapon model not found:", weaponName); return end

	local lockerFolder = workspace:WaitForChild("Locker", 5)
	local spawnLocation = lockerFolder and lockerFolder:WaitForChild("WeaponSpawn", 5)
	if not spawnLocation then warn("WeaponSpawn no encontrado en Workspace.Locker"); return end

	local newWeap = weaponTemplate:Clone()
	newWeap.Parent = spawnLocation
	newWeap:PivotTo(spawnLocation.CFrame)

	-- Asegurar que esté anclado para preview
	for _, part in newWeap:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	if skinData then
		applySkin(newWeap, skinData)
	end

	previewWeapon:set(newWeap)
	return newWeap
end


-- Gestor de Apariencia
local FaceApplier = require(ReplicatedStorage.Shared.Modules.Appearance.FaceApplier)
local HatApplier = require(ReplicatedStorage.Shared.Modules.Appearance.HatApplier)
local OutfitApplier = require(ReplicatedStorage.Shared.Modules.Appearance.OutfitApplier)
local ItemsData = require(ReplicatedStorage.Shared.ItemsData)
local DataController = require(ReplicatedStorage.Shared.Modules.DataController)

-- Estado reactivo de los datos del jugador (Global para usar en functions)
local playerData = Value(scope, DataController:Get() or {})

-- Escuchar cambios en los datos
DataController:OnReady(function()
	playerData:set(DataController:Get())
end)

local _conn_data = DataController:OnRawChange(function()
	playerData:set(DataController:Get())
end)

local function restorePreview()
	local data = peek(playerData)
	local currentTab = peek(selectedTab)

	-- Restore Weapon
	local equippedWeapon = "Default"
	if data and data.equipped and data.equipped.Weapons then
		equippedWeapon = data.equipped.Weapons
	end

	local equippedSkinData = nil
	local skinName = "Default"
	if data and data.equipped and data.equipped.WeaponSkins then
		skinName = data.equipped.WeaponSkins
	end

	if ItemsData.Arsenal and ItemsData.Arsenal.WeaponSkins then
		for _, s in ItemsData.Arsenal.WeaponSkins do
			if s.Name == skinName then
				equippedSkinData = s
				break
			end
		end
	end

	spawnWeapon(equippedWeapon, equippedSkinData)

	-- Restore Character Appearance
	local char = spawnCharacter()
	if char and data and data.equipped then
		-- Face
		local equippedFaceName = data.equipped.Faces
		if equippedFaceName then
			local faceItem = nil
			if ItemsData.Cosmetics and ItemsData.Cosmetics.Faces then
				for _, item in ItemsData.Cosmetics.Faces do
					if item.Name == equippedFaceName then faceItem = item; break end
				end
			end
			if faceItem then FaceApplier.Apply(char, faceItem) end
		end

		-- Hat
		local equippedHatName = data.equipped.Hats
		if equippedHatName then
			local hatItem = nil
			if ItemsData.Cosmetics and ItemsData.Cosmetics.Hats then
				for _, item in ItemsData.Cosmetics.Hats do
					if item.Name == equippedHatName then hatItem = item; break end
				end
			end
			if hatItem then
				HatApplier.Apply(char, hatItem)
			else
				HatApplier.Clear(char)
			end
		else
			HatApplier.Clear(char)
		end

		-- Outfit
		local equippedOutfitName = data.equipped.Outfits
		if equippedOutfitName then
			local outfitItem = nil
			if ItemsData.Cosmetics and ItemsData.Cosmetics.Outfits then
				for _, item in ItemsData.Cosmetics.Outfits do
					if item.Name == equippedOutfitName then outfitItem = item; break end
				end
			end
			if outfitItem then OutfitApplier.Apply(char, outfitItem) end
		end

	end
end

-- Observar cambios en la selección
local Observer = Fusion.Observer
local obsItem = Observer(scope, selectedItem)
obsItem:onChange(function()
	local item = peek(selectedItem)

	if item then
		local option = peek(selectedOption)

		-- SHOW PREVIEW
		if option == "Weapons" then
			local data = peek(playerData)
			local equippedSkinData = nil
			local skinName = "Default"

			if data and data.equipped and data.equipped.WeaponSkins then
				skinName = data.equipped.WeaponSkins
			end

			if ItemsData.Arsenal and ItemsData.Arsenal.WeaponSkins then
				for _, s in ItemsData.Arsenal.WeaponSkins do
					if s.Name == skinName then
						equippedSkinData = s
						break
					end
				end
			end

			spawnWeapon(item.Name, equippedSkinData)
		elseif option == "WeaponSkins" then
			local data = peek(playerData)
			local currentWeapon = data.equipped and data.equipped.Weapons or "Default"
			spawnWeapon(currentWeapon, item) -- item is the skin data
		elseif option == "Faces" then
			local char = spawnCharacter()
			if char then FaceApplier.Apply(char, item) end
		elseif option == "Hats" then
			local char = spawnCharacter()
			if char then HatApplier.Apply(char, item) end

		elseif option == "Outfits" then
			local char = spawnCharacter()
			if char then OutfitApplier.Apply(char, item) end
		elseif option == "KillEffects" then
			spawnKillEffectDummy(false) -- Ensure dummy exists
			task.spawn(function()
				playKillEffectPreview(item)
			end)
		end

		-- Auto-Equipar si se tiene (Owned)
		local data = peek(playerData)
		local isOwned = false
		if data.inventory and data.inventory[option] then
			for _, name in data.inventory[option] do
				if name == item.Name then isOwned = true; break end
			end
		end
		if item.Name == "Default" then isOwned = true end

		if isOwned and equipItemRF then
			-- Check if already equipped to avoid redundant calls
			if data.equipped and data.equipped[option] == item.Name then
				return
			end

			-- OPTIMISTIC UPDATE: Auto-equip locally immediately
			local newData = table.clone(peek(playerData))
			if not newData.equipped then newData.equipped = {} end
			newData.equipped[option] = item.Name
			playerData:set(newData)

			task.spawn(function()
				equipItemRF:InvokeServer(option, item.Name)
			end)
		end
	else
		-- Si se deselecciona, restaurar equipado
		restorePreview()
	end
end)

local function updatePreviewScene()
	if not peek(isStoreOpen) then
		cleanupPreview()
		return
	end

	-- Si está abierto, forzar restauración basada en el tab actual
	-- Esto maneja el cambio entre pestañas (Arsenal <-> Cosmetics)

	if peek(selectedOption) == "KillEffects" then
		spawnKillEffectDummy(false)
	else
		restorePreview()
	end
end

-- Observer para cambio de Tab (para cambiar de escena Weapon <-> Character)
local obsTab = Observer(scope, selectedTab)
obsTab:onChange(function()
	updatePreviewScene()
end)

local currentCameraTarget = "Locker"

-- Observer para cambio de Opción (para cambiar de Cámara en KillEffects)
local obsOption = Observer(scope, selectedOption)
obsOption:onChange(function()
	if not peek(isStoreOpen) then return end

	local option = peek(selectedOption)
	local targetName = (option == "KillEffects") and "KillEffects" or "Locker"

	if currentCameraTarget ~= targetName then
		currentCameraTarget = targetName

		local camerasFolder = workspace:WaitForChild("Cameras")
		local cameraPart = camerasFolder:FindFirstChild(targetName)

		if cameraPart then
			local focusDist = (targetName == "KillEffects") and 17.06 or 10 -- Default 10 for Locker
			CameraManager.setTarget(cameraPart, true, nil, focusDist)
		end
	end

	-- AUTO-SELECT EQUIPPED ITEM
	local data = peek(playerData)
	local tab = peek(selectedTab)
	local equippedName = data.equipped and data.equipped[option]

	local foundEquipped = false
	if equippedName and equippedName ~= "" then
		local categoryData = ItemsData[tab]
		local optionData = categoryData and categoryData[option]

		if optionData then
			for _, item in optionData do
				if item.Name == equippedName then
					selectedItem:set(item)
					foundEquipped = true
					break
				end
			end
		end
	end

	-- If we switched to an option where we don't have something equipped (e.g. empty category)
	-- we might want to clear the selection or keep it. Original logic suggested clearing.
	if not foundEquipped then
		selectedItem:set(nil)
	end
end)

local function setStoreState(isOpen)
	if isOpen then
		-- Force default tab/option when opening
		selectedTab:set("Arsenal")
		selectedOption:set("Weapons")

		-- Pre-spawn KillEffectDummy so it's ready
		spawnKillEffectDummy(false)
	end

	isStoreOpen:set(isOpen)
	updatePreviewScene()

	if isOpen then
		-- ABRIR
		currentCameraTarget = "Locker" -- Resetear al abrir
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
--------------------------------------------------------------------------------
-- Grid de items (ScrollingFrame con tarjetas)
--------------------------------------------------------------------------------

local function createItemGrid(scope: Fusion.Scope<typeof(Fusion)>)
	-- playerData ya está definido arriba en scope principal

	-- Limpieza al destruir el scope (aunque en este script LockerUI vive siempre, es buena práctica)
	-- table.insert(scope, { Destroy = ... }) -- conn_data es global ahora


	-- Lista de items reactiva según tab/opción
	-- Lista de items reactiva según tab/opción
	local currentItems = Computed(scope, function(use)
		local tab = use(selectedTab)
		local option = use(selectedOption)
		local data = use(playerData)

		local categoryData = ItemsData[tab]
		if not categoryData then return {} end

		local optionData = categoryData[option]
		if not optionData then return {} end

		-- Filtro estricto para WeaponSkins: SOLO mostrar si se tienen en el inventario
		if option == "WeaponSkins" then
			local filtered = {}
			local ownedSet = {}

			if data.inventory and data.inventory.WeaponSkins then
				for _, name in data.inventory.WeaponSkins do
					ownedSet[name] = true
				end
			end
			-- Always ensure Default is visible (safety fallback)
			ownedSet["Default"] = true

			for _, item in optionData do
				if ownedSet[item.Name] then
					table.insert(filtered, item)
				end
			end

			return filtered
		else
			-- Otras categorías muestran todo (bloqueado/desbloqueado)
			return optionData
		end
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
			local priceA = a.Price or 0
			local priceB = b.Price or 0
			if priceA ~= priceB then
				return priceA < priceB
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

			if currentOption == "WeaponSkins" then
				table.insert(cards, SkinCard(scope, {
					skinName = item.Name,
					skinData = item,
					isEquipped = isEquipped, -- Pass equipped state
					equippedWeapon = Computed(scope, function(use)
						local d = use(playerData)
						return d.equipped and d.equipped.Weapons or "Default"
					end),
					layoutOrder = i,
					isSelected = Computed(scope, function(use)
						local current = use(selectedItem)
						return current and current.Name == item.Name
					end),
					onClick = function()
						selectedItem:set(item)
					end,

				}))
			elseif currentOption == "Outfits" then
				table.insert(cards, OutfitCard(scope, {
					outfitName = item.Name,
					outfitData = item,
					layoutOrder = i,
					isOwned = isOwned,
					isEquipped = isEquipped,
					isSelected = Computed(scope, function(use)
						local current = use(selectedItem)
						return current and current.Name == item.Name
					end),
					onClick = function()
						selectedItem:set(item)
					end,
				}))
			else
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
					isSelected = Computed(scope, function(use)
						local current = use(selectedItem)
						return current and current.Name == item.Name
					end),
					onClick = function()
						selectedItem:set(item)
					end,
				}))
			end
		end

		-- Special "Plus" button for WeaponSkins (Custom + Skins)
		if currentOption == "WeaponSkins" then
			-- Clear standard items for skins to avoid double rendering if we want ONLY skins here
			-- Actually `items` comes from `ItemsData["Arsenal"]["WeaponSkins"]`, so `sortedItems` ARE the skins.
			-- Wait, `ItemCard` expects `Image` prop, but SkinData has `TextureID`. `ItemCard` is designed for static images.
			-- We should replace the loop above with a conditional check.
		end

		-- Special "Plus" button for WeaponSkins
		if currentOption == "WeaponSkins" then
			table.insert(cards, scope:New "ImageButton" {
				Name = "Weapon",
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutoButtonColor = false,
				BackgroundColor3 = Color3.fromRGB(54, 54, 54),
				ClipsDescendants = true,
				Image = "rbxassetid://100090954804591",
				ImageColor3 = Color3.fromRGB(79, 79, 79),
				ImageTransparency = 0.14,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				LayoutOrder = 9999, -- Ensure it's at the end

				[Children] = {
					scope:New "UICorner" {
						Name = "UICorner",
						CornerRadius = UDim.new(0.08, 0),
					},

					scope:New "UIStroke" {
						Name = "UIStroke",
						Color = Color3.fromRGB(131, 131, 131),
						Thickness = 5,
					},

					scope:New "TextLabel" {
						Name = "Rarity",
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Arial.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Size = UDim2.fromScale(1, 1),
						Text = "+",
						TextColor3 = Color3.fromRGB(253, 255, 255),
						TextScaled = true,
						ZIndex = 2,

						[Children] = {
							scope:New "UIStroke" {
								Name = "UIStroke",
								Thickness = 2,
							},

							scope:New "UITextSizeConstraint" {
								Name = "UITextSizeConstraint",
							},
						}
					},
				}
			})
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

				-- Action Frame (Purchase)

				-- Action Frame (Purchase)
		ActionFrame(scope, {
			price = Computed(scope, function(use)
				local item = use(selectedItem)
				if not item then return "0" end

				-- Check for level lock to display "LEVEL X" or Price
				local data = use(playerData)
				local requiredLevel = item.Level or 0
				local playerLevel = data.level or 0

				if requiredLevel > 0 and playerLevel < requiredLevel then
					return "LEVEL " .. tostring(requiredLevel)
				else
					return tostring(item.Price)
				end
			end),
			title = Computed(scope, function(use)
				local item = use(selectedItem)
				if not item then return "PURCHASE" end

				local data = use(playerData)

				local requiredLevel = item.Level or 0
				local playerLevel = data.level or 0

				-- 1. Locked check
				if requiredLevel > 0 and playerLevel < requiredLevel then
					return "LOCKED"
				end

				-- 2. Ownership check
				local currentOption = use(selectedOption)
				local isOwned = false
				if data.inventory and data.inventory[currentOption] then
					for _, name in data.inventory[currentOption] do
						if name == item.Name then isOwned = true; break end
					end
				end
				if item.Name == "Default" then isOwned = true end

				return isOwned and "EQUIP" or "PURCHASE"
			end),
			isLocked = Computed(scope, function(use)
				local item = use(selectedItem)
				if not item then return false end

				local data = use(playerData)
				local requiredLevel = item.Level or 0
				local playerLevel = data.level or 0

				return requiredLevel > 0 and playerLevel < requiredLevel
			end),
			isVisible = Computed(scope, function(use)
				local item = use(selectedItem)
				if not item then return false end

				-- Hide if owned (auto-equip handles it without explicit button), UNLESS it's locked (should show locked state)
				-- or if we want to allow equipping explicitly via button (which logic above suggests: "EQUIP")

				-- Actually, the original logic hid the button if owned or Default.
				-- But wait, the title logic has an "EQUIP" state. So why hide it if owned?
				-- Original logic:
				-- if data.inventory... return false end
				-- return true

				-- If we want to show "LOCKED", we must verify this.
				-- If it's locked, we definitely want to show it.

				local data = use(playerData)
				local requiredLevel = item.Level or 0
				local playerLevel = data.level or 0

				if requiredLevel > 0 and playerLevel < requiredLevel then
					return true -- Perform show for LOCKED
				end

				local currentOption = use(selectedOption)

				if data.inventory and data.inventory[currentOption] then
					for _, name in data.inventory[currentOption] do
						if name == item.Name then return false end
					end
				end
				if item.Name == "Default" then return false end

				return true
			end),
			onPurchase = function()
				local item = peek(selectedItem)
				if item then
					local data = peek(playerData)
					local currentOption = peek(selectedOption)
					local currentTab = peek(selectedTab)

					-- Check Locked
					local requiredLevel = item.Level or 0
					local playerLevel = data.level or 0
					if requiredLevel > 0 and playerLevel < requiredLevel then
						print("Item locked")
						return -- Do nothing if locked
					end

					-- Check ownership
					local isOwned = false
					if data.inventory and data.inventory[currentOption] then
						for _, name in data.inventory[currentOption] do
							if name == item.Name then isOwned = true; break end
						end
					end
					if item.Name == "Default" then isOwned = true end

					if isOwned then
						-- EQUIP
						if equipItemRF then
							print("Equipping:", item.Name)
							equipItemRF:InvokeServer(currentOption, item.Name)
							selectedItem:set(nil) -- Clear selection triggers restorePreview
						else
							warn("Remote EquipItem no encontrado")
						end
					else
						-- PURCHASE
						if buyItemRF then
							local success, msg = buyItemRF:InvokeServer(currentTab, currentOption, item.Name)
							if success then
								print("Compra exitosa:", item.Name)
								-- Auto-equip
								if equipItemRF then
									equipItemRF:InvokeServer(currentOption, item.Name)
								end

								-- OPTIMISTIC UPDATE: Add to inventory and equip locally
								local newData = table.clone(peek(playerData))

								-- 1. Add to inventory
								if not newData.inventory then newData.inventory = {} end
								if not newData.inventory[currentOption] then newData.inventory[currentOption] = {} end
								table.insert(newData.inventory[currentOption], item.Name)

								-- 2. Equip
								if not newData.equipped then newData.equipped = {} end
								newData.equipped[currentOption] = item.Name

								playerData:set(newData)

								selectedItem:set(nil)
							else
								warn("Error al comprar:", msg)
							end
						else
							warn("Remote BuyItem no encontrado")
						end
					end
				end
			end
		}),
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
