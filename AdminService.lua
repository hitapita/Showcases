-- Services
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")

-- Modules
local AdminConfig = require(script.Parent:WaitForChild("AdminConfig"))

-- Remotes
local AdminPanelRemotes = ReplicatedStorage:WaitForChild("AdminPanelRemotes")
local PermanentlyBanPlayer = AdminPanelRemotes:WaitForChild("PermanentlyBanPlayer")
local UnbanPlayerFromPermanentBan = AdminPanelRemotes:WaitForChild("UnbanPlayerFromPermanentBan")
local MutePlayer = AdminPanelRemotes:WaitForChild("MutePlayer")
local UnmutePlayer = AdminPanelRemotes:WaitForChild("UnmutePlayer")
local WarnPlayer = AdminPanelRemotes:WaitForChild("WarnPlayer")
local KickPlayer = AdminPanelRemotes:WaitForChild("KickPlayer")
local MakeAnnouncement = AdminPanelRemotes:WaitForChild("MakeAnnouncement")
local EnableAdminPanel = AdminPanelRemotes:WaitForChild("EnableAdminPanel")
local PromptWarnNotification = AdminPanelRemotes:WaitForChild("PromptWarnNotification")
local CheckPlayerRole = AdminPanelRemotes:WaitForChild("CheckPlayerRole")
local HandleChatVisibility = AdminPanelRemotes:WaitForChild("HandleChatVisibility")
local CreateAdminLog = AdminPanelRemotes:WaitForChild("CreateAdminLog")
local CreateBanList = AdminPanelRemotes:WaitForChild("CreateBanList")
local RemoveFromBanList = AdminPanelRemotes:WaitForChild("RemoveFromBanList")
local ChangeCooldownState = AdminPanelRemotes:WaitForChild("ChangeCooldownState")
local CheckForHierarchyRequirement = AdminPanelRemotes:WaitForChild("CheckForHierarchyRequirement")
local RemovePlayerFromAdminList = AdminPanelRemotes:WaitForChild("RemovePlayerFromAdminList")
local AddPlayerToAdminList = AdminPanelRemotes:WaitForChild("AddPlayerToAdminList")
local CheckPlayerPrivileges = AdminPanelRemotes:WaitForChild("CheckPlayerPrivileges")
local ServerBanPlayer = AdminPanelRemotes:WaitForChild("ServerBanPlayer")
local UnbanPlayerFromServerBan = AdminPanelRemotes:WaitForChild("UnbanPlayerFromServerBan")

-- DataStore
local PunishmentData = DataStoreService:GetDataStore("PunishmentData")
local BanLogsData = DataStoreService:GetOrderedDataStore("BanLogs")

local HierarchyTable = {
    Creator = 3,
    Admin = 2,
    Mod = 1
}

local PrivilegeTable = {
    Creator = {"Warn", "Announce", "Kick", "Ban", "Mute"},
    Admin = {"Warn", "Announce", "Kick", "Ban"},
    Mod = {"Warn", "Announce", "Kick"}
}

local StoredAdminLogs = {}
local StoredKillLogs = {}
local StoredAdminUserIds = {}
local AdminsOnCooldown = {}
local StoredPermanentBans = {}
local StoredServerBans = {}

local AdminService = {}

