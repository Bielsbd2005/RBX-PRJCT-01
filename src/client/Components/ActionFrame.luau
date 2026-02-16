--[[
	ActionFrame
	Frame que aparece desde abajo para comprar items.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Fusion = require(ReplicatedStorage.Packages.fusion)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Spring = Fusion.Spring
local Value = Fusion.Value
local Observer = Fusion.Observer

local Constants = require(script.Parent.StoreConstants)

type ActionFrameProps = {
	price: Fusion.UsedAs<string>,
	title: Fusion.UsedAs<string>?,
	isLocked: Fusion.UsedAs<boolean>?,
	isVisible: Fusion.UsedAs<boolean>,
	onPurchase: () -> (),
}

local function ActionFrame(scope: Fusion.Scope<typeof(Fusion)>, props: ActionFrameProps)

	-- Animación de posición Y
	-- Visible: 0.856 (posición original del usuario)
	-- Oculto: 1.1 (fuera de pantalla hacia abajo)
	local targetY = Computed(scope, function(use)
		return use(props.isVisible) and 0.856 or 1.2
	end)

	local springY = Spring(scope, targetY, 25, 0.8)

	-- Animación de "Pop" al cambiar el precio/item
	local buttonScale = Value(scope, 1)
	local springScale = Spring(scope, buttonScale, 50, 0.5)

	-- Observar cambios en el precio para disparar la animación
	local obs = Observer(scope, props.price)
	obs:onChange(function()
		buttonScale:set(1.1)
		task.delay(0.05, function()
			buttonScale:set(1)
		end)
	end)

	-- Colores para el gradiente
	local gradientColors = Computed(scope, function(use)
		if use(props.isLocked) then
			-- Gray gradient for locked state
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(150, 150, 150)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 100, 100)),
			})
		else
			-- Gold gradient for purchase/equip
			return ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(252, 255, 87)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(244, 204, 74)),
			})
		end
	end)

	-- Icono de moneda o candado
	local currencyIcon = Computed(scope, function(use)
		if use(props.isLocked) then
			return "rbxassetid://121709682417919" -- Lock icon
		else
			return "rbxassetid://96222277892751" -- Bill icon
		end
	end)

    -- Título del botón
    local buttonTitle = Computed(scope, function(use)
        if use(props.isLocked) then
            return "LOCKED"
        else
            return use(props.title) or "PURCHASE"
        end
    end)

	return scope:New "Frame" {
		Name = "ActionFrame",
		BackgroundTransparency = 1,
		-- Position = UDim2.fromScale(-6.35783e-08, 0.856217), -- Original
		Position = Computed(scope, function(use)
			return UDim2.fromScale(0, use(springY))
		end),
		Size = UDim2.fromScale(0.631, 0.0919131),
		AnchorPoint = Vector2.new(0, 0), -- Asumo default 0,0 basado en Position original

		[Children] = {
			scope:New "UIListLayout" {
				Name = "UIListLayout",
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0.03, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			},

			scope:New "ImageButton" {
				Name = "Template",
				BackgroundColor3 = Color3.new(1, 1, 1),
				-- Interactable = false, -- User code had this, but we need click to purchase?
				-- Actually the user provided code has 'Interactable = false' on the CONTAINER button?
				-- Wait, the user code has an ImageButton named "Template" wrapping the elements.
				-- It likely serves as the background/container for the visual elements.
				-- Since we need to click it to purchase, let's allow it to be interactable or wrap it.
				-- The user title says "PURCHASE", so this whole button is likely the button.
				-- I will remove 'Interactable = false' or ensure the click works.

				Size = UDim2.fromScale(0.292219, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.353891 + (0.292219/2), 0.5), -- Recalculate position for center anchor


				[OnEvent "Activated"] = props.onPurchase,

				[Children] = {
					scope:New "UIScale" {
						Scale = springScale,
					},

					scope:New "UIStroke" {
						Name = "BorderStroke",
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Thickness = 4,
					},

					scope:New "UICorner" {
						Name = "UICorner",
						CornerRadius = UDim.new(0.2, 0),
					},

					scope:New "ImageLabel" {
						Name = "CurrencyImage",
						BackgroundTransparency = 1,
						Image = currencyIcon,
						Position = UDim2.fromScale(0.132791, 0.441273),
						ScaleType = Enum.ScaleType.Fit,
						Size = UDim2.fromScale(0.197018, 0.555362),
						ZIndex = 2,
					},

					scope:New "TextLabel" {
						Name = "Price",
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/HighwayGothic.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.fromScale(0.393267, 0.431398),
						Size = UDim2.fromScale(0.605248, 0.565237),
						Text = props.price,
						TextColor3 = Color3.fromRGB(253, 255, 255),
						TextScaled = true,
						TextXAlignment = Enum.TextXAlignment.Left,
						ZIndex = 2,

						[Children] = {
							scope:New "UIStroke" {
								Name = "UIStroke",
								Thickness = 4,
							},

							scope:New "UITextSizeConstraint" {
								Name = "UITextSizeConstraint",
								MaxTextSize = 50,
							},
						}
					},

					scope:New "UIGradient" {
						Name = "UIGradient",
						Color = gradientColors,
						Rotation = 90,
					},

					scope:New "TextLabel" {
						Name = "Title",
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/HighwayGothic.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.fromScale(-0.00406972, 0.111219),
						Size = UDim2.fromScale(1, 0.330054),
						Text = buttonTitle,
						TextColor3 = Color3.fromRGB(0, 0, 0), -- Black default
						TextScaled = true,
						ZIndex = 2,

						[Children] = {
							scope:New "UITextSizeConstraint" {
								Name = "UITextSizeConstraint",
								MaxTextSize = 50,
							},
						}
					},
				}
			},
		}
	}
end

return ActionFrame
