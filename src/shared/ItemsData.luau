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
		WeaponSkins = {
			{
				Name = "PinkDream",
				Rarity = "Rare",
				--Se aplica en la primaryPart
				BaseColor = Color3.fromRGB(253, 176, 255),
				TextureID = "rbxassetid://10051794906",
				TextureColor = Color3.fromRGB(221, 0, 255),
				Animated = true,
				StudsPerTile = 0.7,
				TextureTransparency = 0.5,

				Particles = {
					Enabled = true,
					Texture = "rbxassetid://138722900670829", -- ID de la partícula
					Color = ColorSequence.new(
						Color3.fromRGB(242, 95, 255),
						Color3.fromRGB(242, 95, 255)
					),
					Size = NumberSequence.new(0.111, 0), -- Empieza en 0.5 y desaparece
					Lifetime = NumberRange.new(0.5, 1),
					Rate = 10, -- Cuántas partículas salen
					Speed = NumberRange.new(0.591, 0.591),
				},

				--Se aplica en la secondaryPart (se llama así)
				SecondaryPartColor = Color3.fromRGB(140, 93, 180),
				SecondaryPartTexture = "",
				SecondaryMaterial = Enum.Material.Salt,
			},
			{
				Name = "Default",
				Rarity = "Common",
				BaseColor = Color3.fromRGB(255, 255, 255),
			}
		},
		KillEffects = {
			{
				Name = "Default",
				Price = 5,
				Rarity = "Common",
				Image = "rbxassetid://79175047578893",
			},
		},
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
		Hats = {
			{
				Name = "Hat1",
				Price = 1,
				Rarity = "Rare",
				Image = "rbxassetid://97016006374032", -- Placeholder thumbnail
			},
			{
				Name = "Hat2",
				Price = 2,
				Rarity = "Rare",
				Image = "rbxassetid://94019428436806", -- Placeholder thumbnail
			},
			{
				Name = "Hat3",
				Price = 3,
				Rarity = "Rare",
				Image = "rbxassetid://131331207733432", -- Placeholder thumbnail
			},
		},
		Outfits = {
			{
				Name = "Default",
				Rarity = "Common",
				-- Shirt properties
				ShirtBaseColor = Color3.fromRGB(190, 59, 76),
				ShirtTextureID = "rbxassetid://10051794906",
				ShirtStudsPerTile = 1.175,
				ShirtTextureTransparency = 0.8,
				ShirtMaterial = Enum.Material.Fabric,

				-- Pant properties
				PantMaterial = Enum.Material.Fabric,
				PantColor = Color3.fromRGB(92, 92, 92),
			},
			{
				Name = "Outfit1",
				Rarity = "Rare",
				Price = 3,
				-- Shirt properties
				ShirtBaseColor = Color3.fromRGB(253, 176, 255),
				ShirtTextureID = "rbxassetid://10051794906",
				ShirtStudsPerTile = 1.181,
				ShirtTextureTransparency = 0.7,
				ShirtMaterial = Enum.Material.Salt,

				-- Pant properties
				PantMaterial = Enum.Material.Salt,
				PantColor = Color3.fromRGB(253, 176, 255),
			},
		},
	},
}

return ItemsData