function AdminService.Init()
    Players.PlayerAdded:Connect(function(Player)
        local Key = "Player-".. tostring(Player.UserId)
        local PlayerData = nil

        pcall(function()
            PlayerData = PunishmentData:GetAsync(Key)
        end)

        if PlayerData then
            local BanData = AdminService.IsPlayerBanned(Player.Name)
            if BanData then
                Player:Kick("\n".. "You are permanently banned.".. "\n".. "Reason: ".. PlayerData["BanReason"].. "\n".. "Banned by: ".. PlayerData["NameOfPersonWhoBanned"])
            end
        else
            AdminService.SetPlayerBanDataToDefault(Player.Name)
        end

        for _, ServerBanData in ipairs(StoredServerBans) do
            if ServerBanData.UserId == Player.UserId then
                Player:Kick(ServerBanData.Reason)
            end
        end

        if table.find(AdminsOnCooldown, Player.UserId) then
            task.spawn(function()
                ChangeCooldownState:FireClient(Player, "Enable")
                task.wait(30)
                table.remove(AdminsOnCooldown, table.find(AdminsOnCooldown, Player.UserId))
                ChangeCooldownState:FireClient(Player, "Disable")
            end)
        end

        local PlayerRole = AdminService.GetPlayerRole(Player.Name)
        
        if PlayerRole then
            table.insert(StoredAdminUserIds, Player.UserId)

            for _, LogText in ipairs(StoredAdminLogs) do
                AdminService.CreateAdminLog(LogText, false, false, Player)
            end
            
            for _, UserId in ipairs(StoredPermanentBans) do
                AdminService.AddNewBanListMember(UserId, "Permanent", false, Player)
            end

            for _, ServerBanData in ipairs(StoredServerBans) do
                AdminService.AddNewBanListMember(ServerBanData.UserId, "Server", false, Player)
            end

            for _, Admin in ipairs(Players:GetPlayers()) do
                if table.find(StoredAdminUserIds, Admin.UserId) and Admin ~= Player then
                    AddPlayerToAdminList:FireClient(Admin, Player, PlayerRole)
                end
            end
        end

        Player.Chatted:Connect(function(Message)
            AdminService.PromptPanel(Player, Message)
        end)

        Player.CharacterAdded:Connect(function(Character)
            Character.Humanoid.Died:Connect(function()
                table.insert(StoredKillLogs, os.date("%X").. " | ".. os.date("%x").. "\n".. Player.Name.. " died.")
            end)
        end)
    end)

    Players.PlayerRemoving:Connect(function(Player)
        local PosInTable = table.find(StoredAdminUserIds, Player.UserId)
        if PosInTable then
            table.remove(StoredAdminUserIds, PosInTable)
        end

        for _, Admin in ipairs(Players:GetPlayers()) do
            if table.find(StoredAdminUserIds, Admin.UserId) then
                RemovePlayerFromAdminList:FireClient(Admin, Player)
            end
        end
    end)

    AdminService.HandleKillLogs()
    AdminService.HandleAdminCheckRoleRequests()
    AdminService.HandleHierarchyCheckRequests()
    AdminService.HandlePrivilegesCheck()
    AdminService.GetPlayerRole()
    AdminService.CacheBanList()
    AdminService.MutePlayer()
    AdminService.UnmutePlayer()
    AdminService.KickPlayer()
    AdminService.PermanentlyBanPlayer()
    AdminService.UnbanPlayerFromPermanentBan()
    AdminService.ServerBanPlayer()
    AdminService.UnbanPlayerFromServerBan()
    AdminService.AnnounceMessage()
    AdminService.WarnPlayer()
end

function AdminService.PromptPanel(Player, Message)
    if string.lower(Message) == "/panel" and table.find(StoredAdminUserIds, Player.UserId) then
        EnableAdminPanel:FireClient(Player)
    end
end

function AdminService.HandleAdminCheckRoleRequests()
    CheckPlayerRole.OnServerInvoke = function(_, NameOfPlayerBeingChecked)
        return AdminService.GetPlayerRole(NameOfPlayerBeingChecked)
    end
end

function AdminService.HandleHierarchyCheckRequests()
    CheckForHierarchyRequirement.OnServerInvoke = function(Player, NameOfPlayerBeingModerated)
        return AdminService.CheckIfPlayerMeetsHierarchyRequirement(Player.Name, NameOfPlayerBeingModerated)
    end
end

function AdminService.HandlePrivilegesCheck()
    CheckPlayerPrivileges.OnServerInvoke = function(Player, PrivilegeToCheckFor)
        return AdminService.CheckForPrivilege(Player.Name, PrivilegeToCheckFor)
    end
end

function AdminService.HandleKillLogs()
    local NumberOfSecondsIn5Min = 300

    task.spawn(function()
        while task.wait(NumberOfSecondsIn5Min) do
            local Webhook = AdminConfig.DiscordWebhook
            local LogText = ""
    
            for _, KillLog in ipairs(StoredKillLogs) do
                LogText = LogText.. "\n".. KillLog
            end
    
            local Data = HttpService:JSONEncode({
                ["content"] = LogText
            })
            
            pcall(function()
                HttpService:PostAsync(Webhook, Data)
            end)
    
            table.clear(StoredKillLogs)
        end
    end)
