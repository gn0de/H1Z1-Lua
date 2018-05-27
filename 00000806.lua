-----------------------------------------------------------------------
--
--    File:      Admin.lua
--    Purpose:   Admin client Lua code
--
-----------------------------------------------------------------------

-- console
Client.EnableDebugConsole = true
BindCommandToLua( "console_show", "ConsoleWrapper:Show" )
BindCommandToLua( "console_hide", "ConsoleWrapper:Hide" )
BindCommandToLua( "console_dump", "ConsoleWrapper:DumpConsoleHistory" )
BindCommandToLua( "console_clear", "ConsoleWrapper:ClearConsoleHistory" )
BindCommandToLua( "console_unfocus", "ConsoleWrapper:ClearConsoleFocus" )
BindCommandToLua( "console_sethistory", "ConsoleWrapper:SetConsoleHistory" )
BindCommandToLua( "console_locked", "ConsoleWrapper:PrintIsConsoleLocked" )
BindCommandToLua( "console_lock", "ConsoleWrapper:LockConsole" )
BindCommandToLua( "console_unlock", "ConsoleWrapper:UnlockConsole" )
BindCommandToLua( "console_log_filename", "ConsoleWrapper:SetLogFileName" )
BindCommandToLua( "console_log_clear", "ConsoleWrapper:SetLogFileName" )
BindCommandToLua( "console_log_open", "ConsoleWrapper:SetLogFileName" )
BindCommandToLua( "console_log_islogging", "ConsoleWrapper:PrintIsConsoleLogging" )
BindCommandToLua( "console_log_on", "ConsoleWrapper:ConsoleLoggingOn" )
BindCommandToLua( "console_log_off", "ConsoleWrapper:ConsoleLoggingOff" )

-- gfc/gfx debug
BindCommandToLua( "debugfocus", "Debug.ShowFocus" )
BindCommandToLua( "debugswfinfo", "Ui.PrintSwfFrameInfo" )

--debug bindings
BindCommandToLua( "dofile","dofileInternalOnlyCommand" )
BindCommandToLua( "dumpds", "DumpDs" )
BindCommandToLua( "listds", "ListDs" )
--BindCommandToLua( "god", "Ui.ProcessChatCommand('/gm invuln toggle')" )
--BindCommandToLua( "godoff", "Ui.ProcessChatCommand('/gm invuln off')" )

--theme
BindCommandToLua( "theme", "Ui.SetTheme" )

--ui
BindCommandToLua( "ironsightuidebug", "HudHandler:SetIronSightTestOverlayVisibility" )
BindCommandToLua( "showmaphexcoordinates", "MapHandler:ShowHexCoordinates" )
BindCommandToLua( "showmaphexkillscore", "MapHandler:ShowHexKillScore" )
BindCommandToLua( "showmapregionlabels", "MapHandler:ShowRegionLabels" )
BindCommandToLua( "adminrespawnmode", "RespawnHandler:SetAdminRespawnMode" )
BindCommandToLua( "equipterminal", "UIStateManager:SetPlayerEquipmentTerminalState" )
--BindCommandToLua( "vehicleterminal", "UIStateManager:SetVehicleTerminalState" ) --This doesn't work right.

Sky = {
    IsDay = 1
}

function Sky:SetDay()
    Ui.ProcessChatCommand('/sky file sky_sunset.xml')
end

function Sky:SetNight()
    Ui.ProcessChatCommand('/sky file sky_coruscant_bbe.xml')
end
