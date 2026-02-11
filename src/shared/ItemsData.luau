--[[
	ItemsData
	Base de datos estática de todos los items del juego.
	Organizado por Categoría > Sección (Tab > Option).
]]

local ItemsData = {
	Arsenal = {
		Weapons = {
			{
				Name = "Default",
				Price = 0,
				Level = 0,
				Rarity = "Rare",
				Image = "rbxassetid://110518081864282",
			},
			{
				Name = "Weapon2",
				Price = 2,
				Level = 0,
				Rarity = "Rare",
				Image = "rbxassetid://108946658716262",
			},
			{
				Name = "Weapon3",
				Price = 3,
				Level = 3,
				Rarity = "Rare",
				Image = "rbxassetid://87132897706192",
			},
			{
				Name = "Weapon4",
				Price = 4,
				Level = 4,
				Rarity = "Rare",
				Image = "rbxassetid://124132998559200",
			},
			{
				Name = "Weapon5",
				Price = 5,
				Level = 5,
				Rarity = "Rare",
				Image = "rbxassetid://72433429395276",
			},
			{
				Name = "Weapon6",
				Price = 6,
				Level = 6,
				Rarity = "Rare",
				Image = "rbxassetid://102465718265447",
			},
			{
				Name = "Weapon",
				Price = 7,
				Level = 7,
				Rarity = "Rare",
				Image = "rbxassetid://76043980713122",
			},
		},
		WeaponSkins = {},
		KillEffects = {},
	},
	Cosmetics = {
		Faces = {
			{
				Name = "Face1",
				Price = 1,
				Rarity = "Rare",
				Image = "rbxassetid://79175047578893",
			},
			{
				Name = "Face2",
				Price = 2,
				Rarity = "Rare",
				Image = "rbxassetid://18571318923",
			},
			{
				Name = "Face3",
				Price = 3,
				Rarity = "Rare",
				Image = "rbxassetid://97580829209799",
			},
			{
				Name = "Face4",
				Price = 4,
				Rarity = "Rare",
				Image = "rbxassetid://94789972115859",
			},
			{
				Name = "Face5",
				Price = 5,
				Rarity = "Rare",
				Image = "rbxassetid://17285554126",
			},
			{
				Name = "Face6",
				Price = 6,
				Rarity = "Rare",
				Image = "rbxassetid://70391209868621",
			},
			{
				Name = "Face7",
				Price = 7,
				Rarity = "Rare",
				Image = "rbxassetid://18626918162",
			},
			{
				Name = "Face8",
				Price = 8,
				Rarity = "Common", -- Missing rarity in request, defaulted to Common
				Image = "rbxassetid://17373537487",
			},
			{
				Name = "Face9",
				Price = 9,
				Rarity = "Rare",
				Image = "rbxassetid://118980363558612",
			},
			{
				Name = "Face10",
				Price = 10,
				Rarity = "Rare",
				Image = "rbxassetid://18870092964",
			},
			{
				Name = "Face11",
				Price = 11,
				Rarity = "Rare",
				Image = "rbxassetid://101878427779141",
			},
			{
				Name = "Face12",
				Price = 12,
				Rarity = "Rare",
				Image = "rbxassetid://112166980943980",
			},
		},
		Hats = {},
		Body = {},
	},
}

return ItemsData