end

-- Helper methods

function AdminService.CacheBanList()
    pcall(function()
        local BanData = BanLogsData:GetSortedAsync(false, 30)
        local Page = BanData:GetCurrentPage()
        for _, Data in ipairs(Page) do
            if Data.value == 1 then
                local ShortenedKey = string.gsub(Data.key, "Player", "")
                local UserId = tonumber(string.sub(ShortenedKey, 2, string.len(ShortenedKey)))
                table.insert(StoredPermanentBans, UserId)
            end
        end
    end)
end

function AdminService.GetPlayerRole(PlayerName)
    local GroupId = AdminConfig.GroupId
    local AllowedGroupRanks = AdminConfig.AllowedGroupRanks
    local RankInGroup = AdminService.GetRankInGroupFromPlayerName(PlayerName)
    local AllowedPlayers = AdminConfig.AllowedPlayers
    local GroupResult = nil
    local UserIdResult = nil

    -- Check for Group
    if GroupId and RankInGroup then
        for _, Data in ipairs(AllowedGroupRanks) do
            if RankInGroup == Data.GroupRank then
                GroupResult = Data.Role
            end
        end
    end

    -- Check for UserID
    pcall(function()
        local PlayerUserId = Players:GetUserIdFromNameAsync(PlayerName)
        for _, Data in ipairs(AllowedPlayers) do
            if PlayerUserId == Data.UserId then
                UserIdResult = Data.Role
            end
        end
    end)

    -- If the player meets the UserId requirement and group requirement then the highest rank overrides.
    if GroupResult and UserIdResult then
        if HierarchyTable[GroupResult] > HierarchyTable[UserIdResult] then
            return GroupResult
        else
            return UserIdResult
        end
    end

    return GroupResult or UserIdResult
end

function AdminService.CheckForPrivilege(ModeratorName, PrivilegeToCheckFor)
    local PlayerRole = AdminService.GetPlayerRole(ModeratorName)
    if PlayerRole then
        if table.find(PrivilegeTable[PlayerRole], PrivilegeToCheckFor) then
            return true
        else
            return false
        end
    end
end

function AdminService.CheckIfPlayerMeetsHierarchyRequirement(ModeratorName, NameOfPlayerBeingModerated)
    local ModeratorLevel = AdminService.GetPlayerRole(ModeratorName)
    local PlayerBeingModeratedLevel = AdminService.GetPlayerRole(NameOfPlayerBeingModerated)

    if ModeratorLevel and not PlayerBeingModeratedLevel or PlayerBeingModeratedLevel and HierarchyTable[ModeratorLevel] > HierarchyTable[PlayerBeingModeratedLevel] then
        return true
    end

    return false
end

function AdminService.GetRankInGroupFromPlayerName(PlayerName)
    local Result = 0

    pcall(function()
        for _, GroupData in ipairs(GroupService:GetGroupsAsync(Players:GetUserIdFromNameAsync(PlayerName))) do
            for _, PropertyValue in pairs(GroupData) do
                if PropertyValue == AdminConfig.GroupId then
                   Result = GroupData.Rank
                end
            end 
        end
    end)

    return Result
end

function AdminService.FilterText(NameOfPlayer, Text)
    local Result = nil

    pcall(function()
        local PlayerUserId = Players:GetUserIdFromNameAsync(NameOfPlayer)
        Result = TextService:FilterStringAsync(Text, PlayerUserId):GetChatForUserAsync(PlayerUserId)
   end)

   return Result
end

function AdminService.AddPlayerToBanData(NameOfPlayerBeingBanned, PlayerBanning, BanReason)
    pcall(function()
        local Key = "Player-".. tostring(Players:GetUserIdFromNameAsync(NameOfPlayerBeingBanned))
        local Data = PunishmentData:GetAsync(Key)
    
        if not Data then
            AdminService.SetPlayerBanDataToDefault(NameOfPlayerBeingBanned)
        end
        
        PunishmentData:SetAsync(Key, {
            ["IsPlayerMuted"] = Data["IsPlayerMuted"],
            ["MuteReason"] = Data["MuteReason"],
            ["NameOfPersonWhoMuted"] = Data["NameOfPersonWhoMuted"],
        
            ["IsPlayerBanned"] = true,
            ["BanReason"] = BanReason,
            ["NameOfPersonWhoBanned"] = PlayerBanning.Name
        })
        
        BanLogsData:SetAsync(Key, 1)
    end)
