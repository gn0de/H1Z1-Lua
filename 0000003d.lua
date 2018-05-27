--@TODO: rename to UIStateManager instead and all corresponding state names

UIStateManager = {}
UIStateManager.currentState = nil
UIStateManager.EVENT_STATE_CHANGE = 'OnStateChange'
UIStateManager.isChangingState = false

LUABroadcaster:addListener( GameEvents, GameEvents.EVENT_GAME_STATE_CHANGE, 'OnGameStateChange', UIStateManager )
LUABroadcaster:addListener( GameEvents, GameEvents.EVENT_PLAYER_EQUIPMENT_TERMINAL_INTERACTION, 'SetPlayerEquipmentTerminalState', UIStateManager )
LUABroadcaster:addListener( GameEvents, GameEvents.EVENT_VEHICLE_TERMINAL_INTERACTION, 'SetVehicleTerminalState', UIStateManager )
LUABroadcaster:addListener( GameEvents, GameEvents.EVENT_WARPGATE_TERMINAL_INTERACTION, 'SetWarpgateTerminalState', UIStateManager )

function UIStateManager:GetCurrentState()
	return self.currentState
end

function UIStateManager:SetCurrentState( toState, ... )
	--preventing recursive calls
	if UIStateManager.isChangingState == true then
		return
	end
	
	if toState == self.currentState then
		if toState and toState.OnResetState then
--			toState:OnResetState( toState, ... )
		end
		
		return
	end
	
	UIStateManager.isChangingState = true
	
	local fromState = self.currentState
	
	if fromState then
		fromState:OnExitState( toState, ... )
	end
	
	self.currentState = toState	
	toState:OnEnterState( fromState, ... )
	
	UIStateManager.isChangingState = false
	LUABroadcaster:dispatchEvent( UIStateManager, UIStateManager.EVENT_STATE_CHANGE, fromState, toState )
end

function UIStateManager:OnGameStateChange( fromState, toState )
	if toState == GameStates.KILL_CAM then
		if self.currentState == UIStateEscapeMenu and not NavigationMenuHandler:IsTerminalMode() then
			NotificationHandler:ShowErrorNotification( Ui.GetString( 'UI.RespawnShortlyKillNotif' ) )
		else
			self:SetCurrentState( UIStateKillCam )
		end
	elseif toState == GameStates.SPAWN_SELECTION then
		self:SetSpawnSelectionState()
	elseif toState == GameStates.ALIVE_INFANTRY then
		self:SetCurrentState( UIStateInfantryHud )
	elseif toState == GameStates.CHARACTER_SELECT then
		self:SetCurrentState( UIStateCharacterSelect )
	elseif toState == GameStates.ZONE_LOADING then
		self:SetCurrentState( UIStateZoneLoading )
	elseif toState == GameStates.FIRST_TIME_INTRO then
		self:SetCurrentState( UIStateFirstTimeIntro )
	end
end

UIStateBase = {}
UIStateBase.name = ''
UIStateBase.manager = UIStateManager

--FOR OVERRIDE
function UIStateBase:OnEnterState( lastState )
	
end

function UIStateBase:OnResetState( currentState)

end

--FOR OVERRIDE
function UIStateBase:OnExitState( nextState )

end

--SHORTCUTS
function UIStateManager:SetNullState()
	self:SetCurrentState( UIStateNull )
end

function UIStateManager:SetInfantryHudState()
	self:SetCurrentState( UIStateInfantryHud )
end

function UIStateManager:SetKillCamState()
	self:SetCurrentState( UIStateKillCam )
end

function UIStateManager:SetEscapeMenuState( page, selectedIndex )
	local currentState = self.currentState
	
	--do not allow the escape menu to pop up if we are in any of these states
	if currentState == UIStateZoneLoading or
	   currentState == UIStateInGameBrowser or
	   currentState == UIStateFirstTimeIntro or
	   currentState == UIStateCharacterSelect then
		return
	end
	
	self:SetCurrentState( UIStateEscapeMenu, page, selectedIndex )
end

function UIStateManager:SetCharacterSelectState()
	self:SetCurrentState( UIStateCharacterSelect )
end

function UIStateManager:SetMapState()
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_MAP )
end

function UIStateManager:SetSquadPageState()
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_SOCIAL, 0 )
end

function UIStateManager:SetFriendPageState()
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_SOCIAL, 2 )
end

function UIStateManager:SetOutfitPageState()
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_SOCIAL, 1 )
end

function UIStateManager:SetNotificationsPageState()
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_SOCIAL, 4 )
end

function UIStateManager:SetInGameBrowserState( ... )
	self:SetCurrentState( UIStateInGameBrowser, ... )
end

function UIStateManager:SetVehicleTerminalState()
	VehicleLoadoutHandler.curMode = VehicleLoadoutHandler.MODE_TERMINAL
	NavigationMenuHandler.isTerminalMode = true
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_VEHICLE_LOADOUT )
end

function UIStateManager:SetPlayerEquipmentTerminalState()
	CharacterLoadoutHandler.curMode = CharacterLoadoutHandler.MODE_TERMINAL
	NavigationMenuHandler.isTerminalMode = true
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_CLASS_LOADOUT )
end

function UIStateManager:SetWarpgateTerminalState()
	NavigationMenuHandler.isTerminalMode = false
	self:SetEscapeMenuState( NavigationMenuHandler.PAGE_WARPGATE )
end

