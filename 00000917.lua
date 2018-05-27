--Broadcaster table for all global events
UiEventDispatcher = {}

--Code calls HUD:onResize when the Client resizes
HUD = {}
function HUD:onResize()
	LUABroadcaster:dispatchEvent( UiEventDispatcher, ClientEvents.CLIENT_RESIZE )
end

UiZLayers = {
	MINIGAME = 105,
	VEHICLE_HUD = 109, 
	RETICLE = 110,
	HUD = 112,
	WINDOW = 114,
	CLICK_GOBBLER = 118,
	NAVIGATION_WINDOW_BG = 119,
	MODAL_WINDOW = 140,
	NAVIGATION_WINDOW = 150,
	CONTEXT_MENU = 160,
	TUTORIAL_WINDOW = 161,
	HELP_WINDOW = 162,
	QUIZ_WINDOW = 163,
	BUNDLE_PURCHASE_WINDOW = 165,
	REPORT_PLAYER_WINDOW = 166,
	STATION_CASH_PURCHASE_WINDOW = 167,
	INGAME_BROWSER = 168,
	SERVER_QUEUE_WINDOW = 169,
	TOOLTIP = 170,
	TUTORIAL = 172,
	NOTIFICATION = 175,
	TAB_SCREEN = 178,
	TOOL = 180,
	LOADING_SCREEN = 190
}

UiHandlerBase = {
	swfName = "default",
	wndName = "default",
	swfNameToHandlerHash = {},
	swfFile = "",
	isShown = false,
	tableName = nil,
	unloadOnHide = true,
	isDebugOn = false,
	hitTestMethod = Constants.HitTestTypes.BUTTON_EVENTS,
	ZLayer = UiZLayers.WINDOW,
	panelSoundsEnabled = false,
	isAS3 = false,
	isModal = false,
	loadOnInit = false,
	isInteractive = true, --deprecated (sjames)
	pushToContext = false,
	clearContextOnShow = false,
	lockContextOnShow = false,
	enableLogging = false, --for logging show/hide to wall of data
	
	--@NOTE: this needs to be set to false by default at some point 
	--		 when we are sure it won't break the UI ( Amit - 06/26/2012 )
	allowInvokesWhenHidden = true,
	
	events = 
	{ 
		VISIBILITY_UPDATE = 'OnVisibilityUpdate' 
    },

    mouseEnabled = true,
    keyboardEnabled = true,
	keyboardCaptured = false,
    keyboardKeys = {}
}

--@desc: generates a new table with an associated metatable ( baseClass )
function inheritsFrom( baseClass )

	local new_class = {}
	local class_mt = { __index = new_class }

	function new_class:create()
		local newinst = {}
		setmetatable( newinst, class_mt )
		return newinst
	end

	if nil ~= baseClass then
		setmetatable( new_class, { __index = baseClass } )
	end

	-- Return the class object of the instance
	function new_class:class()
		return new_class
	end

	-- Return the super class object of the instance
	function new_class:superClass()
		return baseClass
	end

	-- Return true if the caller is an instance of theClass
	function new_class:instanceof( theClass )
		local b_isa = false

		local cur_class = new_class

		while ( nil ~= cur_class ) and ( false == b_isa ) do
			if cur_class == theClass then
				b_isa = true
			else
				cur_class = cur_class:superClass()
			end
		end

		return b_isa
	end
	
	LUABroadcaster:addListener( UiEventDispatcher, ClientEvents.CLIENT_RESIZE, 'OnResize', new_class )
	LUABroadcaster:addListener( UiEventDispatcher, ClientEvents.CLIENT_INIT, 'OnInit', new_class )
	LUABroadcaster:addListener( GameEvents, GameEvents.EVENT_WORLD_READY_COMPLETE, 'OnClientLoadComplete', new_class )

	return new_class
end

