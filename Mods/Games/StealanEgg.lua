local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Crokier/Roblox/main/Packages/Sampluy/init.luau"))()

local Services = setmetatable({}, {__index = function(_, i) return cloneref and cloneref(game:GetService(i)) or game:GetService(i) end})

local Players = Services.Players
local RunService = Services.RunService
local ReplicatedStorage = Services.ReplicatedStorage

local Enableds = {["Collect"] = false, ["Place"] = false, ["Farm"] = false, ["Hatch"] = false, ["Equip"] = false, ["Sell"] = false, ["Upgrade"] = false, ["BuyTrail"] = false}
local Connections = {}
local Threads = {}
local Values = {["ChosenArea"] = "Automatic", ["NoclipParts"] = {}, ["SellList"] = {}}
local SaveValues = {}

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local Packets = {} 
local SpeedValue = LocalPlayer:QueryDescendants("#leaderstats > #Speed")[1]
local Plot = nil

local PlotsFolder = workspace:FindFirstChild("Plots")

for i, plot in ipairs(PlotsFolder:GetChildren()) do
	local imageLabel = plot:QueryDescendants("#PlotSign > #PlayerPlotSign > #Frame > #PlayerIcon")[1]
	if imageLabel and imageLabel.Image:find(tostring(LocalPlayer.UserId)) then
		Plot = plot
		break
	end
end

local GuardAreas = workspace:QueryDescendants("#__OBJECTS > #Areas > #GuardAreas")[1]
local SpawnedEggs = workspace:FindFirstChild("AreaEggSlotsClient")
local PlacedEggs = nil

local Interfaces = {
	["PetScroll"] = PlayerGui:QueryDescendants("#ActivePets > #Frame > #ScrollingFrame")[1],
	["TrailScroll"] = PlayerGui:QueryDescendants("#TrailShop > #Frame > #ScrollingFrame")[1],
}

for i, v in ipairs(workspace:GetChildren()) do
	if v.Name == "PlacedEggRenders" and #v:GetChildren() >= 1 then
		PlacedEggs = v
	end
end

local UpgradeTypes = {"Treadmill","Buy Trail"}
local UpgradeActives = {["AllEnabled"]=true}

local UpgradeTreadmillButton = nil

local AreasList = {
	"Automatic"
}
for i, v in ipairs(GuardAreas:GetChildren()) do
	table.insert(AreasList, v.Name)
end

local Areas = {
	["Forest"] = {
		Speed = 0
	},
	["Lake"] = {
		Speed = 900
	},
	["Desert"] = {
		Speed = 10000
	},
	["Jungle"] = {
		Speed = 40000
	},
	["Snow"] = {
		Speed = 450000
	},
	["Volcano"] = {
		Speed = 700000
	},
	["Abyss Ocean"] = {
		Speed = 2500000
	},
	["Prehistoric"] = {
		Speed = 17000000
	},
	["Cosmic"] = {
		Speed = 700000000
	}
}

local Waypoints = {
	SafeArea = Vector3.new(542, 71, -363)
}

local LastInventory = nil

Connections.CharacterAdded = LocalPlayer.CharacterAdded:Connect(function(char)
	Character = char
	task.wait(2)
end)

local function FireButton(button)
	if firesignal then
		firesignal(button.Activated)
		firesignal(button.MouseButton1Click)
	end
end

local function GetBestArea()
	local currentSpeed = SpeedValue.Value
	local bestName, bestSpeed = nil, -1

	if Values.ChosenArea == "Automatic" then
		for name, data in pairs(Areas) do
			if data.Speed <= currentSpeed and data.Speed > bestSpeed then
				bestName = name
				bestSpeed = data.Speed
			end
		end
	else
		bestName = Values.ChosenArea
	end

	return bestName or "Lake"
end

local function WalkTo(hum, pos)
	local hrp = hum.RootPart
	while true do
		hum:MoveTo(pos)
		local reached = hum.MoveToFinished:Wait()

		if reached then
			return true
		end

		if hrp and hrp.Parent then
			local flat = (Vector2.new(hrp.Position.X, hrp.Position.Z) - Vector2.new(pos.X, pos.Z)).Magnitude
			if flat <= 4 then
				return true
			end
		else
			return false
		end
	end
