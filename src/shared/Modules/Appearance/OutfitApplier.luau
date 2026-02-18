--[[
	OutfitApplier
	Módulo para aplicar outfits a un personaje.
	Uses SkinApplier for texture creation to avoid duplication.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SkinApplier = require(ReplicatedStorage.Shared.Modules.Appearance.SkinApplier)

local OutfitApplier = {}

function OutfitApplier.Apply(character: Model, outfitData: { [string]: any })
	if not character or not outfitData then return end

	local targetFolder = character:FindFirstChild("Clothing") or character
	if not targetFolder then return end

	for _, part in targetFolder:GetChildren() do
		if not part:IsA("BasePart") then continue end

		-- Parte de arriba (Shirts)
		if string.find(part.Name, "T%-Shirt") then
			part.Color = outfitData.ShirtBaseColor or part.Color
			part.Material = outfitData.ShirtMaterial or Enum.Material.Plastic
			part.Transparency = 0 -- Asegurar visible

			-- Limpiar texturas anteriores
			for _, child in part:GetChildren() do
				if child:IsA("Texture") and string.find(child.Name, "ShirtTexture_") then
					child:Destroy()
				end
			end

			if outfitData.ShirtTextureID and outfitData.ShirtTextureID ~= "" then
				SkinApplier.applyTexturesToPart(part, outfitData.ShirtTextureID, {
					namePrefix = "ShirtTexture_",
					transparency = outfitData.ShirtTextureTransparency or 0,
					studsPerTile = outfitData.ShirtStudsPerTile or 1,
					color = Color3.new(1, 1, 1),
				})
			end

		-- Parte de abajo (Pants)
		elseif string.find(part.Name, "Pant") then
			part.Color = outfitData.PantColor or part.Color
			part.Material = outfitData.PantMaterial or Enum.Material.Plastic
			part.Transparency = 0 -- Asegurar visible
		end
	end
end

return OutfitApplier
