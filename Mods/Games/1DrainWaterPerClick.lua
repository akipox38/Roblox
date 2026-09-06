-- This is what the script looks like from Tora IsMe.
-- This is a script I made myself. I DO NOT STEAL SCRIPT because i can't read script on Tora IsMe

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()
local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})
local Players = Services.Players
local ReplicatedStorage = Services.ReplicatedStorage

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Enableds = {["Click"] = false, ["Upgrade"] = false, ["Cash"] = false, ["Stage"] = false, ["Sell"] = false, ["Rebirth"] = false, ["Equip"] = false}
local Connections = {}

local ClickIndex = 0
local WaterPumpInfos = {}
local Packets = {}

local Interfaces={
	["MainGui"] = PlayerGui:FindFirstChild("Main"),
	["HomeButton"] = PlayerGui:QueryDescendants("#HUD > #Main > #Top > #GoShow > #TextButton")[1],
	["UpgradeScroll"] = PlayerGui:QueryDescendants("#Main > #Upgrades > #Main > #ScrollingFrame")[1],
}

Interfaces.WaterPumpFrame = Interfaces.MainGui:FindFirstChild("Water Pump")
if Interfaces.WaterPumpFrame then
	Interfaces.WaterPumpScroll = Interfaces.WaterPumpFrame:QueryDescendants("#Main > #ScrollingFrame")[1]
end

local AmountValue = LocalPlayer:QueryDescendants("#BackpackData > #amount")[1]
local CapacityValue = LocalPlayer:QueryDescendants("#BackpackData > #capacity")[1]
local StageValue = LocalPlayer:QueryDescendants("#Stage > #stage")[1]

local UpgradeTypes = {"Buy Water Pump"}
local UpgradeActives = {["AllEnabled"] = true, ["Buy Water Pump"] = false}
local UpgradeInfos = {}

local ProfileData = {
	["MaxStage"] = 0
}

local StageFolder = nil
local WorldFishFolder = nil
local CashHitbox = nil

if Interfaces.WaterPumpScroll then
	local sortWaterPumps = {}
	for _, layer in ipairs(Interfaces.WaterPumpScroll:GetChildren()) do
		if layer and layer.Parent and layer:IsA("GuiObject") then
			local frame = layer:FindFirstChild("Sellall")
			if not frame then continue end

			local buyFrame = frame:FindFirstChild("Sell")
			if not buyFrame then continue end

			local buyButton = buyFrame:FindFirstChild("go")
			if not buyButton then continue end

			table.insert(sortWaterPumps, {
				["BuyButton"] = buyButton,
				["BuyFrame"] = buyFrame,
				["EquipFrame"] = frame:FindFirstChild("Equip"),
				["UnequipFrame"] = frame:FindFirstChild("Equipped"),
				["Tier"] = layer.LayoutOrder
			})
		end
	end
	table.sort(sortWaterPumps, function(a, b)
		return a.Tier < b.Tier
	end)
	for _, info in ipairs(sortWaterPumps) do
		table.insert(WaterPumpInfos, info)
	end
end

if StageValue and (StageValue:IsA("NumberValue") or StageValue:IsA("IntValue")) then
	ProfileData.Stage = StageValue.Value
	Connections.StageChanged = StageValue:GetPropertyChangedSignal("Value"):Connect(function()
		ProfileData.Stage = StageValue.Value
	end)
end

if CapacityValue and (CapacityValue:IsA("NumberValue") or CapacityValue:IsA("IntValue")) then
	ProfileData.Capacity = CapacityValue.Value
	Connections.CapacityChanged = CapacityValue:GetPropertyChangedSignal("Value"):Connect(function()
		ProfileData.Capacity = CapacityValue.Value
	end)
end

if AmountValue and (AmountValue:IsA("NumberValue") or AmountValue:IsA("IntValue")) then
	ProfileData.Amount = AmountValue.Value
	Connections.AmountChanged = AmountValue:GetPropertyChangedSignal("Value"):Connect(function()
		ProfileData.Amount = AmountValue.Value
	end)
end

local LevelTarget = ProfileData.Stage or 1

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