end

local TrailInfos = {}

if Interfaces.TrailScroll then
	local sortTrails={}

	for _,layer in ipairs(Interfaces.TrailScroll:GetChildren()) do
		if layer and layer.Parent and layer:IsA("GuiObject") then
			local button=layer:QueryDescendants("#LockedControls > #BuyCash")[1]
			if not button then continue end

			local title=layer:QueryDescendants("#LockedControls > #BuyCash > #Price")[1]
			if not title then continue end

			table.insert(sortTrails, {
				["Button"]=button,
				["Title"]=title,
				["Tier"]=layer.LayoutOrder
			})
		end
	end

	table.sort(sortTrails, function(a, b)
		return a.Tier<b.Tier
	end)

	for _,info in ipairs(sortTrails) do
		table.insert(TrailInfos,info)
	end
end

local Window = UI:CreateWindow({
	Name = "Steal an Egg",
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

Window:AddToggle({
	Name = "Auto Farm",
	Value = false,
	Callback = function(v)
		Enableds.Farm = v
		if v then
			task.spawn(function()
				while Enableds.Farm do
					task.wait()

					Values.NoclipParts = {}
					Values.SaveHipHeight = nil

					if not (Character and Character.Parent) then continue end

					local humanoid = Character:FindFirstChildOfClass("Humanoid")
					if not humanoid then continue end

					Values.LastHumanoid = humanoid
					Values.SaveHipHeight = humanoid.HipHeight

					Connections.Noclipping = RunService.Stepped:Connect(function()
						if Enableds.Farm then
							for _, child in ipairs(Character:GetDescendants()) do
								if child:IsA("BasePart") and child.CanCollide == true then
									child.CanCollide = false
									Values.NoclipParts[child] = true
								end
							end
						end
					end)

					if Enableds.Collect and Packets.Steal then
						task.wait(0.1)
						WalkTo(humanoid, Waypoints.SafeArea)
						task.wait(0.1)
						local selectBestArea = GetBestArea()
						local bestArea = GuardAreas[selectBestArea]
						local bestBounds = nil
						local alreadyAreas = {}
						local bestBounds = bestArea:FindFirstChild("Bounds")

						if not bestBounds then
							repeat 
								for index=2,#AreasList do
									if not Enableds.Collect then break end
									bestBounds = bestArea:FindFirstChild("EggZone")
									if bestBounds then break end
									local selectArea = AreasList[index]
									if alreadyAreas[selectArea] then continue end
									local area = GuardAreas:FindFirstChild(selectArea)
									local bounds = area:FindFirstChild("EggZone")
									if bounds then
										local reached = WalkTo(humanoid, bounds.Position)
										if reached then
											alreadyAreas[selectArea] = true 
										end
									end
									task.wait()
								end

								task.wait(1)
							until bestBounds ~= nil or not Enableds.Collect
							if not Enableds.Collect then break end
						end
						WalkTo(humanoid, bestBounds.Position)
						local closestEgg, closestDist = nil, nil
						for _, v in ipairs(SpawnedEggs:GetChildren()) do
							if v and v.Parent then
								local primaryPart = v.PrimaryPart or v:FindFirstChildOfClass("BasePart")
								if primaryPart then
									if Character and Character.Parent then
										local rootPart = Character.PrimaryPart or Character:FindFirstChild("HumanoidRootPart")
										if rootPart~=nil then 
											local dist = (primaryPart.Position - Character.HumanoidRootPart.Position).Magnitude
											if not closestDist or dist < closestDist then
												closestDist = dist
												closestEgg = v
											end
										end
									end
								end
							end
						end

						if closestEgg then
							WalkTo(humanoid, closestEgg.PrimaryPart.Position)

							task.wait(0.5)

							WalkTo(humanoid, closestEgg.PrimaryPart.Position)
							task.wait()

							Packets.Steal:InvokeServer({Uid = closestEgg.Name})
						end
						WalkTo(humanoid, Waypoints.SafeArea)
					end

					task.wait(0.5)

					if Enableds.Place and Packets.Place then
						if LastInventory ~= nil then
							--humanoid.HipHeight = 20
							task.wait(0.1)
							WalkTo(humanoid, Plot.CenterPoint.Position)

							for i, v in pairs(LastInventory) do
								local randomArea = CFrame.new(math.random(-23, 23), -0.5001220703125, math.random(-29, 29), 0, 0, 1, 0, 1, 0, -1, 0, 0)

								Packets.Place:InvokeServer(
									{
										Uid = i,
										LocalCFrame = randomArea
									}
								)

								task.wait()
							end
						end
					end

					if Enableds.Hatch and Packets.Hatch and Packets.CompleteHatch then
						for i, v in ipairs(PlacedEggs:GetChildren()) do
							if not (v and v.Parent) then continue end
							local splitString = v.Name:split("_")
							if splitString[1] == tostring(LocalPlayer.UserId) then
								--Humanoid.HipHeight = 20
								task.wait(0.1)
								WalkTo(humanoid, v.PrimaryPart.Position)

								local res = Packets.Hatch:InvokeServer(
									splitString[2]
								)

								if res then
									Packets.CompleteHatch:InvokeServer(splitString[2])
								end

								task.wait(0.1)
							end
						end
					end

					if Connections.Noclipping then
						Connections.Noclipping:Disconnect()
						Connections.Noclipping = nil
					end

					for part in pairs(Values.NoclipParts) do
						if part and part.Parent then
							part.CanCollide = true
						end
					end

					Values.NoclipParts = {}

					if humanoid and humanoid.Parent and Values.SaveHipHeight then
						humanoid.HipHeight = Values.SaveHipHeight
						Values.SaveHipHeight = nil
						Values.LastHumanoid = nil
					end
					task.wait(1)
				end
			end)
		else
			if Connections.Noclipping and not Enableds.Farm then
				Connections.Noclipping:Disconnect()
				Connections.Noclipping = nil
			end

			if Values.LastHumanoid and Values.LastHumanoid.Parent and Values.SaveHipHeight then
				Values.LastHumanoid.HipHeight = Values.SaveHipHeight
				Values.SaveHipHeight = nil
				Values.LastHumanoid = nil
			end

			for part in pairs(Values.NoclipParts) do
				if Enableds.Farm then break end
				if part and part.Parent then
					part.CanCollide = true
				end
			end
		end
	end
})

Interfaces.CollectToggle = Window:AddToggle({
	Name = "Auto Collect",
	Default = false,
	Callback = function(v)
		Enableds.Collect = v
		if v then
			if not Packets.Steal then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskFieldEggCarry"]
				end)
				if ok and result then Packets.Steal = result end

				if not Packets.Steal then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestAreaEggCarry"]
					end)
					if ok and result then Packets.Steal = result end
				end
			end
		end
		if not Packets.Steal then
			Enableds.Collect = false
			Interfaces.CollectToggle:Replace(false)
		end
	end
})