function UIStateManager:SetZoneLoadingState()
	self:SetCurrentState( UIStateZoneLoading )
end

function UIStateManager:SetSpawnSelectionState()
	if self.currentState ~= UIStateEscapeMenu then
		self:SetEscapeMenuState( NavigationMenuHandler.PAGE_MAP )
	end
	
	if SoundHandler:GetIsMusicInCombatMode() == false then
		SoundHandler:StopMusic()
	end
	SoundHandler:PlayMusic( 'MX_Deployment_LP' )
	SoundHandler:TriggerMenuStateAudioMixer( true )
	
	NavigationMenuHandler:SetShortcutButton( 'MAP', 1, NavigationMenuHandler.PAGE_MAP )
	NavigationMenuHandler.isRespawnMode = true
end

--******* NO UI *************************************
UIStateNull = inheritsFrom( UIStateBase )
UIStateNull.name = 'Null State'

function UIStateNull:OnEnterState( lastState )
end

function UIStateNull:OnExitState( nextState )

end

--******* KILL CAM *******************************
UIStateKillCam = inheritsFrom( UIStateBase )
UIStateKillCam.name = 'Kill Cam State'

function UIStateKillCam:OnEnterState( lastState )
	KillCamHandler:Show()
	SoundHandler:TriggerMenuStateAudioMixer( true )
	SoundHandler:LockMusic( true )
end

function UIStateKillCam:OnExitState( nextState )
	KillCamHandler:Hide()
	SoundHandler:LockMusic( false )
end

--******* ESCAPE MENU *******************************
UIStateEscapeMenu = inheritsFrom( UIStateBase )
UIStateEscapeMenu.name = 'Escape Menu State'

function UIStateEscapeMenu:OnEnterState( lastState, ... )
	NotificationHandler:PauseAll()
	NavigationMenuHandler:Show( ... )
	SoundHandler:TriggerMenuStateAudioMixer( true )
end

function UIStateEscapeMenu:OnExitState( nextState )
	NavigationMenuHandler:Hide()
end

--******* INFANTRY HUD *******************************
UIStateInfantryHud = inheritsFrom( UIStateBase )
UIStateInfantryHud.name = 'Infantry State'

function UIStateInfantryHud:OnEnterState( lastState )
	
	if GameSettings.GetDrawHUD() ~= "0" then
		HudHandler:Show()
		ChatHandler:ValidateActiveChannelGroups()
		NotificationHandler:ResumeAll()
	end
	
	if lastState == UIStateZoneLoading then
		SoundHandler:StopMusic()
		if SoundHandler:GetIsMusicInCombatMode() == false then
			SoundHandler:PlaySpawnMusic( 250 ) --We want this to delay 250 milliseconds because we don't want music to play if we're going into a drop pod.
		end
	end
	
	SoundHandler:TriggerMenuStateAudioMixer( false )
	
end

function UIStateInfantryHud:OnExitState( nextState )
	HudHandler:Hide()
end

--******* FIRST TIME INTRO *******************************

UIStateFirstTimeIntro = inheritsFrom( UIStateBase )
UIStateFirstTimeIntro.name = 'First Time Intro'

function UIStateFirstTimeIntro:OnEnterState( lastState )
	FirstTimeIntroHandler:Show()
	NotificationHandler:Show()
	NotificationHandler:ClearAllQueues()
	NotificationHandler:PauseAll()
	SoundHandler:TriggerMenuStateAudioMixer( false )
end

function UIStateFirstTimeIntro:OnResetState( currentState)
	FirstTimeIntroHandler:OnReset()
end

function UIStateFirstTimeIntro:OnExitState( nextState )
	FirstTimeIntroHandler:Hide()
end

--******* INGAME BROWSER *******************************
UIStateInGameBrowser = inheritsFrom( UIStateBase )
UIStateInGameBrowser.name = 'InGame Browser State'

function UIStateInGameBrowser:OnEnterState( lastState, ... )
	InGameBrowserHandler:Show( ... )
	--Ui.ShowCursor()
	SoundHandler:TriggerMenuStateAudioMixer( true )
end

function UIStateInGameBrowser:OnExitState( nextState )
	NotificationHandler:Show()
	InGameBrowserHandler:Hide()
end

--******* CHARACTER SELECT/CREATE **************************
UIStateCharacterSelect = inheritsFrom( UIStateBase )
UIStateCharacterSelect.name = 'Character Select/Create State'

function UIStateCharacterSelect:OnEnterState( lastState )
	CharacterSelectHandler:Show()
	NotificationHandler:Show()
	NotificationHandler:ClearAllQueues()
	NotificationHandler:PauseAll()
end

function UIStateCharacterSelect:OnResetState( currentState)
	CharacterSelectHandler:OnReset()
end

function UIStateCharacterSelect:OnExitState( nextState )
	CharacterSelectHandler:Hide()
end

--******* ZONE LOADING **************************
UIStateZoneLoading = inheritsFrom( UIStateBase )
UIStateZoneLoading.name = 'Loading State'

function UIStateZoneLoading:OnEnterState( lastState )
	LoadingScreenHandler:Show()
	SoundHandler:TriggerMenuStateAudioMixer( true )
end

function UIStateZoneLoading:OnExitState( nextState )
	if nextState ~=  UIStateCharacterSelect then
		LoadingScreenHandler:Hide()
	end
	if nextState == UIStateInfantryHud and SoundHandler:GetIsMusicInCombatMode() == false then
		SoundHandler:StopMusic()
	end
end
