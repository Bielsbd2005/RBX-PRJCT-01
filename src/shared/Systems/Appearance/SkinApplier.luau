--[[
	SkinApplier
	Unified module for applying weapon skins (textures, materials, particles, animation).
	Used by LockerUI, SkinCard, and OutfitApplier.

	Ruta: ReplicatedStorage.Shared.Modules.Appearance.SkinApplier
]]

local RunService = game:GetService("RunService")

local SkinApplier = {}

-- Constants
local DEFAULT_TILE_SIZE = 2
local TEXTURE_SPEED_U = 0.5
local TEXTURE_SPEED_V = 0

--------------------------------------------------------------------------------
-- Low-level: Create Texture instances on all 6 faces of a BasePart
--------------------------------------------------------------------------------
function SkinApplier.applyTexturesToPart(
	part: BasePart,
	textureId: string,
	config: {
		namePrefix: string?,
		transparency: number?,
		studsPerTile: number?,
		color: Color3?,
	}?
): { Texture }
	local textures = {}
	local cfg = config or {}
	local prefix = cfg.namePrefix or "SkinTexture_"

	for _, face in ipairs(Enum.NormalId:GetEnumItems()) do
		local t = Instance.new("Texture")
		t.Name = prefix .. face.Name
		t.Face = face
		t.Texture = textureId
		t.Transparency = cfg.transparency or 0
		t.StudsPerTileU = cfg.studsPerTile or DEFAULT_TILE_SIZE
		t.StudsPerTileV = cfg.studsPerTile or DEFAULT_TILE_SIZE
		t.Color3 = cfg.color or Color3.new(1, 1, 1)
		t.Parent = part
		table.insert(textures, t)
	end

	return textures
end

--------------------------------------------------------------------------------
-- Cleanup: Remove all skin-related children from a model
--------------------------------------------------------------------------------
function SkinApplier.cleanup(model: Model)
	if not model then return end

	for _, desc in model:GetDescendants() do
		if desc:IsA("Texture") then
			local name = desc.Name
			if
				string.find(name, "SkinTexture_")
				or string.find(name, "SecondaryTexture_")
				or string.find(name, "ShirtTexture_")
			then
				desc:Destroy()
			end
		elseif desc:IsA("ParticleEmitter") and desc.Name == "SkinParticles" then
			desc:Destroy()
		end
	end
end

--------------------------------------------------------------------------------
-- Apply: Full skin application to a weapon model
-- Returns a table of all created Texture instances (for animation)
--------------------------------------------------------------------------------
function SkinApplier.apply(model: Model, skinData: { [string]: any }): { Texture }
	if not model or not skinData then return {} end

	-- Clean previous skin artifacts first
	SkinApplier.cleanup(model)

	local textures = {}

	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			-- Skip invisible parts (hitboxes, etc.) to save memory/draw calls
			if part.Transparency == 1 then
				continue
			end

			-- Logic for SecondaryPart
			if part.Name == "SecondaryPart" then
				part.Color = skinData.SecondaryPartColor or part.Color

				if skinData.SecondaryMaterial then
					part.Material = skinData.SecondaryMaterial
				end

				if part:IsA("MeshPart") then
					part.TextureID = skinData.SecondaryPartTexture or ""
				elseif skinData.SecondaryPartTexture and skinData.SecondaryPartTexture ~= "" then
					local created = SkinApplier.applyTexturesToPart(part, skinData.SecondaryPartTexture, {
						namePrefix = "SecondaryTexture_",
						transparency = skinData.TextureTransparency or 0,
						studsPerTile = skinData.StudsPerTile or DEFAULT_TILE_SIZE,
						color = Color3.new(1, 1, 1),
					})
					for _, t in created do
						table.insert(textures, t)
					end
				end

			-- Logic for other parts (Primary Style)
			else
				part.Color = skinData.BaseColor
				part.Material = skinData.Material or Enum.Material.Plastic

				-- Apply textures to all faces if TextureID exists
				if skinData.TextureID and skinData.TextureID ~= "" then
					local created = SkinApplier.applyTexturesToPart(part, skinData.TextureID, {
						namePrefix = "SkinTexture_",
						transparency = skinData.TextureTransparency or 0,
						studsPerTile = skinData.StudsPerTile or DEFAULT_TILE_SIZE,
						color = skinData.TextureColor or Color3.new(1, 1, 1),
					})
					for _, t in created do
						table.insert(textures, t)
					end
				end

				-- Particles (only on PrimaryPart)
				if part == model.PrimaryPart and skinData.Particles and skinData.Particles.Enabled then
					local p = Instance.new("ParticleEmitter")
					p.Name = "SkinParticles"
					p.Texture = skinData.Particles.Texture
					p.Color = skinData.Particles.Color
					p.Size = skinData.Particles.Size
					p.Lifetime = skinData.Particles.Lifetime
					p.Rate = skinData.Particles.Rate
					p.Speed = skinData.Particles.Speed
					p.Parent = part
				end
			end
		end
	end

	return textures
end

--------------------------------------------------------------------------------
-- Animation: Start UV-scrolling on a set of textures
-- Uses Heartbeat (NOT RenderStepped) for better performance.
-- Returns the connection so the caller can manage cleanup.
--------------------------------------------------------------------------------
function SkinApplier.startAnimation(
	textures: { Texture },
	skinData: { [string]: any },
	parentCheck: Instance? -- Object to verify still exists (e.g. weapon model)
): RBXScriptConnection?
	if not skinData.Animated then return nil end
	if not textures or #textures == 0 then return nil end

	local currentU = 0
	local currentV = 0
	local tileSize = skinData.StudsPerTile or DEFAULT_TILE_SIZE

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if parentCheck and (not parentCheck.Parent) then
			if connection then connection:Disconnect() end
			return
		end

		currentU = (currentU + TEXTURE_SPEED_U * dt) % tileSize
		currentV = (currentV + TEXTURE_SPEED_V * dt) % tileSize

		for _, t in textures do
			t.OffsetStudsU = currentU
			t.OffsetStudsV = currentV
		end
	end)

	return connection
end

return SkinApplier
