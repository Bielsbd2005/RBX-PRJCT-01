--[[
	SkinCard
	Componente para visualizar una skin de arma con efectos y animación.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _RunService = game:GetService("RunService")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local _New = Fusion.New
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value
local Computed = Fusion.Computed
local Observer = Fusion.Observer

-- Constantes visuales del usuario
local FOV_IDEAL = 30
local DISTANCIA_MULTIPLIER = 0.52
local ROTACION_X = 0
local ROTACION_Y = 130
local ROTACION_Z = -12
local DESPLAZAMIENTO_X = 0.2

local function SkinCard(scope: Fusion.Scope<typeof(Fusion)>, props: {
	skinName: string,
	equippedWeapon: Fusion.UsedAs<string>, -- Nuevo prop para saber qué arma mostrar
	skinData: {
		Rarity: string,
		BaseColor: Color3,
		TextureID: string,
		TextureColor: Color3?,
		StudsPerTile: number,
		TextureTransparency: number,
		Animated: boolean,
		SecondaryPartColor: Color3,
		SecondaryPartTexture: string,
		SecondaryMaterial: Enum.Material?,
		Material: Enum.Material?,
		Particles: {
			Enabled: boolean,
			Texture: string,
			Color: ColorSequence,
			Size: NumberSequence,
			Lifetime: NumberRange,
			Rate: number,
			Speed: NumberRange
		}?
	},
	layoutOrder: number,
	isSelected: Fusion.UsedAs<boolean>,
	isEquipped: Fusion.UsedAs<boolean>?, -- New prop
	onClick: () -> (),
})
	local isHovered = Value(scope, false)

	-- ViewportFrame Ref
	local viewportRef = Value(scope, nil)

	-- Estado para la animación de textura


	-- Setup del ViewportFrame (Cámara y Modelo)
	local function setupViewport(vp: ViewportFrame)
		if not vp then return end

		vp:ClearAllChildren()

		-- 1. CLONACIÓN Y LIMPIEZA
		local weaponName = "Default" -- Fusion.peek(props.equippedWeapon) or "Default" -- Reverted to always "Default" as requested
		local weaponsFolder = ReplicatedStorage:WaitForChild("Weapons", 5)
		local baseModel = weaponsFolder and (weaponsFolder:FindFirstChild(weaponName) or weaponsFolder:FindFirstChild("Default"))

		if not baseModel then return end

		local clonedModel = baseModel:Clone()
		clonedModel.Parent = vp

		-- 2. ORIENTACIÓN INICIAL
		local modelCenter, modelSize = clonedModel:GetBoundingBox()
		local orientacionFija = CFrame.fromEulerAnglesYXZ(
			math.rad(ROTACION_X),
			math.rad(ROTACION_Y),
			math.rad(ROTACION_Z)
		)

		-- Pivotar al centro
		clonedModel:PivotTo(CFrame.new(modelCenter.Position) * orientacionFija)

		-- 3. CÁMARA
		local cam = Instance.new("Camera")
		cam.FieldOfView = FOV_IDEAL
		vp.CurrentCamera = cam
		cam.Parent = vp

		-- Recalcular dimensiones tras la rotación
		local updatedCenter, updatedSize = clonedModel:GetBoundingBox()
		local maxDimension = math.max(updatedSize.X, updatedSize.Y, updatedSize.Z)

		local halfFov = math.rad(cam.FieldOfView / 2)
		local baseDistance = (maxDimension / 2) / math.tan(halfFov)
		local finalDistance = baseDistance * DISTANCIA_MULTIPLIER

		cam.CFrame = CFrame.new(
			updatedCenter.Position + Vector3.new(0, 0, finalDistance),
			updatedCenter.Position
		) * CFrame.new(-DESPLAZAMIENTO_X, 0, 0) -- Desplazamos la cámara a la izquierda

		-- 4. APLICAR SKIN using shared module
		local SkinApplier = require(ReplicatedStorage.Shared.Modules.Appearance.SkinApplier)
		local data = props.skinData
		local textures = SkinApplier.apply(clonedModel, data)

		-- 5. ANIMACIÓN using shared module (uses Heartbeat, not RenderStepped)
		local animConnection = SkinApplier.startAnimation(textures, data, vp)
		if animConnection then
			table.insert(scope, { Destroy = function() animConnection:Disconnect() end })
		end
	end

	-- Efecto para inicializar el Viewport una vez montado
	local obs = Observer(scope, viewportRef)
	obs:onChange(function()
		local vp = Fusion.peek(viewportRef)
		if vp then
			task.defer(function()
				setupViewport(vp)
			end)
		end
	end)

	local _backgroundColor = Computed(scope, function(use)
		local selected = use(props.isSelected)
		local hovered = use(isHovered)

		if selected then
			return Color3.fromRGB(170, 206, 251) -- Seleccionado (Azul claro del ejemplo)
		elseif hovered then
			return Color3.fromRGB(80, 80, 80)
		else
			return Color3.fromRGB(170, 206, 251) -- Fondo por defecto del ejemplo (puede ser muy brillante si no está seleccionado, ajustar si necesario)
		end
	end)

	return scope:New "ImageButton" {
		Name = "WeaponSkin",
		LayoutOrder = props.layoutOrder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(170, 206, 251),
		ClipsDescendants = true,
		Image = "rbxassetid://71136216021149",
		ImageTransparency = 0.8,
		Size = UDim2.fromScale(1, 1), -- Será controlado por UIGridLayout del padre, pero UDim2.fromScale(1,1) rellena la celda

		[OnEvent "Activated"] = props.onClick,
		[OnEvent "MouseEnter"] = function() isHovered:set(true) end,
		[OnEvent "MouseLeave"] = function() isHovered:set(false) end,

		[Children] = {
			scope:New "UICorner" {
				Name = "UICorner",
				CornerRadius = UDim.new(0.08, 0),
			},

			-- Borde de selección (UIStroke thickness 5 del ejemplo)
			scope:New "UIStroke" {
				Name = "UIStroke",
				Color = Computed(scope, function(use)
					local equipped = false
					if props.isEquipped then
						equipped = if typeof(props.isEquipped) == "table" then use(props.isEquipped) else props.isEquipped
					end

					return (use(props.isSelected) or equipped) and Color3.fromRGB(85, 126, 239) or Color3.fromRGB(131, 131, 131)
				end),
				Thickness = 5,
			},

			scope:New "TextLabel" {
				Name = "Name",
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/HighwayGothic.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(-0.005, 0.774),
				Size = UDim2.fromScale(1, 0.222),
				Text = props.skinName,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				ZIndex = 2,

				[Children] = {
					scope:New "UIStroke" {
						Name = "UIStroke",
						Thickness = 2,
					},
					scope:New "UITextSizeConstraint" {
						Name = "UITextSizeConstraint",
						MaxTextSize = 30,
					},
				}
			},

			scope:New "TextLabel" {
				Name = "Rarity",
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/HighwayGothic.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0, 0.018),
				Size = UDim2.fromScale(1, 0.179),
				Text = props.skinData.Rarity,
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
						MaxTextSize = 46,
					},
				}
			},

			(function()
				local vp = scope:New "ViewportFrame" {
					Name = "ViewportFrame",
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
				}
				viewportRef:set(vp)
				return vp
			end)(),
		}
	}
end

return SkinCard
