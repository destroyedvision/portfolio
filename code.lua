local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local CollectionService  = game:GetService("CollectionService")
local RunService         = game:GetService("RunService")

---------------------------------------------------------------------
--// 2  Globals ------------------------------------------------------
---------------------------------------------------------------------
local DOOR_TAG  = "Door"
local PLATE_TAG = "Plate"
local KEY_TAG   = "Key"

-- Storage tables live at top so all downstream code sees them
local Doors  = {}  -- [BasePart] = DoorObject
local Plates = {}  -- [BasePart] = PlateObject
local Keys   = {}  -- [BasePart] = KeyObject

---------------------------------------------------------------------
--// 3  Utility: server‑safe notification ----------------------------
---------------------------------------------------------------------
local function notify(player: Player, text: string)
	-- Creates a minimal ScreenGui + TextLabel that self‑destructs after 2 s.
	if not player or not player.Parent then return end
	local gui      = Instance.new("ScreenGui")
	gui.Name       = "DoorNotifyGUI"
	gui.ResetOnSpawn = false
	gui.Parent     = player:WaitForChild("PlayerGui")

	local label    = Instance.new("TextLabel")
	label.Size     = UDim2.fromOffset(300, 40)
	label.Position = UDim2.new(0.5, -150, 0.85, 0)
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	label.TextColor3 = Color3.new(1,1,1)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 18
	label.Text = text
	label.Parent = gui

	task.delay(2, function()
		gui:Destroy()
	end)
end

---------------------------------------------------------------------
--// 4  Door class ---------------------------------------------------
---------------------------------------------------------------------
local Door = {}
Door.__index = Door

function Door.new(part: BasePart)
	local self = setmetatable({}, Door)
	self.Part        = part
	self.ClosedCFrame= part.CFrame
	self.OpenCFrame  = part.CFrame * CFrame.new(0, 0, -part.Size.Z)
	self.IsOpen      = false
	self.Locked      = part:GetAttribute("Locked") or false
	self.LastUsed    = {}   -- [Player] = tick()  (per‑player cooldown)
	part.BrickColor  = BrickColor.new("Bright red")
	return self
end

function Door:_tween(toCF: CFrame)
	local info  = TweenInfo.new(1, Enum.EasingStyle.Sine)
	TweenService:Create(self.Part, info, { CFrame = toCF }):Play()
end

function Door:Open(requester: Player?)
	if self.IsOpen then
		if requester then notify(requester, "Door already open!") end
		return
	end
	if self.Locked then
		if requester then notify(requester, "Door is locked.") end
		return
	end
	if requester then
		local t = self.LastUsed[requester]
		if t and tick() - t < 2 then return end
		self.LastUsed[requester] = tick()
	end
	self.IsOpen = true
	self:_tween(self.OpenCFrame)
	self.Part.BrickColor = BrickColor.new("Bright green")
	print("[Door] Open:", self.Part.Name)
end

function Door:Close()
	if not self.IsOpen then return end
	self.IsOpen = false
	self:_tween(self.ClosedCFrame)
	self.Part.BrickColor = BrickColor.new("Bright red")
	print("[Door] Close:", self.Part.Name)
end

function Door:Unlock()
	self.Locked = false
	print("[Door] Unlock:", self.Part.Name)
end

---------------------------------------------------------------------
--// 5  Plate class --------------------------------------------------
---------------------------------------------------------------------
local Plate = {}
Plate.__index = Plate

function Plate.new(part: BasePart)
	local self = setmetatable({}, Plate)
	self.Part       = part
	self.TargetName = part:GetAttribute("TargetDoor")
	self.Cooldown   = 3   -- global cooldown per plate
	self.LastTick   = 0
	return self
end

function Plate:OnTouch(hit: BasePart)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end
	if tick() - self.LastTick < self.Cooldown then return end
	self.LastTick = tick()

	for doorPart, doorObj in pairs(Doors) do
		if doorPart.Name == self.TargetName then
			doorObj:Open(player)
			task.delay(5, function() doorObj:Close() end)
			break
		end
	end
end

---------------------------------------------------------------------
--// 6  Key class ----------------------------------------------------
---------------------------------------------------------------------
local Key = {}
Key.__index = Key

function Key.new(part: BasePart)
	local self = setmetatable({}, Key)
	self.Part      = part
	self.DoorName  = part:GetAttribute("OpensDoor")
	return self
end

function Key:OnTouch(hit: BasePart)
	local player = Players:GetPlayerFromCharacter(hit.Parent)
	if not player then return end

	if self.DoorName then
		player:SetAttribute("HasKey_" .. self.DoorName, true)
		notify(player, "Key obtained for " .. self.DoorName)
	end
	self.Part:Destroy()
end

---------------------------------------------------------------------
--// 7  Setup / discovery -------------------------------------------
---------------------------------------------------------------------
local function scanDoors()
	for _, part in ipairs(CollectionService:GetTagged(DOOR_TAG)) do
		Doors[part] = Doors[part] or Door.new(part)
	end
end

local function scanPlates()
	for _, part in ipairs(CollectionService:GetTagged(PLATE_TAG)) do
		if not Plates[part] then
			local obj = Plate.new(part)
			Plates[part] = obj
			part.Touched:Connect(function(hit) obj:OnTouch(hit) end)
		end
	end
end

local function scanKeys()
	for _, part in ipairs(CollectionService:GetTagged(KEY_TAG)) do
		if not Keys[part] then
			local obj = Key.new(part)
			Keys[part] = obj
			part.Touched:Connect(function(hit) obj:OnTouch(hit) end)
		end
	end
end

---------------------------------------------------------------------
--// 8  Debug helper -------------------------------------------------
---------------------------------------------------------------------
local function listPlayerKeys(player: Player)
	print("[Keys] " .. player.Name)
	for doorPart in pairs(Doors) do
		local attr = "HasKey_" .. doorPart.Name
		if player:GetAttribute(attr) then
			print(" •" , doorPart.Name)
		end
	end
end

Players.PlayerAdded:Connect(function(plr)
	plr.Chatted:Connect(function(msg)
		if msg:lower() == ":doors" then
			listPlayerKeys(plr)
		end
	end)
end)

---------------------------------------------------------------------
--// 9  Initialisation & listeners ----------------------------------
---------------------------------------------------------------------
scanDoors(); scanPlates(); scanKeys()

CollectionService:GetInstanceAddedSignal(DOOR_TAG):Connect(scanDoors)
CollectionService:GetInstanceAddedSignal(PLATE_TAG):Connect(scanPlates)
CollectionService:GetInstanceAddedSignal(KEY_TAG):Connect(scanKeys)

while true do
	task.wait(10)
	scanDoors(); scanPlates(); scanKeys()
end
