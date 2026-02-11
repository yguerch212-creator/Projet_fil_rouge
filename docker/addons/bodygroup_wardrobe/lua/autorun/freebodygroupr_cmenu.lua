hook.Add( "Initialize", "Freebodygroupr ConVar", function()
    CreateConVar( "sv_st_freebodygroupr_remote", "1", { FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_NOTIFY }, "Should the Bodygroups window be accessible via the context menu and console command?", 0, 1 )
end )

list.Set( "DesktopWindows", "Free Bodygroupr Icon", {
    title = "Bodygroups",
    icon = "free_bodygroupr/wardrobe64.png",
    init = function( icon, window )
        if GetConVar( "sv_st_freebodygroupr_remote" ):GetBool() then
            RunConsoleCommand( "bodygroupwardrobe" )
        else
            surface.PlaySound( "buttons/lightswitch2.wav" )
            notification.AddLegacy( "Remote access has been disabled on this server.  Please use a wardrobe.", NOTIFY_ERROR, 4 )
        end
    end
} )