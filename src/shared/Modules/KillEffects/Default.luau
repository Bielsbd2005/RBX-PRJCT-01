local RagdollModule = {}

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local JOINT_MAX_ANGLE = 55
local THROW_FORCE = 50
local THROW_FORCE_UP_MULT = 1.5
local PRINT_DEBUG = false
local RAGDOLL_HEAD_AS_JOINT = false

local rng = Random.new()

local function dprint(...)
	if PRINT_DEBUG then
		print("[Ragdoll]", ...)
	end
end

local function anchorCharacter(char: Instance, anchored: boolean)
	for _, child in ipairs(char:GetChildren()) do
		if child:IsA("BasePart") then
			child.Anchored = anchored
		end
	end
end

local function destroyMotors(char: Instance)
	for _, desc in ipairs(char:GetDescendants()) do
		if desc:IsA("Motor6D") then
			desc:Destroy()
		end
	end
end

local function safeBallJoint(att0: Attachment?, att1: Attachment?)
	if not att0 or not att1 then return end
	local joint = Instance.new("BallSocketConstraint")
	joint.Attachment0 = att0
	joint.Attachment1 = att1
	joint.LimitsEnabled = true
	joint.UpperAngle = JOINT_MAX_ANGLE
	joint.Parent = att0
end

local function safeWeld(p0: BasePart?, p1: BasePart?)
	if not p0 or not p1 then return end
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = p0
	weld.Part1 = p1
	weld.Parent = p0
end

local function isR15(char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum and hum.RigType == Enum.HumanoidRigType.R15
end

local function applyThrowImpulse(lowerTorso: BasePart?)
	if not lowerTorso then return end
	local vx = rng:NextInteger(-THROW_FORCE, THROW_FORCE)
	local vy = rng:NextInteger(0, THROW_FORCE) * THROW_FORCE_UP_MULT
	local vz = rng:NextInteger(-THROW_FORCE, THROW_FORCE)
	lowerTorso.AssemblyLinearVelocity = Vector3.new(vx, vy, vz)
end

local function buildRagdollOnce(char: Model)
	local upperTorso = char:FindFirstChild("UpperTorso")
	local lowerTorso = char:FindFirstChild("LowerTorso")
	local head = char:FindFirstChild("Head")
	local ruArm = char:FindFirstChild("RightUpperArm")
	local luArm = char:FindFirstChild("LeftUpperArm")
	local rlArm = char:FindFirstChild("RightLowerArm")
	local llArm = char:FindFirstChild("LeftLowerArm")
	local rHand = char:FindFirstChild("RightHand")
	local lHand = char:FindFirstChild("LeftHand")
	local ruLeg = char:FindFirstChild("RightUpperLeg")
	local luLeg = char:FindFirstChild("LeftUpperLeg")
	local rlLeg = char:FindFirstChild("RightLowerLeg")
	local llLeg = char:FindFirstChild("LeftLowerLeg")
	local rFoot = char:FindFirstChild("RightFoot")
	local lFoot = char:FindFirstChild("LeftFoot")

	if RAGDOLL_HEAD_AS_JOINT then
		safeBallJoint(upperTorso and upperTorso:FindFirstChild("NeckRigAttachment"), head and head:FindFirstChild("NeckRigAttachment"))
	else
		safeWeld(head, upperTorso)
	end

	safeBallJoint(upperTorso and upperTorso:FindFirstChild("RightShoulderRigAttachment"), ruArm and ruArm:FindFirstChild("RightShoulderRigAttachment"))
	safeBallJoint(upperTorso and upperTorso:FindFirstChild("LeftShoulderRigAttachment"), luArm and luArm:FindFirstChild("LeftShoulderRigAttachment"))
	safeBallJoint(lowerTorso and lowerTorso:FindFirstChild("LeftHipRigAttachment"), luLeg and luLeg:FindFirstChild("LeftHipRigAttachment"))
	safeBallJoint(lowerTorso and lowerTorso:FindFirstChild("RightHipRigAttachment"), ruLeg and ruLeg:FindFirstChild("RightHipRigAttachment"))
	safeBallJoint(ruArm and ruArm:FindFirstChild("RightElbowRigAttachment"), rlArm and rlArm:FindFirstChild("RightElbowRigAttachment"))
	safeBallJoint(luArm and luArm:FindFirstChild("LeftElbowRigAttachment"), llArm and llArm:FindFirstChild("LeftElbowRigAttachment"))
	safeBallJoint(luLeg and luLeg:FindFirstChild("LeftKneeRigAttachment"), llLeg and llLeg:FindFirstChild("LeftKneeRigAttachment"))
	safeBallJoint(ruLeg and ruLeg:FindFirstChild("RightKneeRigAttachment"), rlLeg and rlLeg:FindFirstChild("RightKneeRigAttachment"))

	safeWeld(lowerTorso, upperTorso)
	safeWeld(rlArm, rHand)
	safeWeld(llArm, lHand)
	safeWeld(rlLeg, rFoot)
	safeWeld(llLeg, lFoot)
end

function RagdollModule.applyDefaultRagdoll(char: Model)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum or not isR15(char) then return end

	hum.BreakJointsOnDeath = false

	hum.Died:Connect(function()
		anchorCharacter(char, true)
		destroyMotors(char)

		local root = char:FindFirstChild("HumanoidRootPart")
		if root then root:ClearAllChildren() end

		hum:ChangeState(Enum.HumanoidStateType.Dead)
		hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)

		task.wait()
		pcall(buildRagdollOnce, char)

		task.wait()
		anchorCharacter(char, false)

		local lowerTorso = char:FindFirstChild("LowerTorso")
		applyThrowImpulse(lowerTorso)
	end)
end

return RagdollModule
