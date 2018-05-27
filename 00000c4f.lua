-- startup.lua
--    gets called when the client starts up.
--    use to define global functions and perform startup tasks

-- GuiOnSave saves the window positions
function GuiOnSave()
    --GuiSaver:Begin()
    --GuiSaver:SaveAppWindowPosition("wndChat")
    --GuiSaver:End()
end

-- GuiOnInit gets called at startup
function GuiOnInit()
    guiInitModule( "Main" )
    clear()
    Startup()
end

function Startup()
	DataSourceEvents:Initialize()
	LUABroadcaster:dispatchEvent( UiEventDispatcher, ClientEvents.CLIENT_INIT )
end

function GuiOnShutdown()
    if (DesignTools_OnShutdown) then
        DesignTools_OnShutdown()
    end
    collectgarbage()
end

-- make dofile prepend the script path (this should ultimately be replaced with more robust dofile registered in C++)
if (systemDoFile==nil) then
    systemDoFile = dofile
    dofileInternalOnlyCommand=function( theFile )
        print("/dofile "..Client.PathScripts .. theFile )
        print("---------------------------------------")
        print("Include new *.lua file in scripts.txt.")
        systemDoFile( Client.PathScripts .. theFile )
    end
end