end

function AdminService.SetPlayerBanDataToDefault(PlayerName)
    pcall(function()
        local Key = "Player-".. tostring(Players:GetUserIdFromNameAsync(PlayerName))

        PunishmentData:SetAsync(Key, {
            ["IsPlayerMuted"] = false,
            ["MuteReason"] = nil,
            ["NameOfPersonWhoMuted"] = nil,
        
            ["IsPlayerBanned"] = false,
            ["BanReason"] = nil,
            ["NameOfPersonWhoBanned"] = nil
        })
    end)
end

function AdminService.RemovePlayerFromBanData(NameOfPlayerBeingRemoved)
    pcall(function()
        local Key = "Player-".. tostring(Players:GetUserIdFromNameAsync(NameOfPlayerBeingRemoved))
        local Data = PunishmentData:GetAsync(Key)
        PunishmentData:SetAsync(Key, {
            ["IsPlayerMuted"] = Data["IsPlayerMuted"],
            ["MuteReason"] = Data["MuteReason"],
            ["NameOfPersonWhoMuted"] = Data["NameOfPersonWhoMuted"],
        
            ["IsPlayerBanned"] = false,
            ["BanReason"] = nil,
            ["NameOfPersonWhoBanned"] = nil
        })

        BanLogsData:RemoveAsync(Key)
    end)
end

function AdminService.IsPlayerBanned(NameOfPlayer)
    local Result = nil

    pcall(function()
        local Key = "Player-".. tostring(Players:GetUserIdFromNameAsync(NameOfPlayer))
        local Data = PunishmentData:GetAsync(Key)

        if Data and Data["IsPlayerBanned"] then
            Result = true
        end
   end)

    return Result
end

function AdminService.GetPlayerRegardlessOfCapitalization(PlayerName)
    for _, Player in ipairs(Players:GetPlayers()) do
        if string.lower(Player.Name) == string.lower(PlayerName) then
            return Player
        end
    end
end

function AdminService.AddNewBanListMember(UserId, BanType, SendToEveryone, PlayerToSendTo)
    if SendToEveryone then
        for _, Player in ipairs(Players:GetPlayers()) do
            if table.find(StoredAdminUserIds, Player.UserId) then
                CreateBanList:FireClient(Player, UserId, BanType)
            end
        end
    elseif PlayerToSendTo then
        CreateBanList:FireClient(PlayerToSendTo, UserId, BanType)
    end
end

function AdminService.RemoveBanListMember(UserId)
    for _, Player in ipairs(Players:GetPlayers()) do
        if table.find(StoredAdminUserIds, Player.UserId) then
            RemoveFromBanList:FireClient(Player, UserId)
        end
    end
end

-- Main Methods

function AdminService.SendLogToDiscord(LogText, PlayerAnnouncing)
    local Webhook = AdminConfig.DiscordWebhook

    if Webhook and Webhook ~= "" then
        if string.find(Webhook, "discord.com") then
            Webhook = string.gsub(Webhook, "discord.com", "hooks.hyra.io")
        elseif string.find(Webhook, "discordapp.com") then
            Webhook = string.gsub(Webhook, "discordapp.com", "hooks.hyra.io")
        end

        -- Prevents pinging through the webhook.
        if string.find(LogText, "@") then
            LogText = string.gsub(LogText, "@", "") 
        end

        if string.find(LogText, "Announcement from ") then
            LogText = string.gsub(LogText, "Announcement from ".. PlayerAnnouncing.Name.. ": ", "")
        end
    
        local Data = HttpService:JSONEncode({
            ["content"] = os.date("%X").. " | ".. os.date("%x").. "\n".. LogText
        })
    
        local Success, ErrorMessage = pcall(function()
            HttpService:PostAsync(Webhook, Data)
        end)
    
        if not Success then
            warn("There was an error sending the admin log to Discord. Please check your webhook. Error Message: ".. ErrorMessage)
        end
    end
