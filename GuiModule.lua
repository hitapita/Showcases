-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Modules
local TweeningModule = require(script.Parent:WaitForChild("TweeningModule"))

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

local GuiModule = {}

function GuiModule:Init()
    self.Player = game.Players.LocalPlayer
    self.AdminPanelGUI = self.Player:WaitForChild("PlayerGui"):WaitForChild("AdminPanelGUI")
    self.AdminGui = self.AdminPanelGUI:WaitForChild("AdminGui")
    self.AvatarImage = self.AdminGui:WaitForChild("AvatarImage")
    self.UsernameLabel = self.AdminGui:WaitForChild("Username")
    self.CloseButton = self.AdminGui:WaitForChild("MainCloseButton")
    self.InputBox = self.AdminGui:WaitForChild("InputFrame"):WaitForChild("InputFrame"):WaitForChild("InputBox")
    self.AdminsFrame = self.AdminGui:WaitForChild("Admins")
    self.AdminTemplate = self.AdminsFrame:WaitForChild("AdminTemplate")
    self.PunishmentGui = self.AdminPanelGUI:WaitForChild("PunishmentGui")
    self.SendPunishmentButton = self.PunishmentGui:WaitForChild("SendPunishmentButton")
    self.SendPunishmentButtonTextLabel = self.SendPunishmentButton:WaitForChild("TextLabel")
    self.PunishmentGuiClose = self.PunishmentGui:WaitForChild("Close")
    self.PunishmentName = self.PunishmentGui:WaitForChild("PunishmentName")
    self.AnnouncementGui = self.AdminPanelGUI:WaitForChild("AnnouncementGui")
    self.NotificationFrame = self.AdminPanelGUI:WaitForChild("Notification")
    self.AcknowledgeButton = self.NotificationFrame:WaitForChild("AcknowledgeButton")
    self.ConfirmGui = self.AdminPanelGUI:WaitForChild("ConfirmGui")
    self.ActionName = self.ConfirmGui:WaitForChild("ActionName")
    self.ConfirmButton = self.ConfirmGui:WaitForChild("Confirm")
    self.AnnouncementTitleBox = self.AnnouncementGui:WaitForChild("TitleFrame"):WaitForChild("TextBox")
    self.AnnouncementMessageBox = self.AnnouncementGui:WaitForChild("MessageFrame"):WaitForChild("TextBox")
    self.LogsGui = self.AdminPanelGUI:WaitForChild("LogsGui")
    self.BanListGui = self.AdminPanelGUI:WaitForChild("BanListGui")
    self.ChooseBanType = self.AdminPanelGUI:WaitForChild("ChooseBanType")
    self.ChooseUnbanType = self.AdminPanelGUI:WaitForChild("ChooseUnbanType")
    self.ServerBanButton = self.ChooseBanType:WaitForChild("ServerBan")
    self.PermanentBanButton = self.ChooseBanType:WaitForChild("PermanentBan")
    self.UnbanFromPermBanButton = self.ChooseUnbanType:WaitForChild("UnbanFromPermBan")
    self.UnbanFromServerBanButton = self.ChooseUnbanType:WaitForChild("UnbanFromServerBan")
    self.OnCommandCooldown = false

    GuiModule:SetupGreetingInfo()
    GuiModule:HandleCloseButtons()
    GuiModule:HandleSendPunishmentButton()
    GuiModule:HandleConfirmPunishmentButton()
    GuiModule:HandleBanTypeAndUnbanTypeButtons()
    GuiModule:HandleAdminList()
    GuiModule:HandleChatVisibility()
    GuiModule:HandleCommandCooldown()
    GuiModule:HandleBanList()
    GuiModule:PromptWarningMessage()
    GuiModule:HandleAcknowledgeButton()
    GuiModule:CreateAdminLog()
    GuiModule:EnableAdminPanel()
    
    for _, PunishmentButton in ipairs(self.AdminGui:GetChildren()) do
        if PunishmentButton:IsA("TextButton") then
            PunishmentButton.MouseButton1Click:Connect(function()
                self.PunishmentName.Text = PunishmentButton.Name
                self.SendPunishmentButtonTextLabel.Text = PunishmentButton.Name
                self.ActionName.Name = PunishmentButton.Name

                local HasMutePrivileges = CheckPlayerPrivileges:InvokeServer("Mute")
                local HasBanPrivileges = CheckPlayerPrivileges:InvokeServer("Ban")
                local HasAnnouncePrivileges = CheckPlayerPrivileges:InvokeServer("Announce")
                local HasKickPrivileges = CheckPlayerPrivileges:InvokeServer("Kick")
                local HasWarnPrivileges = CheckPlayerPrivileges:InvokeServer("Warn")
                local MeetsHierarchyRequirement = CheckForHierarchyRequirement:InvokeServer(self.InputBox.Text)

                local function BasicPunishmentTween()
                    TweeningModule.TweenSideFramesIn(self.LogsGui, self.BanListGui)
                    TweeningModule.TweenGuiDown(self.AdminGui, true)
                    TweeningModule.TweenGuiUp(self.PunishmentGui, UDim2.fromScale(0.305, 0.266), true)
                end

                if PunishmentButton.Name == "Announce" and HasAnnouncePrivileges then
                    TweeningModule.TweenSideFramesIn(self.LogsGui, self.BanListGui)
                    TweeningModule.TweenGuiDown(self.AdminGui, true)
                    TweeningModule.TweenGuiUp(self.AnnouncementGui, UDim2.fromScale(0.327, 0.279), true)
                elseif PunishmentButton.Name == "Unmute" and not GuiModule:CheckForInputErrors(self.InputBox.Text, true) and HasMutePrivileges then
                    TweeningModule.TweenSideFramesIn(self.LogsGui, self.BanListGui)
                    TweeningModule.TweenGuiDown(self.AdminGui, true)
                    TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
                end

                if not GuiModule:CheckForInputErrors(self.InputBox.Text, true) and MeetsHierarchyRequirement then
                    if PunishmentButton.Name == "Kick" and HasKickPrivileges or PunishmentButton.Name == "Warn" and HasWarnPrivileges or PunishmentButton.Name == "Mute" and HasMutePrivileges then
                        BasicPunishmentTween()
                    end 
                end

                if not self.OnCommandCooldown and not GuiModule:CheckForInputErrors(self.InputBox.Text) and HasBanPrivileges then
                    if PunishmentButton.Name == "Ban" and MeetsHierarchyRequirement then
                        BasicPunishmentTween()
                    elseif PunishmentButton.Name == "Unban" then
                        TweeningModule.TweenSideFramesIn(self.LogsGui, self.BanListGui)
                        TweeningModule.TweenGuiDown(self.AdminGui, true)
                        TweeningModule.TweenGuiUp(self.ChooseUnbanType, UDim2.fromScale(0.388, 0.356), true)
                    end
                end
            end)
        end
    end
