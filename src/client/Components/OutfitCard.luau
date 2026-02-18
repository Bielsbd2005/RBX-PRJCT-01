--[[
	OutfitCard
	Componente para visualizar un outfit en un ViewportFrame.
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

local Constants = require(script.Parent.StoreConstants)

-- Constantes visuales
local FOV_IDEAL = 30
local DISTANCIA_MULTIPLIER = 1.6 -- Ajustado para ser más lejano
local ROTACION_X = 0
local ROTACION_Y = 180 -- Rotado hacia el frente
local ROTACION_Z = 0
local DESPLAZAMIENTO_Y = 0 -- Centrado

local function OutfitCard(scope: Fusion.Scope<typeof(Fusion)>, props: {
	outfitName: string,
	outfitData: {
		Rarity: string,
		Price: number,
		ShirtBaseColor: Color3,
		ShirtTextureID: string,
		ShirtStudsPerTile: number,
		ShirtTextureTransparency: number,
		ShirtMaterial: Enum.Material,
		PantMaterial: Enum.Material,
		PantColor: Color3,
	},
	layoutOrder: number,
	isSelected: Fusion.UsedAs<boolean>,
	isOwned: boolean?,
	isEquipped: Fusion.UsedAs<boolean>?,
	onClick: () -> (),
})

	-- ViewportFrame Ref
	local viewportRef = Value(scope, nil)

	-- Setup del ViewportFrame (Cámara y Character)
	local setupViewport = function(vp: ViewportFrame)
		if not vp then return end

		vp:ClearAllChildren()

		-- 1. CLONACIÓN
		local template = ReplicatedStorage:WaitForChild("ClothingTemplate", 5)
		if not template then return end

		local clonedChar = template:Clone()
		clonedChar.Parent = vp

		-- 2. ORIENTACIÓN INICIAL
		local modelCenter, modelSize = clonedChar:GetBoundingBox()
		local orientacionFija = CFrame.fromEulerAnglesYXZ(
			math.rad(ROTACION_X),
			math.rad(ROTACION_Y),
			math.rad(ROTACION_Z)
		)

		-- Pivotar al centro
		clonedChar:PivotTo(CFrame.new(modelCenter.Position) * orientacionFija)

		-- 3. CÁMARA
		local cam = Instance.new("Camera")
		cam.FieldOfView = FOV_IDEAL
		vp.CurrentCamera = cam
		cam.Parent = vp

		-- Recalcular dimensiones
		local updatedCenter, updatedSize = clonedChar:GetBoundingBox()
		local maxDimension = math.max(updatedSize.X, updatedSize.Y, updatedSize.Z)

		local halfFov = math.rad(cam.FieldOfView / 2)
		local baseDistance = (maxDimension / 2) / math.tan(halfFov)
		local finalDistance = baseDistance * DISTANCIA_MULTIPLIER

		cam.CFrame = CFrame.new(
			updatedCenter.Position + Vector3.new(0, DESPLAZAMIENTO_Y, finalDistance),
			updatedCenter.Position + Vector3.new(0, DESPLAZAMIENTO_Y, 0)
		)

		-- 4. APLICAR OUTFIT using shared module
		local OutfitApplier = require(ReplicatedStorage.Shared.Modules.Appearance.OutfitApplier)
		OutfitApplier.Apply(clonedChar, props.outfitData)

		-- Animación Idle (opcional, si tiene humanoide)
		local Constants = require(script.Parent.StoreConstants)
		local humanoid = clonedChar:FindFirstChild("Humanoid")
		local animator = humanoid and humanoid:FindFirstChild("Animator")
		if animator then
			local animation = Instance.new("Animation")
			animation.AnimationId = Constants.AnimationIds.Idle
			local track = animator:LoadAnimation(animation)
			track.Looped = true
			track:Play()
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

	return scope:New "ImageButton" {
		Name = "OutfitCard",
		LayoutOrder = props.layoutOrder,
		AnchorPoint = Vector2.new(0.5, 0.5),
		AutoButtonColor = false,
		BackgroundColor3 = Constants.Colors.CardBackground,
		ClipsDescendants = true,
		Image = Constants.Assets.CardTexture,
		ImageTransparency = 0.14,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),

		[OnEvent "Activated"] = props.onClick,

		[Children] = {
			scope:New "UICorner" {
				Name = "UICorner",
				CornerRadius = UDim.new(0.08, 0),
			},

			scope:New "UIStroke" {
				Name = "UIStroke",
				Color = Computed(scope, function(use)
					local equipped = if typeof(props.isEquipped) == "table" then use(props.isEquipped) else props.isEquipped
					local selected = if typeof(props.isSelected) == "table" then use(props.isSelected) else props.isSelected

					if equipped then
						return Constants.Colors.NavOptionActive
					elseif selected then
						return Constants.Colors.Selected
					else
						return Constants.Colors.CardStroke
					end
				end),
				Thickness = 5,
			},

			if not props.isOwned then
				scope:New "ImageLabel" {
					Name = "CurrencyImage",
					BackgroundTransparency = 1,
					Image = Constants.Assets.CurrencyIcon,
					Position = UDim2.fromScale(0.059, 0.778),
					ScaleType = Enum.ScaleType.Fit,
					Size = UDim2.fromScale(0.285, 0.225),
					ZIndex = 2,
				}
			else nil,

			if props.isEquipped then
				scope:New "TextLabel" {
					Name = "StatusLabel",
					BackgroundTransparency = 1,
					FontFace = Constants.Font,
					Position = UDim2.fromScale(0, 0.774),
					Size = UDim2.fromScale(1, 0.222),
					Text = "EQUIPPED",
					TextColor3 = Constants.Colors.NavOptionActive,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
					[Children] = {
						scope:New "UIStroke" { Thickness = 2 },
						scope:New "UITextSizeConstraint" { MaxTextSize = 25 },
					},
				}
			elseif props.isOwned then
				scope:New "TextLabel" {
					Name = "StatusLabel",
					BackgroundTransparency = 1,
					FontFace = Constants.Font,
					Position = UDim2.fromScale(0, 0.774),
					Size = UDim2.fromScale(1, 0.222),
					Text = "OWNED",
					TextColor3 = Color3.fromRGB(200, 200, 200),
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
					[Children] = {
						scope:New "UIStroke" { Thickness = 2 },
						scope:New "UITextSizeConstraint" { MaxTextSize = 25 },
					},
				}
			else nil,

			if not props.isOwned then
				scope:New "TextLabel" {
					Name = "Price",
					BackgroundTransparency = 1,
					FontFace = Constants.Font,
					Position = UDim2.fromScale(0.42, 0.774),
					Size = UDim2.fromScale(0.57, 0.222),
					Text = tostring(props.outfitData.Price or 0),
					TextColor3 = Constants.Colors.White,
					TextScaled = true,
					TextXAlignment = Enum.TextXAlignment.Left,
					ZIndex = 2,

					[Children] = {
						scope:New "UIStroke" {
							Name = "UIStroke",
							Thickness = 2,
						},

						scope:New "UITextSizeConstraint" {
							Name = "UITextSizeConstraint",
							MaxTextSize = 42,
						},
					}
				}
			else nil,

			scope:New "TextLabel" {
				Name = "Rarity",
				BackgroundTransparency = 1,
				FontFace = Constants.Font,
				Size = UDim2.fromScale(1, 0.222),
				Text = props.outfitData.Rarity,
				TextColor3 = Constants.Colors.White,
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

return OutfitCard