end

function AdminService.CreateAdminLog(LogText, Store : boolean, Everyone : boolean, PlayerToPrompt, PlayerAnnouncing)
    AdminService.SendLogToDiscord(LogText, PlayerAnnouncing)
    if Everyone then
        for _, Player in ipairs(Players:GetPlayers()) do
            for _, AdminID in ipairs(StoredAdminUserIds) do
                if Player.UserId == AdminID then
                    CreateAdminLog:FireClient(Player, LogText)
                end
            end
        end
    else
        CreateAdminLog:FireClient(PlayerToPrompt, LogText)
    end

    if Store then
        table.insert(StoredAdminLogs, LogText)
    end
end

function AdminService.MutePlayer()
    MutePlayer.OnServerEvent:Connect(function(Player, NameOfPlayerBeingMuted, MuteReason)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Mute")
        local MeetsHierarchyRequirement = AdminService.CheckIfPlayerMeetsHierarchyRequirement(Player.Name, NameOfPlayerBeingMuted)

        if NameOfPlayerBeingMuted and MuteReason and MeetsHierarchyRequirement and HasPrivileges then
            local PlayerBeingMuted = Players:FindFirstChild(NameOfPlayerBeingMuted)
            local FilteredMuteReason = AdminService.FilterText(Player.Name, MuteReason)
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)

            if PlayerBeingMuted then
                HandleChatVisibility:FireClient(PlayerBeingMuted, "Disable")
                PromptWarnNotification:FireClient(PlayerBeingMuted, "MUTED", "You have been muted by ".. Player.Name.. "\n".. "\n".. "Reason: ".. FilteredMuteReason)
            end

            AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has Muted ".. NameOfPlayerBeingMuted.. " for the Reason: ".. FilteredMuteReason, true, true)
        end
    end)
end

function AdminService.UnmutePlayer()
    UnmutePlayer.OnServerEvent:Connect(function(Player, NameOfPlayerBeingUnmuted)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Mute")

        if NameOfPlayerBeingUnmuted and HasPrivileges then
            local PlayerBeingUnmuted = Players:FindFirstChild(NameOfPlayerBeingUnmuted)
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)

            if PlayerBeingUnmuted then
                HandleChatVisibility:FireClient(PlayerBeingUnmuted, "Enable")
                PromptWarnNotification:FireClient(PlayerBeingUnmuted, "UNMUTED", "You have been unmuted by ".. Player.Name)
            end

            AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has Unmuted ".. NameOfPlayerBeingUnmuted, true, true)
        end
    end)
end


function AdminService.PermanentlyBanPlayer()
    PermanentlyBanPlayer.OnServerEvent:Connect(function(Player, NameOfPlayerBeingBanned, BanReason)
        local DoesPlayerMeetHierarchyRequirement = AdminService.CheckIfPlayerMeetsHierarchyRequirement(Player.Name, NameOfPlayerBeingBanned)
        local FoundInCooldownTable = table.find(AdminsOnCooldown, Player.UserId)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Ban")

        if NameOfPlayerBeingBanned and DoesPlayerMeetHierarchyRequirement and not FoundInCooldownTable and HasPrivileges then
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)
            local PlayerBeingBanned = AdminService.GetPlayerRegardlessOfCapitalization(NameOfPlayerBeingBanned)
            local FilteredBanReason = AdminService.FilterText(Player.Name, BanReason)
            
            table.insert(AdminsOnCooldown, Player.UserId)
            ChangeCooldownState:FireClient(Player, "Enable")
            AdminService.AddPlayerToBanData(NameOfPlayerBeingBanned, Player, FilteredBanReason)
            AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has permanently Banned ".. NameOfPlayerBeingBanned.. " for the Reason: ".. FilteredBanReason, true, true)

            if PlayerBeingBanned then
                PlayerBeingBanned:Kick("\n".. "You have been permanently banned.".. "\n".. "Reason: ".. FilteredBanReason.. "\n".. "Banned by: ".. Player.Name)
            end
            
            pcall(function()
                AdminService.AddNewBanListMember(Players:GetUserIdFromNameAsync(NameOfPlayerBeingBanned), "Permanent", true, nil)
            end)

            task.spawn(function()
                task.wait(30)
                table.remove(AdminsOnCooldown, table.find(AdminsOnCooldown, Player.UserId))
                ChangeCooldownState:FireClient(Player, "Disable")
            end)
        end
    end)
