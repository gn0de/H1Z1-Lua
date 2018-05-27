LUABroadcaster = {

    hashBroadcaster = {},
    
    addListener = function(self, broadcaster, event, funcString, scope)
    
	   if not funcString or not broadcaster then
			print( 'LUABroadcaster ERROR: trying to add nil event listener to ' .. tostring( broadcaster.tableName ) )
			return
	   end
	   
	   broadcaster = tostring(broadcaster)
        
        if(not self.hashBroadcaster[broadcaster]) then
             self.hashBroadcaster[broadcaster] = {}
        end
        
        if(not self.hashBroadcaster[broadcaster][event]) then
             self.hashBroadcaster[broadcaster][event] = {}
        end
        
        self.hashBroadcaster[broadcaster][event][#self.hashBroadcaster[broadcaster][event]+1] = {scope, funcString}
        
    end,
    
    removeListener = function(self, broadcaster, event, funcString, scope)
        --print('removing listener [' ..funcString..'] '..'for event: '..event)
        broadcaster = tostring(broadcaster)
        
        if (not self.hashBroadcaster[broadcaster]) or (not self.hashBroadcaster[broadcaster][event]) then
            return
        end
        
        for k,v in pairs(self.hashBroadcaster[broadcaster][event]) do 
            local a = v[1]
            local b = v[2]
            if (((a and a == scope) or (not a)) and b == funcString ) then
                self.hashBroadcaster[broadcaster][event][k] = nil
            end
        end
    end,
    
    dispatchEvent = function(self, broadcaster, event, ...)
        broadcaster = tostring( broadcaster )
        
        if (not self.hashBroadcaster[broadcaster]) or (not self.hashBroadcaster[broadcaster][event]) then
            return
        end
        
        for k,v in pairs(self.hashBroadcaster[broadcaster][event]) do 
         
            local scope = v[1]
            local funcString = v[2]
                    
            if ( funcString ) then
                --print('executing listener: '..event)
                if scope and scope[ funcString ] then
					scope[ funcString ]( scope, unpack( arg ) )
                elseif _G[ funcString ] then
                    _G[ funcString ]( unpack( arg ) )
                end
            end
        end
       
    end,
    
    dumpListeners = function(self, broadcaster)
        broadcaster = tostring(broadcaster)
        
    	if (not self.hashBroadcaster[broadcaster]) then
		    print('0 listeners')
            return
        end
        
        for k,v in pairs(self.hashBroadcaster[broadcaster]) do
            for k2,v2 in pairs( self.hashBroadcaster[broadcaster][k] ) do
            
				local scope = v2[1]
				local funcString = v2[2]

				if (funcString) then
					print('listener for '..k..': '..funcString)
				end
			end
        end
    	
    
    end

}


--[[TestTable1 = {
    init = function(self)
        LUABroadcaster:addListener(TestTable2, 'update', self.handleUpdate, self)
        LUABroadcaster:addListener(TestTable2, 'update', self.handleUpdate2)
    end,
    
    handleUpdate = function(self, a, b)
        print('caught the update: '..a..', '..b)
    
    end,
    handleUpdate2 = function(a, b)
            print('caught the update again!: '..a..', '..b)
        
    end,
    
    deinit = function(self)
        LUABroadcaster:removeListener(TestTable2, 'update', self.handleUpdate)
    end,
    
    vartest = function(self, ...)
       print(self:sum(unpack(arg)))
    end,
    
    sum = function(self, a, b)
        return a + b
    
    end
}



TestTable2 = {
    dispatchEvent = function(self)
        LUABroadcaster:dispatchEvent(TestTable2, 'update', 1, 2)
    end

}]]