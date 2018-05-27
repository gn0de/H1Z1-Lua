--************************************************************
--*** global.lua - holds helper utility methods
--************************************************************

--general utils
Utils = {}
Utils.intervals = {}
Utils.intervalId = 0
Utils.numActiveIntervals = 0

function Utils:SetInterval( interval, repeatCount, func, scope, ... )
	local id = self.intervalId + 1
	local hash = self.intervals
	
	self.numActiveIntervals = self.numActiveIntervals + 1
	
	hash[ id ] = { func = func, 
				   scope = scope, 
				   args = arg, 
				   lastUpdateTime = os.clock(), 
				   interval = interval, 
				   repeatCount = repeatCount, 
				   executeCount = 0, 
				   complete = false,
				   flagForRemoval = false
				 }
	
	self.intervalId = id
	
	self:ValidateIntervalUpdateList()
	
	return id
end

function Utils:SetTimeout( timeout, func, scope, ... )
	return self:SetInterval( timeout, 1, func, scope, ... )
end

function Utils:ValidateIntervalUpdateList()
	if self.numActiveIntervals > 0 then
		UpdateList[ 'UtilsIntervalTimerProcessing' ] = self
	else
		UpdateList[ 'UtilsIntervalTimerProcessing' ] = nil
	end
end

function Utils:ClearInterval( intervalId )
	local intervalObj = self.intervals[ intervalId ]
	
	if intervalObj then
		intervalObj[ 'flagForRemoval' ] = true
	end
end

function Utils:ClearTimeout( timeoutId )
	self:ClearInterval( timeoutId )
end

--internal use only
function Utils:RemoveInterval( intervalId )
	if self.intervals[ intervalId ] then
		self.numActiveIntervals = self.numActiveIntervals - 1
		self.intervals[ intervalId ] = nil
		self:ValidateIntervalUpdateList()
	end
end

function Utils:RemoveFlaggedIntervals()
	local k
	local obj
	local hash = self.intervals
	local keysToRemove = {}
	
	for k, obj in pairs( hash ) do
		if obj and obj[ 'flagForRemoval' ] then
			table.insert( keysToRemove, k )
		end
	end
	
	for k in pairs( keysToRemove ) do
		self:RemoveInterval( keysToRemove[ k ] )
	end
end

function Utils:Update()
	self:ProcessIntervalTimers()
end

function Utils:ProcessIntervalTimers()
	local k
	local obj
	local curTime = os.clock()
	local hash = self.intervals
	
	--remove intervals flagged for removal
	self:RemoveFlaggedIntervals()
	
	--iterate through the intervals
	for k,obj in pairs( hash ) do
		local lastUpdateTime = obj[ 'lastUpdateTime' ]
		if curTime - lastUpdateTime >= obj[ 'interval' ]  then
			--execute method
			local func = obj[ 'func' ]
			local scope = obj[ 'scope' ]
			
			if scope then
				func( scope, unpack( obj[ 'args' ] ) )
			else
				func( unpack( obj[ 'args' ] ) )
			end
			
			--post processing
			local repeatCount = obj[ 'repeatCount' ]
			local executeCount = obj[ 'executeCount' ] + 1
			
			obj[ 'executeCount' ] = executeCount
			obj[ 'lastUpdateTime' ] = curTime
			
			--remove if repeat condition has been met
			if repeatCount > 0 and executeCount >= repeatCount then
				self:ClearInterval( k )
			end
		end
	end
end

--table utils
TableUtils = {}

function TableUtils:Join( list, delimiter, listProperty )
  if not delimiter then
	delimiter = ','
  end
  
  local len = #list
  if len == 0 then 
    return "" 
  end
  
  local str = ''
  
  for i = 1, len do 
	local val = list[ i ]
	
	if listProperty ~= nil then
		val = val[ listProperty ]
	end
	
	str = str .. tostring( val )
	
	if i < len then
		str = str .. tostring( delimiter )
	end
  end
  
  return str
end

function TableUtils:Slice( list, i1, i2 )
	local res = {}
	local n = #list
	-- default values for range
	i1 = i1 or 1
	i2 = i2 or n
	if i2 < 0 then
		i2 = n + i2 + 1
	elseif i2 > n then
		i2 = n
	end
	
	if i1 < 1 or i1 > n then
		return {}
	end
	
	local k = 1
	for i = i1,i2 do
		res[k] = list[i]
		k = k + 1
	end
	
	return res
end

--string utils
StringUtils = {}

--@Desc: this method finds all occurrences of %0, %1, ...etc in str and replaces each find with 
--		 the values specified in replaceParams parameter and returns the resulting string
function StringUtils:ReplaceInString( str, replaceParams )
	local i
	for i=1,#replaceParams do
		str = string.gsub( str, '%%' .. tostring( i-1 ), replaceParams[ i ] )
	end
	return str
