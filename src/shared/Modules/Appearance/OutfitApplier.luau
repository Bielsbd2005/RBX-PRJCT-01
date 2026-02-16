--[[
	OutfitApplier
	Módulo para aplicar outfits a un personaje.
]]

local OutfitApplier = {}

function OutfitApplier.Apply(character: Model, outfitData: { [string]: any })
	if not character or not outfitData then return end

	local clothingFolder = character:FindFirstChild("Clothing")
	if not clothingFolder then return end

	for _, part in clothingFolder:GetChildren() do
		if not part:IsA("BasePart") then continue end

		-- Parte de arriba (Shirts)
		if string.find(part.Name, "T%-Shirt") then
			part.Color = outfitData.ShirtBaseColor or part.Color
			part.Material = outfitData.ShirtMaterial or Enum.Material.Plastic
			part.Transparency = 0 -- Asegurar visible

			-- Limpiar texturas anteriores si existen y queremos reemplazarlas limpiamente
			-- (O simplemente añadir nuevas encima, pero mejor limpiar)
			for _, child in part:GetChildren() do
				if child:IsA("Texture") and string.find(child.Name, "ShirtTexture_") then
					child:Destroy()
				end
			end

			if outfitData.ShirtTextureID and outfitData.ShirtTextureID ~= "" then
				for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
					local t = Instance.new("Texture")
					t.Name = "ShirtTexture_" .. face.Name
					t.Face = face
					t.Texture = outfitData.ShirtTextureID
					t.Transparency = outfitData.ShirtTextureTransparency or 0
					t.StudsPerTileU = outfitData.ShirtStudsPerTile or 1
					t.StudsPerTileV = outfitData.ShirtStudsPerTile or 1
                    t.Color3 = Color3.new(1,1,1)
					t.Parent = part
				end
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