end

function AdminService.ServerBanPlayer()
    ServerBanPlayer.OnServerEvent:Connect(function(Player, NameOfPlayerBeingBanned, BanReason)
        local MeetsHierarchyRequirement = AdminService.CheckIfPlayerMeetsHierarchyRequirement(Player.Name, NameOfPlayerBeingBanned)
        local FoundInCooldownTable = table.find(AdminsOnCooldown, Player.UserId)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Ban")

        if NameOfPlayerBeingBanned and MeetsHierarchyRequirement and not FoundInCooldownTable and HasPrivileges then
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)
            local PlayerBeingBanned = AdminService.GetPlayerRegardlessOfCapitalization(NameOfPlayerBeingBanned)
            local FilteredBanReason = AdminService.FilterText(Player.Name, BanReason)
            local KickMessage = "\n".. "You have been server banned.".. "\n".. "Reason: ".. FilteredBanReason.. "\n".. "Banned by: ".. Player.Name
        
            table.insert(AdminsOnCooldown, Player.UserId)
            ChangeCooldownState:FireClient(Player, "Enable")
            AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has server Banned ".. NameOfPlayerBeingBanned.. " for the Reason: ".. FilteredBanReason, true, true)
            AdminService.AddNewBanListMember(Players:GetUserIdFromNameAsync(NameOfPlayerBeingBanned), "Server", true, nil)

            if PlayerBeingBanned then
                PlayerBeingBanned:Kick(KickMessage)
            end

            pcall(function()
                table.insert(StoredServerBans, {UserId = Players:GetUserIdFromNameAsync(NameOfPlayerBeingBanned), Reason = KickMessage})
            end)

            task.spawn(function()
                task.wait(30)
                table.remove(AdminsOnCooldown, table.find(AdminsOnCooldown, Player.UserId))
                ChangeCooldownState:FireClient(Player, "Disable")
            end)
        end
    end)
end

function AdminService.UnbanPlayerFromPermanentBan()
    UnbanPlayerFromPermanentBan.OnServerEvent:Connect(function(Player, NameOfPlayerBeingUnbanned)
        local FoundInCooldownTable = table.find(AdminsOnCooldown, Player.UserId)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Ban")

        if NameOfPlayerBeingUnbanned and not FoundInCooldownTable and HasPrivileges then
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)
            
            table.insert(AdminsOnCooldown, Player.UserId)
            ChangeCooldownState:FireClient(Player, "Enable")

            AdminService.RemovePlayerFromBanData(NameOfPlayerBeingUnbanned)
            AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has Unbanned ".. NameOfPlayerBeingUnbanned.. " from a permanent ban", true, true)

            pcall(function()
                local PlayerBeingBannedUnbannedUserId = Players:GetUserIdFromNameAsync(NameOfPlayerBeingUnbanned)
                AdminService.RemoveBanListMember(PlayerBeingBannedUnbannedUserId)
                local PosInTable = table.find(StoredPermanentBans, PlayerBeingBannedUnbannedUserId)
                table.remove(StoredPermanentBans, PosInTable)
            end)

            task.spawn(function()
                task.wait(30)
                table.remove(AdminsOnCooldown, table.find(AdminsOnCooldown, Player.UserId))
                ChangeCooldownState:FireClient(Player, "Enable")
            end)
        end
    end)
end