Window:AddDropdown({
	Name = "Area",
	Options = AreasList,
	Multi = false,
	Callback = function(option)
		Values.ChosenArea = option[1]
	end
})

Interfaces.PlaceToggle = Window:AddToggle({
	Name = "Auto Place",
	Default = false,
	Callback = function(v)
		Enableds.Place = v
		if v then
			if not Packets.Place then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskPlaceEgg"]
				end)
				if ok and result then Packets.Place = result end

				if not Packets.Place then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestPlaceEgg"]
					end)
					if ok and result then Packets.Place = result end
				end
			end
			if not Packets.Inventory then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RE/EggWorld/OwnerShifted"]
				end)
				if ok and result then Packets.Inventory = result end

				if not Packets.Inventory then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RuntimeOwnerUpdated"]
					end)
					if ok and result then Packets.Inventory = result end
				end
			end
			if Packets.Inventory and not Connections.Inventory then
				Connections.Inventory = Packets.InventoryChanged.OnClientEvent:Connect(function(data)
					if data.OwnerUserId == LocalPlayer.UserId then
						LastInventory = data.Records
					end
				end)
			end
		end
		if not (Packets.Place and Packets.Inventory) then
			Enableds.Place = false
			Interfaces.PlaceToggle:Replace(false)
		end
	end
})