--@Desc: assign a window and swf to the table
function UiHandlerBase:SetUiProperties( wndName, swfName, swfFile, tableName, zLayer, ps4SwfFile )

	-- ps4SwfName is for skinned UI Components.  Eventually we should port all of these components over and deprecate this field
	if ps4SwfFile == nil then
		ps4SwfFile = swfFile
	end

    --TODO: Move this to a separate function.
    Window.Create(wndName, swfName, swfFile, tableName, ps4SwfFile)
    self.wndName = wndName
    self.swfName = wndName..'.'..swfName
    self.swfFile = swfFile
	self.ps4SwfFile = ps4SwfFile
    self.tableName = tableName
    self.swfNameToHandlerHash[ self.swfName ] = self

    local diffSwfName = string.gsub(self.swfName, '%p', '_')

    if self.OnUserEvent then
        _G[ diffSwfName..'_OnUserEvent' ] = function(a, ...) self:OnUserEvent(a, ...) end
    end
    
    if self.OnSwfFocus then
        _G[ diffSwfName..'_OnFocus' ] = function(isFocused) self:OnSwfFocus(isFocused) end
    end
    
   if( zLayer )then
       self.ZLayer = zLayer
       
       local wnd = self:getWindow()
       if wnd then
           wnd:SetProperty( 'ZLayer', zLayer )
       end
   end

   self:SetKeyboardEnabled( self.keyboardEnabled )
   self:SetKeyboardCaptured( self.keyboardCaptured )
   self:SetMouseEnabled( self.mouseEnabled )
   self:SetDesiredKeys( unpack( self.keyboardKeys ) )
end

---
-- @param value (boolean) - enable or disable keyboard input
function UiHandlerBase:SetKeyboardEnabled( value )
    self.keyboardEnabled = value

    local window = self:getWindow()
    if ( window ) then
        window:SetKeyboardEnabled( value )
    end
end

---
-- @param value (boolean) - enable or disable keyboard input for the entire keyboard
function UiHandlerBase:SetKeyboardCaptured( value )
    self.keyboardCaptured = value

    local window = self:getWindow()
    if ( window ) then
        window:SetKeyboardCaptured( value )
    end
end



---
-- @param value (boolean) - enable or disable mouse input
function UiHandlerBase:SetMouseEnabled( value )
    self.mouseEnabled = value

    local window = self:getWindow()
    if ( window ) then
        window:SetMouseEnabled( value )
    end
end

---
-- @param ... var arg list of Key Codes
function UiHandlerBase:SetDesiredKeys( ... )
    self.keyboardKeys = { ... }

    local window = self:getWindow()
    if ( window ) then
        window:SetDesiredKeys( ... )
    end
end

function UiHandlerBase:GetHandlerBySwfName( swfName )
	return self.swfNameToHandlerHash[ swfName ]
end

function UiHandlerBase:Show()

	-- print(debug.traceback())

	if self.isShown then
		return
	end
	
	self.isShown = true
	
	local wnd = self:getWindow()
	
	if( wnd )then
		wnd:SetProperty( 'ZLayer', self.ZLayer )
		
		-- PS2 MERGE
		--local isInteractive = '0'
		
		--if self.isInteractive then
		--	isInteractive = '1'
		--end
		
		--wnd:SetProperty( 'IsInteractive', isInteractive )
		
		if self.clearContextOnShow then
			Context:Clear()
		end
		
		if self.lockContextOnShow then
			Context:Lock( self.tableName )
		end
		
		--push hide function onto the context stack
		if self.pushToContext then
			Context:Push( self, self.OnContextPop, self.tableName )
		end
		
		if self.isModal then
			wnd:ShowModal()
		else
			wnd:Show()
		end
		
		wnd:SetHitTestType( self.hitTestMethod )
		
		self:ASInvoke( 'setWindowData', self.tableName )
		self:ASInvoke( 'onSwfShow' )
		self:OnResize()
		
		if( self.panelSoundsEnabled )then
			SoundHandler:PlaySoundById( SoundHandler.sounds.UI_Pane_Open, 1 );
		end
		
		LUABroadcaster:dispatchEvent( self, self.events.VISIBILITY_UPDATE, true )
	end
	
	if self.enableLogging then
		self:LogShow()
	end
	
end

function UiHandlerBase:OnContextPop()
	self:Hide()
end

function UiHandlerBase:LogShow()
	if self.tableName then
		Ui.SetWallOfData( self.tableName, 'show' )
	end
