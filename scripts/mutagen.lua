local oldInit = init
local oldUpdate = update
local oldUninit = uninit -- Doesn't exist

function init()
	oldInit()
	world.logInfo( "mutagen.lua::init : Setup = %f, Version = %f", status.statusProperty( "mutagenSetup" ), status.statusProperty( "mutagenVersion" ) )
	script.setUpdateDelta(600) -- slow down the needless updating. Don't seem to be able to force a stop.
	
	
end

function update(dt)
	oldUpdate(dt)
	--world.logInfo( "mutagen.lua::update(dt) : entrance : Setup = %f", status.resource( "mutagenSetup" ) )
	if status.statusProperty( "mutagenSetup" ) == 0 then
		status.setStatusProperty( "mutagenSetup", 1) -- in reservation of possible other uses, set to 1 for now
		status.addPersistentEffect( "mutagen", "mutagenRPG" )
	end
	
	--world.logInfo( "mutagen.lua::update(dt) : exit : Setup = %f", status.statusProperty( "mutagenSetup" ) )
end

function uninit()
	if oldUninit ~= nil then
		oldUninit()
	end
	--world.logInfo( "mutagen.lua::uninit : mutagenSetup = %f", status.statusProperty( "mutagenSetup" ) )
	--status.setStatusProperty( "mutagenSetup", 3)
end