end

function StringUtils:Split(str, delim, maxNb)
    -- Eliminate bad cases...
    if string.find(str, delim) == nil then
        return { str }
    end
    if maxNb == nil or maxNb < 1 then
        maxNb = 0    -- No limit
    end
    local result = {}
    local pat = "(.-)" .. delim .. "()"
    local nb = 0
    local lastPos
    for part, pos in string.gfind(str, pat) do
        nb = nb + 1
        result[nb] = part
        lastPos = pos
        if nb == maxNb then break end
    end
    -- Handle the last field
    if nb ~= maxNb then
        result[nb + 1] = string.sub(str, lastPos)
    end
    return result
end

--timer utils

--TimerGroup maintains a group of timers and ensures there is only 1 running at any given time
TimerGroup =
{
	TIMER_EVENT = 'OnTimerEvent',
	ACTIVE_TIMER_CHANGE = 'OnActiveTimerChange',
	
	id = nil,
	timers = {},
	activeTimer = nil,
	
	Create = function( id )
		local timerGroup = {}
		setmetatable( timerGroup, { __index = TimerGroup } )
		timerGroup.id = id
		return timerGroup
	end,
	
	Add = function( self, timer )
		self.timers[ timer.id ] = timer
		LUABroadcaster:addListener( timer, Timer.EVENT_TIMER_START, 'HandleTimerStart', self )
		LUABroadcaster:addListener( timer, Timer.EVENT_TIMER_STOP, 'HandleTimerStop', self )
		LUABroadcaster:addListener( timer, Timer.EVENT_TIMER_CANCEL, 'HandleTimerCancel', self )
		LUABroadcaster:addListener( timer, Timer.EVENT_TIMER_UPDATE, 'HandleTimerUpdate', self )
		LUABroadcaster:addListener( timer, Timer.EVENT_TIMER_COMPLETE, 'HandleTimerComplete', self )
	end,
	
	Remove = function( self, timer )
		LUABroadcaster:removeListener( timer, Timer.EVENT_TIMER_START, 'HandleTimerStart', self )
		LUABroadcaster:removeListener( timer, Timer.EVENT_TIMER_STOP, 'HandleTimerStop', self )
		LUABroadcaster:removeListener( timer, Timer.EVENT_TIMER_CANCEL, 'HandleTimerCancel', self )
		LUABroadcaster:removeListener( timer, Timer.EVENT_TIMER_UPDATE, 'HandleTimerUpdate', self )
		LUABroadcaster:removeListener( timer, Timer.EVENT_TIMER_COMPLETE, 'HandleTimerComplete', self )
		
		self.timers[ timer.id ] = nil
	end,
	
	GetActiveTimer = function( self )
		return self.activeTimer
	end,
	
	SetActiveTimer = function( self, timer )
		local hasChanged = timer ~= self.activeTimer
		self.activeTimer = timer
		
		if hasChanged then
			LUABroadcaster:dispatchEvent( self, self.ACTIVE_TIMER_CHANGE, self.activeTimer )
		end
	end,
	
	HandleTimerStart = function( self, timer )
		if not timer then
			return
		end
		
		if self.activeTimer and timer ~= self.activeTimer then
			self.activeTimer:Stop()
		end
		
		self:SetActiveTimer( timer )
		self:DispatchEvent( Timer.EVENT_TIMER_START, timer )
	end,
	
	HasRunningTimer = function( self )
		local k
		local v
		local hasRunningTimer = false
		
		for k,v in pairs( self.timers ) do
			if v and v:IsRunning() then
				hasRunningTimer = true
			end
		end
		
		return hasRunningTimer
	end,
	
	StopActiveTimer = function( self )
		if self.activeTimer and self.activeTimer:IsRunning() then
			self.activeTimer:Stop()
		end
	end,
	
	HandleTimerStop = function( self, timer ) 
		if not self:HasRunningTimer() then
			self:SetActiveTimer( nil )
		end
		
		self:DispatchEvent( Timer.EVENT_TIMER_STOP, timer ) 
	end,
	
	HandleTimerUpdate = function( self, timer ) self:DispatchEvent( Timer.EVENT_TIMER_UPDATE, timer ) end,
	HandleTimerComplete = function( self, timer ) self:DispatchEvent( Timer.EVENT_TIMER_COMPLETE, timer ) end,
	HandleTimerCancel = function( self, timer ) self:DispatchEvent( Timer.EVENT_TIMER_CANCEL, timer ) end,
	
	DispatchEvent = function( self, event, timer )
		LUABroadcaster:dispatchEvent( self, self.TIMER_EVENT, event, timer )
	end
}

