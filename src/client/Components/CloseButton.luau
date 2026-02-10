--[[
	CloseButton
	Botón X rojo reutilizable para cerrar GUIs.

	Props:
		position: UDim2?    — Posición (por defecto esquina superior derecha)
		size: UDim2?        — Tamaño (por defecto escala proporcional)
		onClose: () -> ()   — Callback al presionar
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent
local Value = Fusion.Value

local Constants = require(script.Parent.StoreConstants)

type CloseButtonProps = {
	position: UDim2?,
	size: UDim2?,
	onClose: () -> (),
}

local function CloseButton(scope: Fusion.Scope<typeof(Fusion)>, props: CloseButtonProps)
	local isHovering = Value(scope, false)
	local isPressed = Value(scope, false)

	local scaleSpring = Fusion.Spring(scope, Fusion.Computed(scope, function(use)
		if use(isPressed) then
			return 0.9 -- Más pequeño al clicar
		elseif use(isHovering) then
			return 1.1 -- Más grande al pasar ratón
		else
			return 1 -- Normal
		end
	end), 40, 0.5)
	return scope:New "ImageButton" {
		Name = "Close",
		BackgroundColor3 = Constants.Colors.CloseBase,
		Position = props.position or UDim2.fromScale(0.946, 0.08),
		Size = props.size or UDim2.fromScale(0.041, 0.07),

		[OnEvent "Activated"] = props.onClose,
		[OnEvent "MouseEnter"] = function() isHovering:set(true) end,
		[OnEvent "MouseLeave"] = function() isHovering:set(false) isPressed:set(false) end,
		[OnEvent "MouseButton1Down"] = function() isPressed:set(true) end,
		[OnEvent "MouseButton1Up"] = function() isPressed:set(false) end,

		[Children] = {
			scope:New "UIScale" {
				Scale = scaleSpring,
			},
			scope:New "UICorner" {
				Name = "UICorner",
				CornerRadius = UDim.new(0.15, 0),
			},

			scope:New "UIAspectRatioConstraint" {
				AspectRatio = 1,
			},

			scope:New "TextLabel" {
				Name = "TextLabel",
				BackgroundColor3 = Constants.Colors.CloseTop,
				FontFace = Constants.Font,
				Position = UDim2.fromScale(0, -0.013),
				Size = UDim2.fromScale(1, 0.9),
				Text = "X",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextWrapped = true,

				[Children] = {
					scope:New "UICorner" {
						Name = "UICorner",
						CornerRadius = UDim.new(0.15, 0),
					},
					scope:New "UITextSizeConstraint" {
						MaxTextSize = 40,
					},
				},
			},

			scope:New "UIStroke" {
				Name = "UIStroke",
				Thickness = 3,
			},
		},
	}
end

return CloseButton