end

function UiHandlerBase:Hide()

	if not self.isShown then
		return
	end
	
	self:ASInvoke( 'onSwfHide' )
	
	self.isShown = false

	local wnd = self:getWindow()
	if( wnd )then
		local close = self.unloadOnHide
		
		if close then
			wnd:Close()
		else
			wnd:Hide()
		end
		
		if( self.panelSoundsEnabled )then
			SoundHandler:PlaySoundById( SoundHandler.sounds.UI_Pane_Close, 1 )
		end
		
		LUABroadcaster:dispatchEvent( self, self.events.VISIBILITY_UPDATE, false )
	end
	
	if self.enableLogging then
		self:LogHide()
	end

	
end

function UiHandlerBase:Exit( force )
	if force then
		Context:Unlock( self.tableName )
	end
	
	Context:ExecuteAndPop( force, self.tableName )
end

function UiHandlerBase:LogHide()
	if self.tableName then
		Ui.SetWallOfData( self.tableName, 'hide' )
	end
end

--@Desc: used to invoke a method on the associated swf
function UiHandlerBase:ASInvoke( func, ... )
	if not func or ( not self.allowInvokesWhenHidden and not self.isShown ) then
		return
	end

	local swf = self:getSwf()
	func = tostring( func )
	
	if swf then
		swf:Invoke( func, ... )
	end
end

--@Desc: invoked when the client is initialized
function UiHandlerBase:OnInit()

end

function UiHandlerBase:OnClientLoadComplete()
	LUABroadcaster:removeListener( GameEvents, GameEvents.EVENT_WORLD_READY_COMPLETE, 'OnClientLoadComplete', self )
	
	if self.loadOnInit then
		self:getWindow():LoadMovie()
	end
end

--@Desc: invoked when the client is resized
function UiHandlerBase:OnResize()
	if self.isShown then
		self:ASInvoke( 'swfResize' )
	end
end

function UiHandlerBase:SetFocus()
	if self.isShown then
		local wnd = self:getWindow()
		local swf = self:getSwf()
	
		if wnd and swf then
			wnd:SetFocus()
			swf:SetFocus()
		end
	end
end

function UiHandlerBase:OnSwfFocus( isFocused )
	if self.isShown == true then
		if self.isAS3 then
			self:ASInvoke( 'onSwfFocus', isFocused )
		else
			self:ASInvoke( 'swfFocus', isFocused )
		end
	end
end

--@Desc: captures fscommand events from the swf and routes it to the table
function UiHandlerBase:OnUserEvent(a, ...)
	if self[ a ] then
		( self[ a ] )( self, ... )
	end
end

--@Desc: get the associated window reference
function UiHandlerBase:getWindow()
	return Window.Find( self.wndName )
end

--@Desc: get the associated swf reference
function UiHandlerBase:getSwf()
	return GfxCtrl.Find( self.swfName )
end

function UiHandlerBase:DebugPrint( msg )
	if self.isDebugOn then
		if self.tableName then
			msg = self.tableName .. ' >> ' .. msg
		end
		
		print( msg )
	end
end

function UiHandlerBase:DebugPrintVars( ... )
	if self.isDebugOn then
		local i
		local s = ''
		local len = #arg
		for i=1,len do
			s = s .. tostring( arg[ i ] )
			
			if i < len then
				s = s .. ', '
			end
		end
		
		if self.tableName then
			s = self.tableName .. ' >> ' .. s
		end
		
		print( s )
	end
end

--******* Base Modal Handler **************************
ModalUiHandlerBase = inheritsFrom( UiHandlerBase )
ModalUiHandlerBase.enableLogging = true
ModalUiHandlerBase.isModal = true
ModalUiHandlerBase.pushToContext = true
ModalUiHandlerBase.hitTestMethod = Constants.HitTestTypes.SHAPES_NO_INVIS

--******* Base Marketplace Popup Screen Handler **************************

MarketplacePopupScreen = inheritsFrom( UiHandlerBase )
MarketplacePopupScreen.enableLogging = true
MarketplacePopupScreen.logReferrerId = -1
MarketplacePopupScreen.logReferrerContext = -1
MarketplacePopupScreen.logScreenId = -1
MarketplacePopupScreen.isModal = true