end

function GuiModule:AddMemberToAdminList(Player, Role)
    if not self.AdminsFrame:FindFirstChild(tostring(Player.UserId)) then
        local TemplateClone = self.AdminTemplate:Clone()
        local Username = TemplateClone.Username
        local AvatarImage = TemplateClone.AvatarImage
        local RoleLabel = TemplateClone.Role

        TemplateClone.Name = tostring(Player.UserId)
        Username.Text = Player.Name
        RoleLabel.Text = Role
        pcall(function()
            AvatarImage.Image = Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
        end)

        TemplateClone.Visible = true
        TemplateClone.Parent = self.AdminsFrame
    end
end

function GuiModule:RemoveMemberFromAdminList(Player)
    local AdminFrame = self.AdminsFrame:FindFirstChild(tostring(Player.UserId))
    if AdminFrame then
        AdminFrame:Destroy()
    end
end

function GuiModule:HandleChatVisibility()
    HandleChatVisibility.OnClientEvent:Connect(function(NewVisibilityState)
        pcall(function()
            if NewVisibilityState == "Enable" then
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
            elseif NewVisibilityState == "Disable" then
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
            end
        end)
    end)
end

function GuiModule:HandleBanTypeAndUnbanTypeButtons()
    self.UnbanFromPermBanButton.MouseButton1Click:Connect(function()
        self.ActionName.Name = "UnbanFromPermBan"
        TweeningModule.TweenGuiDown(self.ChooseUnbanType, true)
        TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
    end)

    self.UnbanFromServerBanButton.MouseButton1Click:Connect(function()
        self.ActionName.Name = "UnbanFromServerBan"
        TweeningModule.TweenGuiDown(self.ChooseUnbanType, true)
        TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
    end)

    self.ServerBanButton.MouseButton1Click:Connect(function()
        self.ActionName.Name = "ServerBan"
        TweeningModule.TweenGuiDown(self.ChooseBanType, true)
        TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
    end)

    self.PermanentBanButton.MouseButton1Click:Connect(function()
        self.ActionName.Name = "PermanentBan"
        TweeningModule.TweenGuiDown(self.ChooseBanType, true)
        TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
    end)
end

function GuiModule:HandleAdminList()
    -- Players may have joined before the script started and the LocalPlayer could also be an admin.
    for _, PlayerInGame in ipairs(Players:GetPlayers()) do
        local PlayerRole = CheckPlayerRole:InvokeServer(PlayerInGame.Name)
        if PlayerRole then
            GuiModule:AddMemberToAdminList(PlayerInGame, PlayerRole)
        end
    end

    AddPlayerToAdminList.OnClientEvent:Connect(function(Admin, Role)
        GuiModule:AddMemberToAdminList(Admin, Role)
    end)

    RemovePlayerFromAdminList.OnClientEvent:Connect(function(Admin)
        GuiModule:RemoveMemberFromAdminList(Admin)
    end)
