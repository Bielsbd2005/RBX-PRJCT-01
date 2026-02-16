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
	TabActive = Color3.fromRGB(85, 126, 239),
	TabInactive = Color3.fromRGB(54, 54, 76),
	NavOptionActive = Color3.fromRGB(85, 126, 239),
	Selected = Color3.fromRGB(255, 255, 255),
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
	LockIcon = "rbxassetid://121709682417919",
	Placeholder = "rbxasset://textures/ui/GuiImagePlaceholder.png",
}

-- Tabs de la tienda (se iteran para generar los botones)
StoreConstants.Tabs = {
	{
		Name = "Arsenal",
		Text = "ARSENAL",
		LayoutOrder = 1,
	},
	{
		Name = "Cosmetics",
		Text = "COSMETICS",
		LayoutOrder = 2,
	},
}

-- Opciones de navegación por tab
StoreConstants.NavOptions = {
	Arsenal = {
		{ Name = "Weapons",     Image = "rbxassetid://86111407632869", Title = "Weapons" },
		{ Name = "WeaponSkins", Image = "rbxassetid://86111407632869", Title = "Weapon Skins" },
		{ Name = "KillEffects", Image = "rbxassetid://86111407632869", Title = "Kill Effects" },
	},
	Cosmetics = {
		{ Name = "Hats",  Image = "rbxassetid://86111407632869", Title = "Hats" },
		{ Name = "Faces", Image = "rbxassetid://86111407632869", Title = "Faces" },
		{ Name = "Outfits", Image = "rbxassetid://86111407632869", Title = "Outfits" },
	},
}

return StoreConstants
