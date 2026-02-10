--[[
	ItemCard
	Tarjeta de item reutilizable para el grid de la Store.

	Props:
		itemName: string     — Nombre del item
		price: string        — Precio formateado (ej: "1,908")
		rarity: string       — Texto de rareza (ej: "EPIC")
		itemImage: string    — Asset ID de la imagen del item
		layoutOrder: number? — Orden en el grid
		onClick: (() -> ())? — Callback al hacer click
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.fusion)
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

local Constants = require(script.Parent.StoreConstants)

type ItemCardProps = {
	itemName: string,
	price: string,
	rarity: string,
	itemImage: string,
	layoutOrder: number?,
	onClick: (() -> ())?,
}

local function ItemCard(scope: Fusion.Scope<typeof(Fusion)>, props: ItemCardProps)
	return scope:New "ImageButton" {
		Name = props.itemName,
		AutoButtonColor = false,
		BackgroundColor3 = Constants.Colors.CardBackground,
		ClipsDescendants = true,
		Image = Constants.Assets.CardTexture,
		ImageTransparency = 0.14,
		LayoutOrder = props.layoutOrder or 0,
		Size = UDim2.fromScale(1, 1),

		[OnEvent "Activated"] = function()
			if props.onClick then
				props.onClick()
			end
		end,

		[Children] = {
			scope:New "UICorner" {
				Name = "UICorner",
				CornerRadius = UDim.new(0.08, 0),
			},

			scope:New "UIStroke" {
				Name = "UIStroke",
				Color = Constants.Colors.CardStroke,
				Thickness = 5,
			},

			-- Icono de moneda
			scope:New "ImageLabel" {
				Name = "CurrencyImage",
				BackgroundTransparency = 1,
				Image = Constants.Assets.CurrencyIcon,
				Position = UDim2.fromScale(0.059, 0.778),
				ScaleType = Enum.ScaleType.Fit,
				Size = UDim2.fromScale(0.285, 0.225),
				ZIndex = 2,
			},

			-- Precio
			scope:New "TextLabel" {
				Name = "Price",
				BackgroundTransparency = 1,
				FontFace = Constants.Font,
				Position = UDim2.fromScale(0.42, 0.774),
				Size = UDim2.fromScale(0.57, 0.222),
				Text = props.price,
				TextColor3 = Constants.Colors.White,
				TextScaled = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				ZIndex = 2,

				[Children] = {
					scope:New "UIStroke" {
						Name = "UIStroke",
						Thickness = 2,
					},
					scope:New "UITextSizeConstraint" {
						MaxTextSize = 42,
					},
				},
			},

			-- Rareza
			scope:New "TextLabel" {
				Name = "Rarity",
				BackgroundTransparency = 1,
				FontFace = Constants.Font,
				Position = UDim2.fromScale(0, 0),
				Size = UDim2.fromScale(1, 0.222),
				Text = props.rarity,
				TextColor3 = Constants.Colors.White,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 2,

				[Children] = {
					scope:New "UIStroke" {
						Name = "UIStroke",
						Thickness = 2,
					},
					scope:New "UITextSizeConstraint" {
						MaxTextSize = 46,
					},
				},
			},

			-- Imagen del item
			scope:New "ImageLabel" {
				Name = "ItemImage",
				BackgroundTransparency = 1,
				Image = props.itemImage,
				ImageColor3 = Color3.fromRGB(249, 253, 255),
				Position = UDim2.fromScale(0.041, 0.092),
				Size = UDim2.fromScale(0.916, 0.811),
			},
		},
	}
end

return ItemCard
