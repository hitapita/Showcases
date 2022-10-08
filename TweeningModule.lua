-- Services
local TweenService = game:GetService("TweenService")

-- Constants
local Tween_Info = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, 0, false, 0)


local TweeningModule = {}

-- Multiple functions used for simplicity in name.

function TweeningModule.TweenGuiUp(Frame, OriginalPosition, Yield)
    local UpTween = TweenService:Create(Frame, Tween_Info, {Position = OriginalPosition})

    Frame.Position = UDim2.fromScale(OriginalPosition.X.Scale, 1)
    Frame.Visible = true
    UpTween:Play()

    --  Completed event wouldn't fire properly.
    if Yield then
        repeat 
            task.wait()
        until UpTween.PlaybackState == Enum.PlaybackState.Completed
    end
end

function TweeningModule.TweenGuiDown(Frame, Yield)
    local HiddenPosition = UDim2.fromScale(Frame.Position.X.Scale, 1)
    local DownTween = TweenService:Create(Frame, Tween_Info, {Position = HiddenPosition})

    DownTween:Play()

    --  Completed event wouldn't fire properly.
    if Yield then
        repeat 
            task.wait()
        until DownTween.PlaybackState == Enum.PlaybackState.Completed
    end
    Frame.Visible = false
end

function TweeningModule.TweenNotificationFrameLeft(Frame)
    local ShownPosition = UDim2.fromScale(0.866, 0.322)
    local LeftTween = TweenService:Create(Frame, Tween_Info, {Position = ShownPosition})

    Frame.Position = UDim2.fromScale(1, 0.322)
    Frame.Visible = true
    LeftTween:Play()
end

function TweeningModule.TweenNotificationFrameRight(Frame)
    local HiddenPosition = UDim2.fromScale(1, 0.322)
    local RightTween = TweenService:Create(Frame, Tween_Info, {Position = HiddenPosition})

    RightTween:Play()
    RightTween.Completed:Wait()
    Frame.Visible = false
end

function TweeningModule.TweenSideFramesOut(AdminLogFrame, BanListFrame)
    local AdminLogHiddenPos = UDim2.fromScale(0.415, 0.269)
    local AdminLogShownPos = UDim2.fromScale(0.169, 0.269)
    local BanListHiddenPos = UDim2.fromScale(0.415, 0.269)
    local BanListShownPos = UDim2.fromScale(0.661, 0.269)

    local AdminLogTween = TweenService:Create(AdminLogFrame, Tween_Info, {Position = AdminLogShownPos})
    local BanListTween = TweenService:Create(BanListFrame, Tween_Info, {Position = BanListShownPos})

    AdminLogFrame.Position = AdminLogHiddenPos
    BanListFrame.Position = BanListHiddenPos

    AdminLogFrame.Visible = true
    BanListFrame.Visible = true

    AdminLogTween:Play()
    BanListTween:Play()

    repeat
        task.wait()
    until BanListTween.PlaybackState == Enum.PlaybackState.Completed and AdminLogTween.PlaybackState == Enum.PlaybackState.Completed
end

function TweeningModule.TweenSideFramesIn(AdminLogFrame, BanListFrame)
    local AdminLogHiddenPos = UDim2.fromScale(0.415, 0.269)
    local BanListHiddenPos = UDim2.fromScale(0.415, 0.269)

    local AdminLogTween = TweenService:Create(AdminLogFrame, Tween_Info, {Position = AdminLogHiddenPos})
    local BanListTween = TweenService:Create(BanListFrame, Tween_Info, {Position = BanListHiddenPos})

    AdminLogTween:Play()
    BanListTween:Play()

    repeat
        task.wait()
    until BanListTween.PlaybackState == Enum.PlaybackState.Completed and AdminLogTween.PlaybackState == Enum.PlaybackState.Completed

    AdminLogFrame.Visible = false
    BanListFrame.Visible = false
end


return TweeningModule

-- This script is the tweening module of my open-sourced admin panel.
