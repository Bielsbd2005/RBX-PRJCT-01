--!strict

--[[
    ItemsData
    Base de datos estática e inmutable de items.
]]

----- Tipos Exportados -----
export type ParticleConfig = {
	Enabled: boolean,
	Texture: string,
	Color: ColorSequence,
	Size: NumberSequence,
	Lifetime: NumberRange,
	Rate: number,
	Speed: NumberRange,
}

export type ItemData = {
	Name: string,
	Rarity: "Common" | "Rare" | "Epic" | "Legendary",
	Price: number?,
	Level: number?,
	Image: string?,

	-- Propiedades de Skins
	BaseColor: Color3?,
	TextureID: string?,
	TextureColor: Color3?,
	Animated: boolean?,
	StudsPerTile: number?,
	TextureTransparency: number?,
	Particles: ParticleConfig?,

	-- Propiedades Secundarias / Ropa
	SecondaryPartColor: Color3?,
	SecondaryPartTexture: string?,
	SecondaryMaterial: Enum.Material?,
	ShirtBaseColor: Color3?,
	ShirtMaterial: Enum.Material?,
	PantColor: Color3?,
	[string]: any -- Permite flexibilidad extra
}

export type CategoryData = {
	[string]: { ItemData } -- Lista ordenada para UI
}

----- Helpers (Reducen ruido visual y errores) -----
local function asset(id: number | string): string
	return "rbxassetid://" .. tostring(id)
end

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

----- Base de Datos -----
local ItemsData: { [string]: CategoryData } = {
	Arsenal = {
		Weapons = {
			{
				Name = "Default",
				Price = 0,
				Level = 0,
				Rarity = "Rare",
				Image = asset(110518081864282),
			},
			{
				Name = "Weapon2",
				Price = 2,
				Level = 0,
				Rarity = "Rare",
				Image = asset(108946658716262),
			},
			{
				Name = "Weapon3",
				Price = 3,
				Level = 3,
				Rarity = "Rare",
				Image = asset(87132897706192),
			},
			-- ... (Puedes comprimir líneas si prefieres legibilidad vertical)
			{ Name = "Weapon4", Price = 4, Level = 4, Rarity = "Rare", Image = asset(124132998559200) },
			{ Name = "Weapon5", Price = 5, Level = 5, Rarity = "Rare", Image = asset(72433429395276) },
			{ Name = "Weapon6", Price = 6, Level = 6, Rarity = "Rare", Image = asset(102465718265447) },
			{ Name = "Weapon",  Price = 7, Level = 7, Rarity = "Rare", Image = asset(76043980713122) },
		},
		WeaponSkins = {
			{
				Name = "PinkDream",
				Rarity = "Rare",

				-- Primary
				BaseColor = rgb(253, 176, 255),
				TextureID = asset(10051794906),
				TextureColor = rgb(221, 0, 255),
				Animated = true,
				StudsPerTile = 0.7,
				TextureTransparency = 0.5,

				Particles = {
					Enabled = true,
					Texture = asset(138722900670829),
					Color = ColorSequence.new(rgb(242, 95, 255)),
					Size = NumberSequence.new(0.111, 0),
					Lifetime = NumberRange.new(0.5, 1),
					Rate = 10,
					Speed = NumberRange.new(0.591, 0.591),
				},

				-- Secondary
				SecondaryPartColor = rgb(140, 93, 180),
				SecondaryPartTexture = "",
				SecondaryMaterial = Enum.Material.Salt,
			},
			{
				Name = "Default",
				Rarity = "Common",
				BaseColor = rgb(255, 255, 255),
			}
		},
		KillEffects = {
			{
				Name = "Default",
				Price = 5,
				Rarity = "Common",
				Image = asset(79175047578893),
			},
		},
	},
	Cosmetics = {
		Faces = {
			{ Name = "Face1", Price = 1, Rarity = "Rare", Image = asset(79175047578893) },
			{ Name = "Face2", Price = 2, Rarity = "Rare", Image = asset(18571318923) },
			{ Name = "Face3", Price = 3, Rarity = "Rare", Image = asset(97580829209799) },
			{ Name = "Face4", Price = 4, Rarity = "Rare", Image = asset(94789972115859) },
			{ Name = "Face5", Price = 5, Rarity = "Rare", Image = asset(17285554126) },
			{ Name = "Face6", Price = 6, Rarity = "Rare", Image = asset(70391209868621) },
			{ Name = "Face7", Price = 7, Rarity = "Rare", Image = asset(18626918162) },
			{ Name = "Face8", Price = 8, Rarity = "Common", Image = asset(17373537487) },
			{ Name = "Face9", Price = 9, Rarity = "Rare", Image = asset(118980363558612) },
			{ Name = "Face10", Price = 10, Rarity = "Rare", Image = asset(18870092964) },
			{ Name = "Face11", Price = 11, Rarity = "Rare", Image = asset(101878427779141) },
			{ Name = "Face12", Price = 12, Rarity = "Rare", Image = asset(112166980943980) },
		},
		Hats = {
			{ Name = "Hat1", Price = 1, Rarity = "Rare", Image = asset(97016006374032) },
			{ Name = "Hat2", Price = 2, Rarity = "Rare", Image = asset(94019428436806) },
			{ Name = "Hat3", Price = 3, Rarity = "Rare", Image = asset(131331207733432) },
		},
		Outfits = {
			{
				Name = "Default",
				Rarity = "Common",

				ShirtBaseColor = rgb(190, 59, 76),
				ShirtTextureID = asset(10051794906),
				ShirtStudsPerTile = 1.175,
				ShirtTextureTransparency = 0.8,
				ShirtMaterial = Enum.Material.Fabric,

				PantMaterial = Enum.Material.Fabric,
				PantColor = rgb(92, 92, 92),
			},
			{
				Name = "Outfit1",
				Rarity = "Rare",
				Price = 3,

				ShirtBaseColor = rgb(253, 176, 255),
				ShirtTextureID = asset(10051794906),
				ShirtStudsPerTile = 1.181,
				ShirtTextureTransparency = 0.7,
				ShirtMaterial = Enum.Material.Salt,

				PantMaterial = Enum.Material.Salt,
				PantColor = rgb(253, 176, 255),
			},
		},
	},
}

-- Inmutabilidad: Previene errores de sobreescritura accidental en tiempo de ejecución
table.freeze(ItemsData)

return ItemsData
