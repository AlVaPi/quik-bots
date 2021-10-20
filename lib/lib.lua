function table.val_to_str ( v )
   if "string" == type( v ) then
      v = string.gsub( v, "\n", "\\n" )
      if string.match( string.gsub(v,"[^'\"]",""), '^"+$' ) then
         return "'" .. v .. "'"
      end
      return '"' .. string.gsub(v,'"', '\\"' ) .. '"'
   end
   return "table" == type( v ) and table.tostring( v ) or tostring( v )
end

function table.key_to_str ( k )
   if "string" == type( k ) and string.match( k, "^[_%a][_%a%d]*$" ) then
      return k
   end
   return "[" .. table.val_to_str( k ) .. "]"
end

function table.tostring( tbl )
   local result, done = {}, {}
   for k, v in ipairs( tbl ) do
      table.insert( result, table.val_to_str( v ) )
      done[ k ] = true
   end
   for k, v in pairs( tbl ) do
      if not done[ k ] then
         table.insert( result, table.key_to_str( k ) .. "=" .. table.val_to_str( v ) )
      end
   end
   return "{" .. table.concat( result, ",\n" ) .. "}"
end

function TabRead(filename)
   local f,err = io.open(filename,"r")
   if not f then
      return nil,err
   end
   local tbl = assert(loadstring("return " .. f:read("*a")))
   f:close()
   return tbl()
end

function TabSave(tbl,filename)
   local f,err = io.open(filename,"w")
   if not f then
      return nil,err
   end
   f:write(table.tostring(tbl))
   f:close()
   return true
end

function timeformat(time_unf)
     local in1, in2=0,0
     local time_form=0      
     in1=string.find(time_unf,":" , 0)
     if in1~=nil and in1~=0 then
        in2=string.find(time_unf,":" , in1+1) 
        time_form=string.sub(time_unf, 0 ,in1-1)..string.sub(time_unf, in1+1 ,in2-1)..string.sub(time_unf, in2+1 ,string.len(time_unf))
     end
     return time_form
end

function bit_set( flags, index )
    local n=1;
    n=bit.lshift(1, index);
    if bit.band(flags, n) ~=0 then
        return true
    else
        return false
    end
end

function GetLots(sec)
    local lots = 0
    local n = getNumberOf("futures_client_holding")
    local futures_client_holding={}                    
    for i=0,n-1 do             
       futures_client_holding = getItem("futures_client_holding", i)
       if tostring(futures_client_holding["sec_code"])==sec then
          lots=tonumber(futures_client_holding["totalnet"])
       end
    end      
    return lots
end
function GetLTime()
	-- âîçâðàùàåò òåêóùåå âðåìÿ êîìïüþòåðà â âèäå ÷èñëà ôîðìàòà HHMMSS
	return tonumber(os.date("%H%M%S"))
end
-------------------------------------------

-- ñòîï çàÿâêà
function SendStopOrder(conf, operation, quantity, stop_price)    
    local offset=1 -- îòñòóï äëÿ ãàðàíòèðîâàííîãî èñïîëíåíèÿ îðäåðà ïî ðûíêó (â êîë-âå øàãîâ öåíû)
    local price
    local direction   
    local step = tonumber(getParamEx(conf.class_code, conf.sec_code, "SEC_PRICE_STEP").param_value)
    if operation=="B" then
        price = stop_price + step*offset 
        direction = "5" -- Íàïðàâëåííîñòü ñòîï-öåíû. «5» - áîëüøå èëè ðàâíî
    else 
        price = stop_price - step*offset 
        direction = "4" -- Íàïðàâëåííîñòü ñòîï-öåíû. «4» - ìåíüøå èëè ðàâíî
    end
    local trans_params = 
        {
        CLIENT_CODE = conf.account,
        CLASSCODE = conf.class_code,
        SECCODE = conf.sec_code,
        ACCOUNT = conf.account,
        TYPE = "L",
        TRANS_ID = tostring(os.time()),
        OPERATION = tostring(operation),
        QUANTITY = tostring(math.abs(quantity)),
        PRICE = string.format("%i",price),
		STOPPRICE = string.format("%i",stop_price),
        ACTION = "NEW_STOP_ORDER",
		STOP_ORDER_KIND = "SIMPLE_STOP_ORDER",
		CONDITION = direction,
		EXPIRY_DATE = "TODAY",
		COMMENT = "BB_bot"
        }
   local result = sendTransaction(trans_params)
--	message('Ð¢Ñ€Ð°Ð½Ð·Ð°ÐºÑ†Ð¸Ñ: '..trans_params.TRANS_ID..'   '..trans_params.OPERATION..' Ð¦ÐµÐ½Ð°: '.. trans_params.PRICE,3)
   if string.len(result) ~= "" then
--       message('Error: '..result,3)
       return nil, result
   else
       return trans_id, result
   end      
end
function MathRound(num)
	return tonumber(string.format("%.1f", num))
end
function RubPrice(inprice, ccode, scode)
	local class_code = ccode or conf.class_code
	local sec_code = scode or conf.sec_code
	local sec_price_step = tonumber(getParamEx(class_code, sec_code, "SEC_PRICE_STEP").param_value)
	local steppricet = tonumber(getParamEx(class_code, sec_code, "STEPPRICET").param_value)
    local price = inprice / sec_price_step * steppricet
    return MathRound(price)
end


-------------------------------------------------------------------------------------

--------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------




-------------------------------------------------------------------------------------------

function IIIF (if1,val1,if2,val2,val3)
	if if1 then 
		return val1
	elseif if2 then
		return val2
	else
		return val3
	end			
end