function MarketplacePopupScreen:Show( referrerContext )
	self.logReferrerId = MarketplaceHandler.Referrers.UI
	self.logReferrerContext = referrerContext
	MarketplaceHandler:RegisterUiHandler( self )
	
	UiHandlerBase.Show( self )
end

function MarketplacePopupScreen:Hide()
	MarketplaceHandler:UnregisterUiHandler( self )
	UiHandlerBase.Hide( self )
end

function MarketplacePopupScreen:LogShow()
	self:DebugPrintVars( 'LogShow', self.logScreenId, self.logReferrerId, self.logReferrerContext )
	
	if self.logScreenId > -1 and self.logReferrerId > -1 and self.logReferrerContext > -1 then
		InGamePurchaseStoreScreen.OnScreenOpen( self.logScreenId, self.logReferrerId, self.logReferrerContext )
	end
end

function MarketplacePopupScreen:LogHide()
	self:DebugPrintVars( 'LogHide', self.logScreenId )
	
	if self.logScreenId then
		InGamePurchaseStoreScreen.OnScreenClose( self.logScreenId )
	end	
end

function MarketplacePopupScreen:OnResize()
	MaximizeWin( self )
    UiHandlerBase.OnResize( self )
end

--******* Base Full-Screen Page Handler *********************

FullScreenUiHandlerBase = inheritsFrom( UiHandlerBase )
FullScreenUiHandlerBase.pageTitle = ''
FullScreenUiHandlerBase.pageCategoryItems = {}
FullScreenUiHandlerBase.enableLogging = true
FullScreenUiHandlerBase.tutorial = nil
FullScreenUiHandlerBase.tutorialOption = nil
FullScreenUiHandlerBase.persistLastViewedCategoryIndex = true
FullScreenUiHandlerBase.lastViewedCategoryIndex = nil
FullScreenUiHandlerBase.hitTestMethod = Constants.HitTestTypes.SHAPES_NO_INVIS

function FullScreenUiHandlerBase:Show()	
	UiHandlerBase.Show( self )
	
	self:SetFocus()
end

function FullScreenUiHandlerBase:GetNavigationCategoryItems()
	return self:FilterNavigationCategoryItems( self.pageCategoryItems )
end

function FullScreenUiHandlerBase:FilterNavigationCategoryItems( items )
	local len = #items
	local i
	local res = {}
	
	for i=1,len do
		local item = items[ i ]
		
		if item then
			if self:ValidateNavigationCategoryItem( item ) then
				table.insert( res, item )
			end
		end
	end
	
	return res
end

function FullScreenUiHandlerBase:ValidateNavigationCategoryItem( item )
	return true
end

function FullScreenUiHandlerBase:OnNavigationCategorySelect( index, id, label, iconId )
	self:ASInvoke( 'onNavigationCategorySelect', index, id, label, iconId )
	
	self.lastViewedCategoryIndex = index
	
	if self.enableLogging and self.tableName then
		Ui.SetWallOfData( self.tableName, 'category_select', id )
	end
end

function FullScreenUiHandlerBase:PersistLastViewedCategoryIndex()
	return self.persistLastViewedCategoryIndex
end

function FullScreenUiHandlerBase:GetLastViewedCategoryIndex()
	return self.lastViewedCategoryIndex
end

function FullScreenUiHandlerBase:SetTutorial( id )
	self.tutorial = id
end

--@Desc: maximize the gfc window and the underlying swf
function MaximizeWin( view )
	local wnd = Window.Find( view.wndName )
	local swf = GfxCtrl.Find( view.swfName )
	local sw, sh = Window.GetCanvasSize()

	if (wnd) then
		wnd:SetProperty( "X", 0 )
		wnd:SetProperty( "Y", 0 )
		wnd:SetProperty( "Width", sw )
		wnd:SetProperty( "Height", sh )
	end

	if (swf) then
		swf:SetProperty( "X", 0 )
		swf:SetProperty( "Y", 0 )
		swf:SetProperty( "Width", sw )
		swf:SetProperty( "Height", sh )
	end
end 