end

function GuiModule:HandleCommandCooldown()
    ChangeCooldownState.OnClientEvent:Connect(function(NewState)
        local BanButtonNameLabel = self.AdminGui:WaitForChild("Ban"):WaitForChild("TextLabel")
        local UnbanButtonLabel = self.AdminGui:WaitForChild("Unban"):WaitForChild("TextLabel")

        if NewState == "Enable" then
            BanButtonNameLabel.Text = "Cooldown"
            UnbanButtonLabel.Text = "Cooldown"
            self.OnCommandCooldown = true
        elseif NewState == "Disable" then
            BanButtonNameLabel.Text = "Ban"
            UnbanButtonLabel.Text = "Unban"
            self.OnCommandCooldown = false
        end
    end)
end

function GuiModule:HandleBanList()
    local ScrollingFrame = self.BanListGui:WaitForChild("ScrollingFrame")
    local BanListTemplate = ScrollingFrame:WaitForChild("LogTemplate")

    CreateBanList.OnClientEvent:Connect(function(UserId, BanType)
        pcall(function()
            local TemplateClone = BanListTemplate:Clone()
            TemplateClone.Text = string.upper(BanType).. " - ".. Players:GetNameFromUserIdAsync(UserId)
            TemplateClone.Name = tostring(UserId)
            TemplateClone.Visible = true
            TemplateClone.Parent = ScrollingFrame
        end)
    end)

    RemoveFromBanList.OnClientEvent:Connect(function(UserId)
        local BanLabel = ScrollingFrame:FindFirstChild(tostring(UserId))
        if BanLabel then
            BanLabel:Destroy()
        end
    end)
end

function GuiModule:CreateAdminLog()
    CreateAdminLog.OnClientEvent:Connect(function(LogText)
        local ScrollingFrame = self.LogsGui:WaitForChild("ScrollingFrame")
        local LogTemplate = ScrollingFrame:WaitForChild("LogTemplate")
        local Log = LogTemplate:Clone()
        Log.Text = LogText
        Log.Visible = true
        Log.Parent = ScrollingFrame
    end)
end

function GuiModule:SetupGreetingInfo()
    self.UsernameLabel.Text = self.Player.Name
    pcall(function()
        self.AvatarImage.Image = Players:GetUserThumbnailAsync(self.Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size60x60)
    end)
end

function GuiModule:CheckForInputErrors(Text, CheckForPlayer)
    if CheckForPlayer then
        local ResultFound = false
        
        for _, Player in ipairs(Players:GetPlayers()) do
            if string.lower(Player.Name) == string.lower(Text) then
                ResultFound = true
            end
        end

        if not ResultFound then
            return true
        end
    end
    
    if string.lower(Text) == string.lower(self.Player.Name) then
        return true
    end

    if string.match(Text, "%s") or not string.match(Text, "%w") or string.len(Text) > 20 then
        return true
    end

    for i = 1, string.len(Text) do
        local Letter = string.sub(Text, i, i)
        if string.match(Letter, "%p") and Letter ~= "_" then
            return true
        end
    end

    return false
end

function GuiModule:HandleSendPunishmentButton()
    local PunishmentReasonBox = self.PunishmentGui:WaitForChild("ReasonFrame"):WaitForChild("ReasonBox")

    for _, PunishmentButton in ipairs(self.AdminPanelGUI:GetDescendants()) do
        if PunishmentButton.Name == "SendPunishmentButton" then
            PunishmentButton.MouseButton1Click:Connect(function()
                local PunishmentNameLabel = PunishmentButton.Parent:FindFirstChildOfClass("TextLabel")

                if PunishmentReasonBox.Text ~= "" and PunishmentNameLabel.Text ~= "Announcement" and not string.find(string.lower(PunishmentNameLabel.Text), "ban") then
                    self.ActionName.Name = PunishmentNameLabel.Text
                    TweeningModule.TweenGuiDown(self.PunishmentGui, true)
                    TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
                elseif PunishmentNameLabel.Text == "Announcement" and self.AnnouncementTitleBox.Text ~= "" and self.AnnouncementMessageBox.Text ~= "" then
                    self.ActionName.Name = "Announcement"
                    TweeningModule.TweenGuiDown(self.AnnouncementGui, true)
                    TweeningModule.TweenGuiUp(self.ConfirmGui, UDim2.fromScale(0.388, 0.356), true)
                elseif PunishmentNameLabel.Text == "Ban" then
                    self.ActionName.Name = PunishmentNameLabel.Text
                    TweeningModule.TweenGuiDown(self.PunishmentGui, true)
                    TweeningModule.TweenGuiUp(self.ChooseBanType, UDim2.fromScale(0.388, 0.356), true)
                elseif PunishmentNameLabel.Text == "Unban" then
                    self.ActionName.Name = PunishmentNameLabel.Text
                    TweeningModule.TweenGuiDown(self.PunishmentGui, true)
                    TweeningModule.TweenGuiUp(self.ChooseUnbanType, UDim2.fromScale(0.388, 0.356), true)
                end
            end)
        end
    end