function AdminService.UnbanPlayerFromServerBan()
    UnbanPlayerFromServerBan.OnServerEvent:Connect(function(Player, NameOfPlayerBeingUnbanned)
        local FoundInCooldownTable = table.find(AdminsOnCooldown, Player.UserId)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Ban")
        local PlayerRole = AdminService.GetPlayerRole(Player.Name)
        local PlayerBeingBannedUserId = nil

        pcall(function()
            PlayerBeingBannedUserId = Players:GetUserIdFromNameAsync(NameOfPlayerBeingUnbanned)
        end)

        if NameOfPlayerBeingUnbanned and not FoundInCooldownTable and HasPrivileges then
            for Index, ServerBanData in ipairs(StoredServerBans) do
                if ServerBanData.UserId == PlayerBeingBannedUserId then
                    table.insert(AdminsOnCooldown, Player.UserId)
                    ChangeCooldownState:FireClient(Player, "Enable")        

                    AdminService.RemoveBanListMember(PlayerBeingBannedUserId)
                    AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has Unbanned ".. NameOfPlayerBeingUnbanned.. " from a server ban", true, true)
                    table.remove(StoredServerBans, Index)

                    task.spawn(function()
                        task.wait(30)
                        table.remove(AdminsOnCooldown, table.find(AdminsOnCooldown, Player.UserId))
                        ChangeCooldownState:FireClient(Player, "Enable")
                    end)
                end
            end
        end
    end)
end

function AdminService.AnnounceMessage()
    MakeAnnouncement.OnServerEvent:Connect(function(Player, AnnouncementTitle, AnnouncementMessage)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Announce")
    
        if AnnouncementTitle and AnnouncementMessage and HasPrivileges then
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)
            local FilteredAnnouncementMessage = "Announcement from ".. Player.Name.. ": ".. AdminService.FilterText(Player.Name, AnnouncementMessage)
            local FilteredAnnouncementTitle = AdminService.FilterText(Player.Name, AnnouncementTitle)

            PromptWarnNotification:FireAllClients(FilteredAnnouncementTitle, FilteredAnnouncementMessage)
            AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has made an Announcement".. "\n".. "Title: ".. FilteredAnnouncementTitle.. "\n".. "Message: ".. FilteredAnnouncementMessage, true, true, nil, Player)
        end
    end)
end

function AdminService.WarnPlayer()
    WarnPlayer.OnServerEvent:Connect(function(Player, NameOfPlayerBeingWarned, WarnReason)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Warn")
        local MeetsHierarchyRequirement = AdminService.CheckIfPlayerMeetsHierarchyRequirement(Player.Name, NameOfPlayerBeingWarned)

        if WarnReason and NameOfPlayerBeingWarned and MeetsHierarchyRequirement and HasPrivileges then
            local FilteredWarnReason = AdminService.FilterText(Player.Name, WarnReason)
            local PlayerBeingWarned = AdminService.GetPlayerRegardlessOfCapitalization(NameOfPlayerBeingWarned)
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)

            if PlayerBeingWarned then
                PromptWarnNotification:FireClient(PlayerBeingWarned, "WARNING", Player.Name.. " says: ".. FilteredWarnReason)
                AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has Warned ".. NameOfPlayerBeingWarned.. " for the Reason: ".. FilteredWarnReason, true, true)
            end
        end
    end)
end

function AdminService.KickPlayer()
    KickPlayer.OnServerEvent:Connect(function(Player, NameOfPlayerBeingKicked, KickReason)
        local HasPrivileges = AdminService.CheckForPrivilege(Player.Name, "Kick")
        local MeetsHierarchyRequirement = AdminService.CheckIfPlayerMeetsHierarchyRequirement(Player.Name, NameOfPlayerBeingKicked)

        if NameOfPlayerBeingKicked and KickReason and MeetsHierarchyRequirement and HasPrivileges then
            local FilteredKickReason = AdminService.FilterText(Player.Name, KickReason)
            local PlayerBeingKicked = AdminService.GetPlayerRegardlessOfCapitalization(NameOfPlayerBeingKicked)
            local PlayerRole = AdminService.GetPlayerRole(Player.Name)

            if PlayerBeingKicked then
                PlayerBeingKicked:Kick("\n".. "You have been kicked.".. "\n".. "Reason: ".. FilteredKickReason.. "\n".. "Kicked by: ".. Player.Name)
                AdminService.CreateAdminLog("[".. PlayerRole.. "]".. " ".. Player.Name.. " has Kicked ".. NameOfPlayerBeingKicked.. " for the Reason: ".. FilteredKickReason, true, true)
            end
        end
    end)
end

return AdminService
