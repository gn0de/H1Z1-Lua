
InGameBrowserHandler = inheritsFrom( ModalUiHandlerBase )
InGameBrowserHandler:SetUiProperties(  'Main.wndInGameBrowser', 'swfInGameBrowser', 'UI\\InGameBrowser.swf', 'InGameBrowserHandler', UiZLayers.INGAME_BROWSER )
InGameBrowserHandler.isDebugOn = true
InGameBrowserHandler.isAS3 = true
InGameBrowserHandler.browser = nil
InGameBrowserHandler.clearContextOnShow = false
InGameBrowserHandler.isLoading = false
InGameBrowserHandler.hitTestMethod = Constants.HitTestTypes.BOUNDS

InGameBrowserHandler.MODE_CS_PETITION = 1
InGameBrowserHandler.MODE_MARKETPLACE_TOPUP = 2
InGameBrowserHandler.MODE_MARKETPLACE_SMS = 3
InGameBrowserHandler.MODE_MARKETPLACE_PAYPAL = 4

function InGameBrowserHandler:OnResize()
    --MaximizeWin( self )
    local wnd = Window.Find( self.wndName )
    local swf = GfxCtrl.Find( self.swfName )
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

    self:superClass().OnResize(self)
end

function InGameBrowserHandler:Hide()
    
    
    if self.browser then
        -- Tell code that we're done with the browser view
        -- This happens faster than the garbage collector
        self.browser.Destroy(self.swfName)
    end
    self.browser = nil

    if Browser.OnHide then
        Browser.OnHide(self.swfName)
    end
    
    self:superClass().Hide(self)
end

function InGameBrowserHandler:Show( url )
    if self.browser then
        self.browser:LoadUrl( self.swfName, url )
    else
        self.pendingUrl = url
    end
    
    self:superClass().Show( self )

end

function InGameBrowserHandler:ShowHelpPage()  
    if Ui.OpenSupportUrl then
        Ui.OpenSupportUrl()
    end
end

function InGameBrowserHandler:OnSwfLoadComplete()
    -- Valid options for first param are: 'RemoteWebBrowsing', 'LocalUi', 'SecureCommerce'
    if not self.browser then
        self.browser = Browser.Create( 'SecureCommerce', 'Main.wndInGameBrowser.swfInGameBrowser', 'BrowserRenderTarget', self.wndName, 'www.google.com', 1024, 768 )
        self.browser:EnableRenderOnPageLoad(true) -- Only display on page load
    end

    if self.pendingUrl then
        self.browser.LoadUrl( self.swfName, self.pendingUrl )
        self.pendingUrl = nil
    end

    -- This is temp to just get some initial rendering
    if Browser.OnShow then
        Browser.OnShow( self.swfName )
    end
end

function InGameBrowserHandler:OnMouseEvent(event, localX, localY, modifiers, offset)
    if ( self.browser ) then
        --print("InGameBrowserHandler:OnMouseEvent event:"..event.." modifiers: "..modifiers.."  offset: "..offset)
        self.browser.OnMouseEvent( self.swfName, event , localX, localY, modifiers, offset * 20)
    end
end

function InGameBrowserHandler:OnKeyEvent(event, keyCode, charCode, modifiers)
    --print("InGameBrowserHandler:OnKeyEvent event: "..event..", keyCode: "..keyCode..", charCode: "..charCode..", modifiers: "..modifiers )
    if ( self.browser ) then
        self.browser.OnKeyEvent(self.swfName, event, keyCode, charCode, modifiers)
    end
end

function InGameBrowserHandler:OnFocusEvent(event)
    --print("InGameBrowserHandler:OnFocusEvent event: ")
    if (self.browser) then
        self.browser.OnFocusEvent(self.wndName, event)
    end
end

function InGameBrowserHandler:OnUrlChange( url )
    self:ASInvoke( 'handleBrowserUrlChange', url )
end

function InGameBrowserHandler:OnStateChange( values )
    --print('InGameBrowser OnStateChange (isLoading:'..tostring(values.isLoading)..') (canNavigateBack:'..tostring(values.canNavigateBack)..') (canNavigateForward:'..tostring(values.canNavigateForward)..') (canRefresh:'..tostring(values.canRefresh)..') (loadProgress:'..tostring(values.loadProgress)..')')

    if self.browser and self.isLoading and not values.isLoading then
        self.browser.EnableRenderOnPageLoad( self.swfName, false )
    end
    self.isLoading = values.isLoading

    self:ASInvoke( 'handleBrowserStateChange', values )
end

--AS3 to LUA
function InGameBrowserHandler:NavigateToUrl( url )
    if self.browser then
        self.browser.LoadUrl( self.swfName, url )
    end
end

function InGameBrowserHandler:NavigateToNextPage()
    if self.browser then
        self.browser.Forward(self.swfName)
    end
end

function InGameBrowserHandler:NavigateToPreviousPage()
    if self.browser then
        self.browser.Back(self.swfName)
    end
end

function InGameBrowserHandler:RefreshPage()
    if self.browser then
        self.browser.Refresh(self.swfName)
    end
end

function InGameBrowserHandler:StopPageLoading()
    if self.browser then
        self.browser.Stop(self.swfName)
    end
end

function InGameBrowserHandler:SetRenderSize(width, height)
    if self.browser then
        self.browser.SetRenderSize(self.swfName, width, height)
    end
end

function InGameBrowserHandler:OnShowPopupMenu( data )
    self:ASInvoke( 'handleBrowserShowPopupMenu', data )
end

function InGameBrowserHandler:OnSelectPopupMenuItem( index )
    if self.browser then
        self.browser.DidSelectPopupMenuItem( self.swfName, index )
    end
end

function InGameBrowserHandler:OnCancelPopupMenu()
    if self.browser then
        self.browser.DidCancelPopupMenu(self.swfName)
    end
end