--[[
	StoreConstants
	Constantes centralizadas para la Store UI.
	Colores, fuentes, y configuraciones de tabs.
]]

local StoreConstants = {}

-- Paleta de colores
StoreConstants.Colors = {
	Background = Color3.fromRGB(25, 25, 25),
	White = Color3.fromRGB(253, 255, 255),
	CardBackground = Color3.fromRGB(244, 250, 255),
	CardStroke = Color3.fromRGB(131, 131, 131),
	CloseBase = Color3.fromRGB(202, 44, 73),
	CloseTop = Color3.fromRGB(255, 63, 77),
	TabCosmetics = Color3.fromRGB(54, 54, 76),
	TabArsenal = Color3.fromRGB(85, 126, 239),
}

-- Fuente principal
StoreConstants.Font = Font.new(
	"rbxasset://fonts/families/HighwayGothic.json",
	Enum.FontWeight.Bold,
	Enum.FontStyle.Normal
)

-- Asset IDs
StoreConstants.Assets = {
	CardTexture = "rbxassetid://71136216021149",
	CurrencyIcon = "rbxassetid://96222277892751",
	Placeholder = "rbxasset://textures/ui/GuiImagePlaceholder.png",
}

-- Tabs de la tienda (se iteran para generar los botones)
StoreConstants.Tabs = {
	{
		Name = "Arsenal",
		Text = "ARSENAL",
		Color = Color3.fromRGB(85, 126, 239),
		LayoutOrder = 1,
	},
	{
		Name = "Cosmetics",
		Text = "COSMETICS",
		Color = Color3.fromRGB(54, 54, 76),
		LayoutOrder = 2,
	},
}

return StoreConstants
