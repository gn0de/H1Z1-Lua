-- a message dialog box
--   to use:
--       AppMsgBox:Message("Here's the message")
--            or
--       AppMsgBox:Message("Here's the message",OptionalOnOkButtonEvent)

AppMsgBox = {
	UserOk = nil,
	WindowName = "Main.wndMessage",
	LabelName = "Main.wndMessage.lblLabel",
	stateBlock = false,
	Ok = function( self )
		local W = Window.Find(self.WindowName)
		if (W ~= nil) then
			SetModalResult(true)
			W:Hide()
			if self.stateBlock then
				self.stateBlock = false
				GfxCtrl.DisableStateBlock()
			end
	    end
		if (self.UserOk ~= nil) then
			self.UserOk()
		end
	end,
	Display = function( self, t, ParamOkFunction )
		self.UserOk = ParamOkFunction
		local W = Window.Find(self.WindowName)
		
		if (W ~= nil) then
			if self.stateBlock==false then
				self.stateBlock = true
				GfxCtrl.EnableStateBlock()
			end
			local L = LabelControl.find(self.LabelName)
			if (L~=nil) then
				L:setText(t)
			end
			W:Center()
			W:ShowModal()
		end
	end
}

Main_wndMessage_btnOk_OnClick = function()
	AppMsgBox:Ok()
end

