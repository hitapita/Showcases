-- Services
local DSS = game:GetService("DataStoreService")
local TS = game:GetService("TeleportService")
local Chat = game:GetService("Chat")
local MS = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

--DataStores
local ServerAccessCodesDS = DSS:GetDataStore("ServerAccessCodesDS.")
local ServerNamesDS = DSS:GetDataStore("ServerNamesDS.")
local LocalOwnedServersDS = DSS:GetDataStore("LocalOwnedServersDS.")
local CustomServerJoinCodesDS = DSS:GetDataStore("CustomServerJoinCodesDS.")
local GlobalPrivateServerDS = DSS:GetOrderedDataStore("GlobalPrivateServerDS.")
local PrivateServerOwnerIdDS = DSS:GetDataStore("PrivateServerOwnerIdDS.")
local ServerInfoDS = DSS:GetDataStore("ServerInfoDS.")

--Paths
local menu = script.Parent.Parent
local createServerButton = menu.Frame.CreateServer.CreateButton
local yourServersButton = menu.Frame.YourServers_Button
local joinServerButton = menu.Frame.JoinByCode.JoinButton

-- Vars
local plr = menu.Parent.Parent
local psid = game.PrivateServerId
local servers = {}
local JoinServerCodeEntered;

pcall(function()
	for i,v in pairs(LocalOwnedServersDS:GetAsync(plr.UserId) or nil) do
		table.insert(servers, v)
		print(plr.Name.." Private Server Codes = "..v)
	end
end)

function GenerateServerInviteCode()
	while true do
		local code = math.random(111111,999999)
		if not ServerNamesDS:GetAsync(code) then
			return code
		end
	end
end

function SortGlobalPrivateSeversAsync()
	local pages = GlobalPrivateServerDS:GetSortedAsync(false, 100)
	
	for i,v in pairs(menu.Frame.ServerList:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	
	local data = pages:GetCurrentPage()
	
	for i,v in pairs(data) do
		warn(v.value, v.key)
		wait(.2)
		local ServerInfoDictionary = ServerInfoDS:GetAsync(v.key)
		local ServerFrameClone = script.ServersTemplate:Clone()
		ServerFrameClone.Parent = script.Parent.Parent.Frame.ServerList
		ServerFrameClone.PlayerCount.Text = v.value.."/20"
		ServerFrameClone.ServerName.Text = ServerInfoDictionary.ServerName
		ServerFrameClone.JoinServerButton.MouseButton1Click:Connect(function()
			local code = ServerAccessCodesDS:GetAsync(v.key)
			TS:TeleportToPrivateServer(game.PlaceId, code, {plr})
		end)
	end
	
end

if string.len(psid) >= 30 then
	print("Private Server", psid)
	game.ReplicatedStorage.PrivateServerOwnerValue.Value = PrivateServerOwnerIdDS:GetAsync(psid)
else
	print("Public Server", psid)
end

script.Parent.RemoteEvent.OnServerEvent:Connect(function(plr, txt)
	JoinServerCodeEntered = txt
end)

joinServerButton.MouseButton1Click:Connect(function()
	if JoinServerCodeEntered ~= nil then
		local id = ServerNamesDS:GetAsync(JoinServerCodeEntered)
		local code = ServerAccessCodesDS:GetAsync(id)
		TS:TeleportToPrivateServer(game.PlaceId, code, {plr})
	end
end)

function UpdateYourServersList()
	for i,v in pairs(menu.Frame.YourServers:GetChildren()) do
		if v:IsA("Frame") then
			v:Destroy()
		end
	end
	
	for i,v in pairs(servers) do
		local id = ServerNamesDS:GetAsync(v)
		local ServerInfoDictionary = ServerInfoDS:GetAsync(id)
		local YourServerFrameClone = script.YourServersTemplate:Clone()
		YourServerFrameClone.Name = v..i
		YourServerFrameClone.Parent = menu.Frame.YourServers
		YourServerFrameClone.JoinCode.Text = v
		YourServerFrameClone.ServerName.Text = ServerInfoDictionary.ServerName
		YourServerFrameClone.JoinServerButton.MouseButton1Click:Connect(function()
			local code = ServerAccessCodesDS:GetAsync(id)
			TS:TeleportToPrivateServer(game.PlaceId, code, {plr})
		end)
	end
	print("Successfully Loaded ", plr.Name, "'s Servers")
end

createServerButton.MouseButton1Click:Connect(function()
	local code, id = TS:ReserveServer(game.PlaceId)
	local NewJoinCode = GenerateServerInviteCode()
	GlobalPrivateServerDS:SetAsync(id, 0)
	CustomServerJoinCodesDS:SetAsync(id, NewJoinCode)
	ServerNamesDS:SetAsync(NewJoinCode, id)
	ServerAccessCodesDS:SetAsync(id, code)
	PrivateServerOwnerIdDS:SetAsync(id, plr.UserId)
	
	local ServerInfoDictionary = {
		ServerName = script.Parent.GetServerName:InvokeClient(plr),
	}
	
	ServerInfoDS:SetAsync(id, ServerInfoDictionary)
	table.insert(servers, NewJoinCode)
	local success, errorMessage = pcall(function()
		LocalOwnedServersDS:SetAsync(plr.UserId, servers)
	end)
	
	UpdateYourServersList()
	SortGlobalPrivateSeversAsync()
end)

Players.PlayerAdded:Connect(function()
	if string.len(psid) >= 30 then
		GlobalPrivateServerDS:SetAsync(psid, #game.Players:GetPlayers())
	end
end)

Players.PlayerRemoving:Connect(function()
	if string.len(psid) >= 30 then
		GlobalPrivateServerDS:SetAsync(psid, #game.Players:GetPlayers())
	end
end)

game:BindToClose(function()
	if string.len(psid) >= 30 then
		GlobalPrivateServerDS:SetAsync(psid, 0)
	end
end)

UpdateYourServersList()

plr.CharacterAdded:Connect(function()
	UpdateYourServersList()
end)

while true do
	SortGlobalPrivateSeversAsync()
	wait(60)
end