if Interfaces.UpgradeScroll then
	local sortUpgrades = {}

	for _, layer in ipairs(Interfaces.UpgradeScroll:GetChildren()) do
		if layer and layer.Parent and layer:IsA("GuiObject") then
			local frame = layer:FindFirstChild("1")
			if not frame then continue end

			local buyButton = frame:QueryDescendants("#Sell > #go")[1]
			if not buyButton then continue end

			local title = frame:QueryDescendants("#Flame > #name")[1]
			if not title then continue end

			local key = title.Text

			if not UpgradeInfos[key] then
				UpgradeInfos[key] = {}
				UpgradeActives[key] = false
				table.insert(sortUpgrades, {
					Name = key,
					Tier = layer.LayoutOrder,
				})
			end

			table.insert(UpgradeInfos[key], {
				Name = key,
				UpgradeButton = buyButton
			})
		end
	end

	table.sort(sortUpgrades, function(a, b)
		return a.Tier < b.Tier
	end)

	for _, info in ipairs(sortUpgrades) do
		table.insert(UpgradeTypes, info.Name)
	end 
end

for _, v1 in ipairs(workspace:GetChildren()) do
	if not (v1 and v1.Parent) then continue end
	if v1.Name == "主场景" then
		for _, v2 in ipairs(v1:GetChildren()) do
			if not (v2 and v2.Parent) then continue end
			if v2.Name == "验证场景" then
				for _, v3 in ipairs(v2:GetChildren()) do
					if not (v3 and v3.Parent) then continue end
					if v3.Name:find("关卡") then
						StageFolder = v2
						break
					end
				end

				if StageFolder then 
					if not WorldFishFolder then
						WorldFishFolder = StageFolder:FindFirstChild("WorldFish")
					end
					for _, v3 in ipairs(StageFolder:GetChildren()) do
						if not (v3 and v3.Parent) then continue end
						if v3.Name:find("关卡") then
							ProfileData.MaxStage += 1
						end
					end
					break 
				end
			end
		end
		if StageFolder then break end
	end
end

local function FirePrompt(prompt)
	if fireproximityprompt then
		fireproximityprompt(prompt, 0)
	end
end

local function FireButton(button)
	if firesignal then
		firesignal(button.Activated)
		firesignal(button.MouseButton1Click)
	end
end

local function FireTouch(hitPart, targetPart)
	if firetouchinterest then
		firetouchinterest(hitPart, targetPart, 1)
		task.wait()
		firetouchinterest(hitPart, targetPart, 0)
	end
end

local function GetPlot()
	local fishShowPlotId = LocalPlayer:GetAttribute("FishShowPlotId")
	for _, plot in ipairs(workspace:GetChildren()) do
		local folder = plot:FindFirstChild("玩家区域")
		if not folder then continue end

		local plotId = tonumber(plot.Name:match("%d+") or "")
		if not plotId then continue end

		local humanoid = plot:FindFirstChildOfClass("Humanoid")
		if humanoid then continue end

		if fishShowPlotId ~= nil and plotId == fishShowPlotId then
			return plot
		end
	end
	return nil
end

local function SuperPivoTo(model, p1, p2, height)
	local orientation = p2.Orientation
	local extraHeight = (p1.Size.Y / 2) + (p2.Size.Y / 2) + height
	local newPosition = Vector3.new(p1.Position.X, p1.Position.Y + extraHeight, p1.Position.Z)
	local newRotation = CFrame.fromEulerAngles(math.rad(orientation.X), math.rad(orientation.Y), math.rad(orientation.Z), Enum.RotationOrder.YXZ)
	model:PivotTo(CFrame.new(newPosition) * newRotation)
end

local Plot = GetPlot()

local Window = UI:CreateWindow({
	Name = "+1 Drain Water Per Click", 
	Destroying = function()
		for key, enabled in pairs(Enableds) do
			Enableds[key] = false
		end
		for key, connection in pairs(Connections) do
			if connection then
				connection:Disconnect()
			end
		end
	end
})

Interfaces.ClickToggle = Window:AddToggle({
	Text = "Level Up",
	Value = false,
	Callback = function(value)
		Enableds.Click = value
		if not Enableds.Click then return end
		Packets.Click = Packets.Click or ReplicatedStorage.Remote.Event.Level["[C-S]Click"]
		if not Packets.Click then
			Enableds.Click = false
			Interfaces.ClickToggle:Replace(false)
			return
		end
		task.spawn(function()
			while Enableds.Click do
				Packets.Click:FireServer(ClickIndex)
				ClickIndex += 1
				task.wait(0.1)
			end
		end)
	end
})

Window:AddSlider({
	Text = "Stage",
	Range = {1, ProfileData.MaxStage > 0 and ProfileData.MaxStage or 1},
	Value = LevelTarget,
	Increment = 1,
	Callback = function(value)
		LevelTarget = value
	end
})

