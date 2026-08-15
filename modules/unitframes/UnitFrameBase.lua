local _, NivUI = ...

NivUI.UnitFrames = NivUI.UnitFrames or {}

local Runtime = NivUI.UnitFrames.Runtime
local HealthUpdater = Runtime.HealthUpdater
local StandardWidgetUpdater = Runtime.StandardWidgetUpdater
local CastbarUpdater = Runtime.CastbarUpdater
local WidgetTree = Runtime.WidgetTree
local EventRouter = Runtime.EventRouter
local SecureFrame = Runtime.SecureFrame
local NameRefresh = Runtime.NameRefresh

local UnitFrameBase = {}
NivUI.UnitFrames.Base = UnitFrameBase

UnitFrameBase.CreateHideBlizzardFrame = SecureFrame.CreateHideBlizzardFrame
UnitFrameBase.SetSecureVisibility = SecureFrame.SetSecureVisibility
UnitFrameBase.UpdateHealthBar = HealthUpdater.UpdateHealthBar
UnitFrameBase.UpdatePowerBar = StandardWidgetUpdater.UpdatePowerBar
UnitFrameBase.UpdateHealthText = StandardWidgetUpdater.UpdateHealthText
UnitFrameBase.UpdatePowerText = StandardWidgetUpdater.UpdatePowerText
UnitFrameBase.UpdatePortrait = StandardWidgetUpdater.UpdatePortrait
UnitFrameBase.UpdateStatusIndicators = StandardWidgetUpdater.UpdateStatusIndicators
UnitFrameBase.UpdateStatusText = StandardWidgetUpdater.UpdateStatusText
UnitFrameBase.UpdateRaidMarker = StandardWidgetUpdater.UpdateRaidMarker
UnitFrameBase.UpdateLeaderIcon = StandardWidgetUpdater.UpdateLeaderIcon
UnitFrameBase.UpdateRoleIcon = StandardWidgetUpdater.UpdateRoleIcon
UnitFrameBase.UpdateNameText = StandardWidgetUpdater.UpdateNameText
UnitFrameBase.UpdateLevelText = StandardWidgetUpdater.UpdateLevelText
UnitFrameBase.UpdateCastbar = CastbarUpdater.UpdateCastbar
UnitFrameBase.UpdateRangeAlpha = StandardWidgetUpdater.UpdateRangeAlpha
UnitFrameBase.CreateWidgets = WidgetTree.CreateWidgets
UnitFrameBase.ApplyAnchors = WidgetTree.ApplyAnchors
UnitFrameBase.HandleEvent = EventRouter.HandleEvent
UnitFrameBase.RegisterStandardEvents = EventRouter.RegisterStandardEvents
UnitFrameBase.BuildCustomFrame = SecureFrame.BuildCustomFrame
UnitFrameBase.CheckVisibility = SecureFrame.CheckVisibility
UnitFrameBase.ApplyPendingVisibility = SecureFrame.ApplyPendingVisibility
UnitFrameBase.DestroyCustomFrame = SecureFrame.DestroyCustomFrame
UnitFrameBase.CreateModule = SecureFrame.CreateModule

function UnitFrameBase.UpdateAllWidgets(state)
    UnitFrameBase.UpdateHealthBar(state)
    UnitFrameBase.UpdateHealthText(state)
    UnitFrameBase.UpdatePowerBar(state)
    UnitFrameBase.UpdatePowerText(state)
    UnitFrameBase.UpdatePortrait(state)
    UnitFrameBase.UpdateNameText(state)
    UnitFrameBase.UpdateLevelText(state)
    UnitFrameBase.UpdateStatusIndicators(state)
    UnitFrameBase.UpdateStatusText(state)
    UnitFrameBase.UpdateRaidMarker(state)
    UnitFrameBase.UpdateLeaderIcon(state)
    UnitFrameBase.UpdateRoleIcon(state)
    UnitFrameBase.UpdateCastbar(state)
    UnitFrameBase.UpdateRangeAlpha(state)
    StandardWidgetUpdater.CascadeAnchorVisibility(state)
end

EventRouter.SetFacade(UnitFrameBase)
SecureFrame.SetFacade(UnitFrameBase)
NameRefresh.Start(function(state, resolverSnapshot)
    UnitFrameBase.UpdateNameText(state, resolverSnapshot)
end)
