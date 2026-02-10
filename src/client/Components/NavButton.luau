--[[
	NavButton
	Botón de opción lateral reutilizable para la navegación de la Store.

	Props:
		name: string       — Nombre del botón
		layoutOrder: number — Orden en el layout
		onClick: (() -> ())?  — Callback opcional al hacer click
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local Constants = require(script.Parent.StoreConstants)

type NavButtonProps = {
	name: string,
	layoutOrder: number,
	onClick: (() -> ())?,
}

local function NavButton(scope: Fusion.Scope<typeof(Fusion)>, props: NavButtonProps)
	return scope:New "ImageButton" {
		Name = props.name,
		BackgroundColor3 = Constants.Colors.Background,
		Image = Constants.Assets.Placeholder,
		ImageTransparency = 1,
		LayoutOrder = props.layoutOrder,
		Size = UDim2.fromScale(1, 0.301205),

		[OnEvent "Activated"] = function()
			if props.onClick then
				props.onClick()
			end
		end,

		[Children] = {
			scope:New "UICorner" {
				Name = "UICorner",
			},
		},
	}
end

return NavButton
