local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AbilityCast")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ui = player:WaitForChild("PlayerGui"):WaitForChild("AbilityUI")

local keyToAbility = {
	Q = "Fireball",
	E = "Dash",
	R = "Heal",
}

local Abilities = {
	Fireball = {Cooldown = 3},
	Dash = {Cooldown = 4},
	Heal = {Cooldown = 5},
}

local cooldowns = {}

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local ability = keyToAbility[input.KeyCode.Name]
	if not ability then return end

	if cooldowns[ability] then
		return
	end

	Remote:FireServer(ability)

	cooldowns[ability] = true

	local slot = ui:FindFirstChild(ability)
	if not slot then return end

	local cooldownFrame = slot:FindFirstChild("Cooldown")
	local label = slot:FindFirstChild("Label")

	if not cooldownFrame or not label then return end

	cooldownFrame.Visible = true
	cooldownFrame.Size = UDim2.fromScale(1, 1)
	label.TextTransparency = 1

	local tweenService = game:GetService("TweenService")
	local tween = tweenService:Create(cooldownFrame, TweenInfo.new(Abilities[ability].Cooldown, Enum.EasingStyle.Linear), {
		Size = UDim2.fromScale(1, 0)
	})
	tween:Play()

	tween.Completed:Connect(function()
		cooldownFrame.Visible = false
		label.TextTransparency = 0
		cooldowns[ability] = nil
	end)
end)

local UIS = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Remote = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("AbilityCast")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local ui = player:WaitForChild("PlayerGui"):WaitForChild("AbilityUI")

local keyToAbility = {
	Q = "Fireball",
	E = "Dash",
	R = "Heal",
}

local cooldowns = {}

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	local ability = keyToAbility[input.KeyCode.Name]
	if ability and not cooldowns[ability] then
		Remote:FireServer(ability)
		cooldowns[ability] = true
		local slot = ui:FindFirstChild(ability)
		if slot then
			slot.Cooldown.Visible = true
			slot.Cooldown.Size = UDim2.fromScale(1, 1)
			slot.Label.TextTransparency = 1

			local tweenService = game:GetService("TweenService")
			local tween = tweenService:Create(slot.Cooldown, TweenInfo.new(Abilities[ability].Cooldown, Enum.EasingStyle.Linear), {
				Size = UDim2.fromScale(1, 0)
			})
			tween:Play()

			task.delay(Abilities[ability].Cooldown, function()
				cooldowns[ability] = nil
				slot.Cooldown.Visible = false
				slot.Label.TextTransparency = 0
			end)
		end
	end
end)

print("Client sees health:", game.Players.LocalPlayer.Character.Humanoid.Health)