Window:AddToggle({
	Text = "Auto Stage",
	Value = false,
	Callback = function(value)
		Enableds.Stage = value
		if not Enableds.Stage then return end
		Packets.GoHome = Packets.GoHome or ReplicatedStorage.Remote.Event.Level["[C-S]GoShow"]
		task.spawn(function()
			while Enableds.Stage do
				local level = ProfileData.Stage
				local levelFolder = StageFolder:FindFirstChild("关卡"..tostring(level))

				if levelFolder then
					local checkPart = levelFolder:FindFirstChild("光门")
					local surfacePart = levelFolder:FindFirstChild("水面")
					local humanoid = Character:FindFirstChildOfClass("Humanoid")
					local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")

					while Enableds.Stage and checkPart and checkPart.CanCollide and level < LevelTarget do
						SuperPivoTo(Character, surfacePart, rootPart, humanoid.HipHeight)
						task.wait()
					end

					local lastLevel = ProfileData.Stage - 1
					if level >= LevelTarget then
						task.wait(0.3)
						local sortFishs = {}

						if WorldFishFolder then
							for _, child in ipairs(WorldFishFolder:GetChildren()) do
								if not Enableds.Stage then break end
								if child and child.Parent and child:IsA("Model") then
									local stageId = child:GetAttribute("StageId")
									if stageId == nil or stageId ~= lastLevel then continue end

									local price = child:GetAttribute("Price")
									if price == nil then continue end

									local fishRoot = child:FindFirstChild("FishRoot")
									if not fishRoot then continue end

									local prompt = fishRoot:FindFirstChild("PickupPrompt")

									table.insert(sortFishs, {
										Tier = price,
										SpawnPoint = fishRoot,
										Prompt = prompt,
									})
									task.wait()
								end
							end
						end

						if not Enableds.Stage then break end

						table.sort(sortFishs, function(a, b)
							return a.Tier > b.Tier
						end)

						for _, info in ipairs(sortFishs) do
							if not Enableds.Stage then break end
							if not (checkPart and checkPart.Parent and checkPart.CanCollide) then break end
							if ProfileData.Amount >= ProfileData.Capacity then
								if Packets.GoHome then
									Packets.GoHome:FireServer()
								else
									FireButton(Interfaces.HomeButton)
								end
								task.wait(1)
								break
							end
							local spawnPoint, prompt = info.SpawnPoint, info.Prompt
							SuperPivoTo(Character, spawnPoint, rootPart, humanoid.HipHeight)
							task.wait(0.1)
							repeat
								if not (checkPart and checkPart.Parent and checkPart.CanCollide) then break end
								FirePrompt(prompt)
								task.wait()
							until not (Enableds.Stage and prompt.Parent and prompt.Enabled)
							task.wait(0.1)
						end
						table.clear(sortFishs)
					end
				end

				task.wait(0.5)
			end
		end)
	end
})

Interfaces.CashToggle = Window:AddToggle({
	Text = "Collect Cash",
	Value = false,
	Callback = function(value)
		Enableds.Cash = value
		if not Enableds.Cash then return end
		
		if not CashHitbox then
			local folder = Plot:FindFirstChild("玩家区域")
			if folder then
				for _, model in ipairs(folder:GetChildren()) do
					if model.Name:find("收集按钮") and model:IsA("Model") then
						local part = model:FindFirstChild("Cash")
						if not part then continue end

						local hitbox = model:FindFirstChild("Touch")
						if not hitbox then continue end

						CashHitbox = hitbox
						break
					end
				end
			end
		end

		if not CashHitbox then
			Enableds.Cash = false
			Interfaces.CashToggle:Replace(false)
			return
		end

		task.spawn(function()
			while Enableds.Cash do
				local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
				if rootPart and CashHitbox then
					FireTouch(rootPart, CashHitbox)
				end
				task.wait(1)
			end
		end)
	end
})

Interfaces.EquipToggle = Window:AddToggle({
	Text = "Equip Best",
	Value = false,
	Callback = function(value)
		Enableds.Equip = value
		if not Enableds.Equip then return end
		Packets.EquipBest = Packets.EquipBest or ReplicatedStorage.Remote.Function.FishShow["[C-S]BestFishUI"]
		if not Packets.EquipBest then
			Enableds.Equip = false
			Interfaces.EquipToggle:Replace(false)
			return
		end
		task.spawn(function()
			while Enableds.Equip do
				Packets.EquipBest:InvokeServer()
				task.wait(3)
			end
		end)
	end
})

