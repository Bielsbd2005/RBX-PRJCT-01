local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HatsFolder = ReplicatedStorage:WaitForChild("Hats")

local HatApplier = {}

-- Limpia sombreros anteriores
function HatApplier.Clear(character)
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") and child:GetAttribute("CosmeticHat") then
			child:Destroy()
		end
	end
end

-- Aplica el sombrero con Weld manual
function HatApplier.Apply(character, itemData)
	local head = character:FindFirstChild("Head")
	local hatTemplate = HatsFolder:FindFirstChild(itemData.Name)

	if not head or not hatTemplate then return end

	-- 1. Limpieza
	HatApplier.Clear(character)

	-- 2. Clonación y Configuración
	local newHat = hatTemplate:Clone()
	local handle = newHat:FindFirstChild("Handle")

	if not handle then return end

	newHat:SetAttribute("CosmeticHat", true)
	handle.Anchored = false
	handle.CanCollide = false
	handle.CFrame = head.CFrame -- Mueve el sombrero a la cabeza antes de soldar

	-- 3. Creación del Weld (Soldadura)
	local weld = Instance.new("Weld")
	weld.Name = "AccessoryWeld"
	weld.Part0 = handle
	weld.Part1 = head

	-- Intentar alinear usando los Attachments existentes
	local hatAtt = handle:FindFirstChildOfClass("Attachment")
	local headAtt = head:FindFirstChild(hatAtt and hatAtt.Name or "HatAttachment")

	if hatAtt and headAtt then
		weld.C0 = hatAtt.CFrame
		weld.C1 = headAtt.CFrame
	else
		-- Si no hay attachments, lo posiciona un poco arriba por defecto
		weld.C0 = CFrame.new(0, -0.5, 0)
	end

	weld.Parent = handle
	newHat.Parent = character

	print("Sombrero soldado correctamente a:", character.Name)
end

return HatApplier