end

function GuiModule:HandleConfirmPunishmentButton()
    local PunishmentReasonBox = self.PunishmentGui:WaitForChild("ReasonFrame"):WaitForChild("ReasonBox")

    self.ConfirmButton.MouseButton1Click:Connect(function()
        if self.ActionName.Name == "Kick" then
            KickPlayer:FireServer(self.InputBox.Text, PunishmentReasonBox.Text)
        elseif self.ActionName.Name == "Warn" then
            WarnPlayer:FireServer(self.InputBox.Text, PunishmentReasonBox.Text)
        elseif self.ActionName.Name == "Mute" then
            MutePlayer:FireServer(self.InputBox.Text, PunishmentReasonBox.Text)
        elseif self.ActionName.Name == "PermanentBan" then
            PermanentlyBanPlayer:FireServer(self.InputBox.Text, PunishmentReasonBox.Text)
        elseif self.ActionName.Name == "ServerBan" then
            ServerBanPlayer:FireServer(self.InputBox.Text, PunishmentReasonBox.Text)
        elseif self.ActionName.Name == "Announcement" then
            MakeAnnouncement:FireServer(self.AnnouncementTitleBox.Text, self.AnnouncementMessageBox.Text)
        elseif self.ActionName.Name == "UnbanFromPermBan" then
            UnbanPlayerFromPermanentBan:FireServer(self.InputBox.Text)
        elseif self.ActionName.Name == "UnbanFromServerBan" then
            UnbanPlayerFromServerBan:FireServer(self.InputBox.Text)
        elseif self.ActionName.Name == "Unmute" then
            UnmutePlayer:FireServer(self.InputBox.Text)
        end

        TweeningModule.TweenGuiDown(self.ConfirmGui, true)
        TweeningModule.TweenGuiUp(self.AdminGui, UDim2.fromScale(0.344, 0.269), true)
        TweeningModule.TweenSideFramesOut(self.LogsGui, self.BanListGui)
    end)
end

function GuiModule:HandleAcknowledgeButton()
    self.AcknowledgeButton.MouseButton1Click:Connect(function()
        TweeningModule.TweenNotificationFrameRight(self.NotificationFrame)
    end)
end

function GuiModule:HandleCloseButtons()
    self.CloseButton.MouseButton1Click:Connect(function()
        TweeningModule.TweenSideFramesIn(self.LogsGui, self.BanListGui)
        TweeningModule.TweenGuiDown(self.AdminGui, true)
    end)

    for _, CloseButton in ipairs(self.AdminPanelGUI:GetDescendants()) do
        if CloseButton:IsA("ImageButton") or CloseButton:IsA("TextButton") then
            if CloseButton.Name == "Close" or CloseButton.Name == "Cancel" then
                CloseButton.MouseButton1Click:Connect(function()
                    TweeningModule.TweenGuiDown(CloseButton.Parent, true)
                    TweeningModule.TweenGuiUp(self.AdminGui, UDim2.fromScale(0.344, 0.269), true)
                    TweeningModule.TweenSideFramesOut(self.LogsGui, self.BanListGui)
                end)
            end
        end
    end
end

function GuiModule:EnableAdminPanel()
    EnableAdminPanel.OnClientEvent:Connect(function()
        if not self.AdminGui.Visible then
            for _, Frame in ipairs(self.AdminPanelGUI:GetChildren()) do
                if Frame:IsA("Frame") and Frame.Visible then
                    TweeningModule.TweenGuiDown(Frame)
                end
            end
        end

        TweeningModule.TweenGuiUp(self.AdminGui, UDim2.fromScale(0.344, 0.269), true)
        self.LogsGui.Position = UDim2.fromScale(0.415, 0.269)
        self.BanListGui.Position = UDim2.fromScale(0.415, 0.269)
        TweeningModule.TweenSideFramesOut(self.LogsGui, self.BanListGui)
    end)
end

function GuiModule:PromptWarningMessage()
        PromptWarnNotification.OnClientEvent:Connect(function(AnnouncementTitle, AnnouncementMessage)
        local Title = self.NotificationFrame:WaitForChild("NotificationTitle")
        local Message = self.NotificationFrame:WaitForChild("NotificationMessage")

        Title.Text = AnnouncementTitle
        Message.Text = AnnouncementMessage

        TweeningModule.TweenNotificationFrameLeft(self.NotificationFrame)
    end)
end

return GuiModule