Interfaces.HatchToggle = Window:AddToggle({
	Name = "Auto Hatch",
	Default = false,
	Callback = function(v)
		Enableds.Hatch = v
		if v then
			if not Packets.Hatch then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskHatch"]
				end)
				if ok and result then Packets.Hatch = result end
				if not Packets.Hatch then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestHatchEgg"]
					end)
					if ok and result then Packets.Hatch = result end
				end
			end
			if not Packets.CompleteHatch then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/EggWorld/AskFinishHatch"]
				end)
				if ok and result then Packets.CompleteHatch = result end
				if not Packets.CompleteHatch then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Eggs: RequestCompleteHatchEgg"]
					end)
					if ok and result then Packets.CompleteHatch = result end
				end
			end
		end
		if not (Packets.Hatch and Packets.CompleteHatch) then
			Enableds.Hatch = false
			Interfaces.HatchToggle:Replace(false)
		end 
	end
})

Interfaces.EquipToggle = Window:AddToggle({
	Name = "Auto Equip Best",
	Default = false,
	Callback = function(v)
		Enableds.Equip = v
		if v then
			if not Packets.EquipBest then
				local ok, result = pcall(function()
					return ReplicatedStorage.Packages.Networking["RF/Haul/WearBest"]
				end)
				if ok and result then Packets.EquipBest = result end
				if not Packets.EquipBest then
					ok, result = pcall(function()
						return ReplicatedStorage.Network["Backpack: EquipBest"]
					end)
					if ok and result then Packets.EquipBest = result end
				end
			end
		end
		if not Packets.EquipBest then
			Enableds.Equip = false
			Interfaces.EquipToggle:Replace(false)
		end 
		if Enableds.Equip and Packets.EquipBest then
			task.spawn(function()
				while Enableds.Equip do
					Packets.EquipBest:InvokeServer()
					task.wait(3)
				end
			end)
		end
	end
})

Window:AddDropdown({
	Text="Upgrade Type",
	Options=#UpgradeTypes>0 and UpgradeTypes or {"No Upgrade Type"},
	Option=nil,
	Multi=true,
	Callback=function(option)
		for _,key in ipairs(UpgradeTypes) do
			UpgradeActives[key]=table.find(option,key)~=nil
		end
		UpgradeActives.AllEnabled=#option<=0
	end
})

Window:AddToggle({
	Text="Auto Upgrade",
	Value=false,
	Callback=function(value)
		Enableds.Upgrade=value
		if not Enableds.Upgrade then return end
		task.spawn(function()
			while Enableds.Upgrade do
				Interfaces.ThreadmillButton = Interfaces.ThreadmillButton or Plot:QueryDescendants("#Sign > #SurfaceGui > #Frame > #Upgrade")[1]
				Interfaces.ThreadmillHint = Interfaces.ThreadmillHint or Plot:QueryDescendants("#Sign > #CanUpgrade")[1]

				if not (Interfaces.ThreadmillHint and Interfaces.ThreadmillButton) then 
					Enableds.Upgrade = false
					Interfaces.UpgradeToggle:Replace(false)
					return
				end
				
				if Interfaces.ThreadmillHint and Interfaces.ThreadmillButton then
					if Interfaces.ThreadmillHint.Enabled then
						FireButton(Interfaces.ThreadmillButton)
					end
				end
				task.wait(1)
			end
		end)
		task.spawn(function()
			while Enableds.Upgrade do
				if UpgradeActives["Buy Trail"] == true then
					for _, info in ipairs(TrailInfos) do
						if not (UpgradeActives["Buy Trail"] and Enableds.Upgrade) then break end
						local key = info.Title.Text:lower()
						if key:find("equip") or key:find("unequip") then continue end
						if key:find("$") then
							FireButton(info.Button)
						end					
						task.wait()

					end
				end
				task.wait(1)
			end
		end)

	end
})

Window:AddLabel({
	Name = "YouTube: Crokyreo",
	TextColor3 = Color3.fromRGB(255, 255, 255),
})

Window:AddLabel({
	Name = "YouTube: vaehz",
	TextColor3 = Color3.fromRGB(255, 255, 255),
})
