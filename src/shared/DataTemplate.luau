--[[
	DataTemplate
	Plantilla por defecto para los datos de cada jugador.
	Usado por ProfileStore (servidor) y DataController (cliente).

	Ruta: ReplicatedStorage.Shared.DataTemplate
]]

return {
	level = 1,
	xp = 0,
	cash = 100,
	gems = 0,

	stats = {
		kills = 0,
		deaths = 0,
		headshotKills = 0,
		highestStreak = 0,
		playTime = 0,
	},

	inventory = {
		KillEffects = {},
		Faces = {},
		Outfits = { "Default" },
		Hats = {},
		Weapons = { "Default" },
		WeaponSkins = { "Default" },
	},

	equipped = {
		KillEffects = "",
		Faces = "",
		Outfits = "Default",
		Hats = "",
		Weapons = "Default",
		WeaponSkins = "Default",
	},

	settings = {
		mouseSensitivity = 1,
		musicVolume = 0.8,
		sfxVolume = 1,
	},

	meta = {
		createdAt = 0,
		updatedAt = 0,
		lastDailyReward = 0,
		isBanned = false,
	},
}