Timer =
{
	EVENT_TIMER_START = 'OnTimerStart',
	EVENT_TIMER_COMPLETE = 'OnTimerComplete',
	EVENT_TIMER_UPDATE = 'OnTimerUpdate',
	EVENT_TIMER_STOP = 'OnTimerStop',
	EVENT_TIMER_CANCEL = 'OnTimerCancel',
	
	DEBUG = false,
	
	id = nil,
	duration = 0,
	startTime = nil,
	lastTickTime = nil,
	tickSoundId = nil,
	tickSoundInterval = 1000,
	lastUpdateTime = nil,
	updateInterval = 250,
	
	Create = function( id )
		local timer = {}
		setmetatable( timer, { __index = Timer } )
		timer.id = id
		return timer
	end,
	
	Start = function( self, params )
		if self:IsRunning() then
			self:Stop()
		end
		
		if params.duration then
			self.duration = params.duration
		else
			return
		end
		
		if params.updateInterval then
			self.updateInterval = params.updateInterval
		end
		
		if params.tickSoundId then
			self.tickSoundId = params.tickSoundId
			
			if params.tickSoundInterval then
				self.tickSoundInterval = params.tickSoundInterval
			end
			
			self.lastTickTime = os.clock()
		end
		
		self.startTime = os.clock()
		self:OnTimerStart()
		self:OnTimerUpdate( true )
		UpdateList[ self.id ] = self
	end,
	
	Stop = function( self, isComplete )
		if not self:IsRunning() then
			return
		end
		
		--cleanup
		self.startTime = nil
		self.lastTickTime = nil
		self.lastUpdateTime = nil
		UpdateList[ self.id ] = nil
		
		self:OnTimerUpdate( true )
		self:OnTimerStop()
			
		if isComplete then
			self:OnTimerComplete()
		else
			self:OnTimerCancel()
		end
	end,
	
	IsRunning = function( self )
		return self.startTime ~= nil
	end,
	
	--timeleft in sec
	TimeLeft = function( self )
		if self:IsRunning() then
			return self.duration - ( os.clock() - self.startTime )
		end
		
		return 0
	end,
	
	ProgressPercent = function( self )
		if self:IsRunning() then
			return ( self.duration - self:TimeLeft() ) / self.duration * 100
		end
		
		return 0
	end,
	
	HasTickSound = function( self )
		return self.tickSoundId ~= nil and self.tickSoundInterval ~= nil
	end,
	
	PlayTickSound = function( self )
		if self:HasTickSound() then
			SoundHandler:PlaySoundById( self.tickSoundId )
		end
	end,
	
	--executes every frame when running
	Update = function( self )
		if self:IsRunning() and self:TimeLeft() <= 0 then
			self:Stop( true )
		else
			--if we have a tick sound, play it at the given interval
			if self:HasTickSound() then
				local curTime = os.clock()
				if ( curTime - self.lastTickTime ) >= self.tickSoundInterval then
					self:PlayTickSound()
					self.lastTickTime = curTime
				end
			end
		
			self:OnTimerUpdate()
		end
	end,
	
	ToString = function( self )
		return '[TIMER ' .. tostring( self.id ) ..']'
	end,
	
	--************************************
	--Timer Event Dispatchers
	--************************************
	--executes when timer starts
	OnTimerStart = function( self )
		LUABroadcaster:dispatchEvent( self, self.EVENT_TIMER_START, self )
		
		if self.DEBUG then
			print( self:ToString() .. ' Start' )
		end
	end,
	
	--executes when timer stops
	OnTimerStop = function( self )
		LUABroadcaster:dispatchEvent( self, self.EVENT_TIMER_STOP, self )
		
		if self.DEBUG then
			print( self:ToString() .. ' Stop' )
		end
	end,
	
	OnTimerCancel = function( self )
		LUABroadcaster:dispatchEvent( self, self.EVENT_TIMER_CANCEL, self )
		
		if self.DEBUG then
			print( self:ToString() .. ' Cancel' )
		end
	end,
	
	--executes when timer successfully completes
	OnTimerComplete = function( self )
		LUABroadcaster:dispatchEvent( self, self.EVENT_TIMER_COMPLETE, self )
		
		if self.DEBUG then
			print( self:ToString() .. ' Complete' )
		end
	end,
	
	--executes on each timer tick and when start/stop methods execute
	OnTimerUpdate = function( self, force )
		local curTime = os.clock()
		if force or not self.lastUpdateTime or ( curTime - self.lastUpdateTime ) >= self.updateInterval then
			LUABroadcaster:dispatchEvent( self, self.EVENT_TIMER_UPDATE, self )
			self.lastUpdateTime = curTime
			
			if self.DEBUG then
				print( self:ToString() .. ' Update, TimeLeft: ' .. tostring( self:TimeLeft() ) )
			end
		end
	end
}