Window:AddDropdown({
	Text = "Upgrade Type",
	Options = #UpgradeTypes > 0 and UpgradeTypes or {"No Upgrade Type"},
	Option = nil,
	Multi = true,
	Callback = function(option)
		for _, mode in ipairs(UpgradeTypes) do
			UpgradeActives[mode] = table.find(option, mode) ~= nil
		end
		UpgradeActives.AllEnabled = #option <= 0
	end
})

Window:AddToggle({
	Text = "Auto Upgrade",
	Value = false,
	Callback = function(value)
		Enableds.Upgrade = value
		if not Enableds.Upgrade then return end

		task.spawn(function()
			while Enableds.Upgrade do
				for key, active in pairs(UpgradeActives) do
					if not Enableds.Upgrade then break end
					if key == "AllEnabled" then continue end
					if UpgradeActives.AllEnabled then active = true end
					if not active then continue end
					local list = UpgradeInfos[key]
					if not list then continue end
					for _, info in ipairs(list) do
						if not Enableds.Upgrade then break end
						local button = info.UpgradeButton
						if button then
							FireButton(button)
							task.wait()
						end
					end
					task.wait()
				end
				task.wait(0.5)
			end
		end)
		
		task.spawn(function()
			while Enableds.Upgrade do
				task.wait()
				if UpgradeActives["Buy Water Pump"] == true or UpgradeActives.AllEnabled == true then
					for _, info in ipairs(WaterPumpInfos) do
						if not (Enableds.Upgrade) then break end
						if UpgradeActives["Buy Water Pump"] == false or not UpgradeActives.AllEnabled then break end
						local equipFrame, unequipFrame = info.EquipFrame, info.UnequipFrame
						local buyFrame, buyButton = info.BuyFrame, info.BuyButton
						if buyFrame.Visible == true then
							if equipFrame and equipFrame.Visible == true then continue end
							if unequipFrame and unequipFrame.Visible == true then continue end
							FireButton(buyButton)
						end
						task.wait()
					end
					task.wait(3)
				end
			end
		end)
	end
})

Interfaces.RebirthToggle = Window:AddToggle({
	Text = "Auto Rebirth",
	Value = false,
	Callback = function(value)
		Enableds.Rebirth = value
		if not Enableds.Rebirth then return end
		Interfaces.RebirthFrame = Interfaces.RebirthFrame or (Interfaces.MainGui and Interfaces.MainGui:FindFirstChild("Rebirth+1water") and Interfaces.MainGui["Rebirth+1water"]:FindFirstChild("UI1") or nil)
		if Interfaces.RebirthFrame then
			Interfaces.RebirthFill = Interfaces.RebirthFill or (Interfaces.RebirthFrame:FindFirstChild("Progress bar") and Interfaces.RebirthFrame["Progress bar"]:FindFirstChild("Internal progress bar") or nil)
			Interfaces.RebirthButton = Interfaces.RebirthButton or Interfaces.RebirthFrame:QueryDescendants("#RebirthButton > #TextButton")[1]
		end
		if not (Interfaces.RebirthFill and Interfaces.RebirthButton) then
			Enableds.Rebirth = false
			Interfaces.RebirthToggle:Replace(false)
			return
		end
		task.spawn(function()
			while Enableds.Rebirth do
				if Interfaces.RebirthFill.Size.X.Scale >= 1 then
					FireButton(Interfaces.RebirthButton)
				end
				task.wait()
			end
		end)
	end
})

Interfaces.SellToggle = Window:AddToggle({
	Text = "Auto Sell",
	Value = false,
	Callback = function(value)
		Enableds.Sell = value
		if not Enableds.Sell then return end
		Packets.SellAll = Packets.SellAll or ReplicatedStorage.Remote.Function.Fish["[C-S]SellAllFish"]
		if not Packets.SellAll then
			Enableds.Sell = false
			Interfaces.SellToggle:Replace(false)
			return
		end
		task.spawn(function()
			while Enableds.Sell do
				Packets.SellAll:InvokeServer()
				task.wait(1)
			end
		end)
	end
})

Window:AddLabel({ Text = "YouTube: Crokyreo", TextColor3 = Color3.fromRGB(255, 255, 255) })
Window:AddLabel({ Text = "YouTube: Tora IsMe", TextColor3 = Color3.fromRGB(255, 255, 255) })

Services.GuiService:SetGameplayPausedNotificationEnabled(false)
