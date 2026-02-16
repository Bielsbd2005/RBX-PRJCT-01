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
local Computed = Fusion.Computed

local Constants = require(script.Parent.StoreConstants)

type ItemCardProps = {
	itemName: string,
	price: string,
	rarity: string,
	itemImage: string,
	layoutOrder: number?,
	onClick: (() -> ())?,
	isOwned: boolean?,
	isEquipped: boolean?,
	isLevelLocked: boolean?,
	requiredLevel: number?,
	isSelected: boolean?,
}

local function ItemCard(scope: Fusion.Scope<typeof(Fusion)>, props: ItemCardProps)
	-- Wrapper Frame para layout correcto
	return scope:New "Frame" {
		Name = props.itemName .. "Wrapper",
		BackgroundTransparency = 1,
		LayoutOrder = props.layoutOrder or 0,
		Size = UDim2.fromScale(1, 1), -- Se ajusta a la celda del Grid

		[Children] = {
			scope:New "ImageButton" {
				Name = props.itemName,
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutoButtonColor = false,
				BackgroundColor3 = Constants.Colors.CardBackground,
				ClipsDescendants = true,
				Image = Constants.Assets.CardTexture,
				ImageTransparency = 0.14,
				Position = UDim2.fromScale(0.5, 0.5),
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
						Transparency = Computed(scope, function(use)
							local _equipped = if typeof(props.isEquipped) == "table" then use(props.isEquipped) else props.isEquipped
							local _selected = if typeof(props.isSelected) == "table" then use(props.isSelected) else props.isSelected

							-- return (equipped or selected) and 0 or 0 -- Keeping 0 as per user preference/default
							return 0
						end),
					},

					-- Icono: Moneda o Candado (Solo si no tiene el item y NO está bloqueado por nivel, ya que level locked ocupa todo)
					if not props.isOwned and not props.isLevelLocked then
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

					-- Estado: EQUIPPED / OWNED
					if props.isEquipped then
						scope:New "TextLabel" {
							Name = "StatusLabel",
							BackgroundTransparency = 1,
							FontFace = Constants.Font,
							Position = UDim2.fromScale(0, 0.774),
							Size = UDim2.fromScale(1, 0.222),
							Text = "EQUIPPED",
							TextColor3 = Constants.Colors.NavOptionActive, -- Azul
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
							TextColor3 = Color3.fromRGB(200, 200, 200), -- Gris claro
							TextScaled = true,
							TextWrapped = true,
							ZIndex = 2,
							[Children] = {
								scope:New "UIStroke" { Thickness = 2 },
								scope:New "UITextSizeConstraint" { MaxTextSize = 25 },
							},
						}
					else nil,

					-- Precio o Nivel (Solo si no tiene el item)
					if not props.isOwned then
						scope:New "TextLabel" {
							Name = "Price",
							BackgroundTransparency = 1,
							FontFace = Constants.Font,

							-- Si está bloqueado, ocupa todo el ancho y se centra. Si no, a la derecha del cono
							Position = if props.isLevelLocked then UDim2.fromScale(0, 0.774) else UDim2.fromScale(0.42, 0.774),
							Size = if props.isLevelLocked then UDim2.fromScale(1, 0.222) else UDim2.fromScale(0.57, 0.222),

							Text = if props.isLevelLocked then "LEVEL " .. tostring(props.requiredLevel or 0) else props.price,
							TextColor3 = if props.isLevelLocked then Color3.fromRGB(255, 80, 80) else Constants.Colors.White,

							TextScaled = true,
							TextWrapped = true,
							TextXAlignment = if props.isLevelLocked then Enum.TextXAlignment.Center else Enum.TextXAlignment.Left,
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
						}
					else nil,

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
		}
	}
end

return ItemCard
