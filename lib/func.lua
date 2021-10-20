function OnInit(script)              
	params = TabRead(params_path)
	if params == nil then
		message('Íåò ôàéëà ïàðàìåòðîâ: '..params_path,3)
		is_run = false
	else
		ds = CreateDataSource(conf.class_code, conf.sec_code, conf.timeframe)  -- ïîäïèñûâàåìñÿ íà ïîëó÷åíèå äàííûõ ñâå÷åé ïî èíñòðóìåíòó â ìàññèâ ds
		table_show = CreateTable()
		is_run = true
	end
	profit = 0	
	last_trade_num = 0	
	candle_close_num = 0
	candle_long_num = 0
	candle_short_num = 0
	if conf.test_mode then
		table_caption = conf.table_caption_test
	else
		table_caption = conf.table_caption
	end
end


function OnParam( class, sec )
	if class == conf.class_code and sec == conf.sec_code then 
		status_torg =  tonumber(getParamEx(class, sec, "TRADINGSTATUS").param_value)
	end
end
function OnFuturesClientHolding(fch)
	if fch.sec_code == conf.sec_code and not conf.test_mode then
		params.pos_number = fch.totalnet
		TabSave (params, params_path)
	end
end

function OnStop()              
     is_run = false
	 TabSave (params, params_path)
     ds:Close() 
	 table_show:delete()
end

function OnTrade(trade)
    -- Åñëè íîìåð ïîñëåäíåãî òðåéäà íå íå ðàâåí íîìåðó òåêóùåãî
    if trade.sec_code == conf.sec_code and last_trade_num < trade.trade_num and not conf.test_mode then
        -- Çàïîìíèì íîìåð ïîñëåäíåãî òðåéäà
        last_trade_num = trade.trade_num
        -- Åñëè çàÿâêà íå àêòèâíà è èñïîëíåíà
        if bit_set(trade.flags, 0) == false and bit_set(trade.flags, 1) == false then
          if bit_set(trade.flags, 2) == true then
--            Ïðîäàæà
			params.last_sell_price = trade.price
	
          else 
--            Ïîêóïêà
			params.last_buy_price = trade.price

          end
		  params.sum_profit = params.sum_profit + (profit * trade.qty)
		  TabSave (params, params_path)
        end
    end
end
----------------------------------------------------------------
function SendMarketOrder(operation, quantity, scode, ccode) 
	local class_code = ccode or conf.class_code
	local sec_code = scode or conf.sec_code
	local qty = quantity or conf.trade_lots
	local price = 0
	local result = ""
	local test_msg = ""
	local pos = 0
    if operation=="B" then
--        price = tonumber(getParamEx(conf.class_code, conf.sec_code, "PRICEMAX").param_value)
		test_msg = "open long"
		pos = params.pos_number + qty
		if conf.test_mode then params.last_buy_price = carrent_price end
    else 
--        price = tonumber(getParamEx(conf.class_code, conf.sec_code, "PRICEMIN").param_value)
		test_msg = "open short"
		pos = params.pos_number - qty
		if conf.test_mode then params.last_sell_price = carrent_price end
	end
    local trans_params = 
          {
            CLIENT_CODE = conf.account,
            CLASSCODE = class_code,
            SECCODE = csec_code,
            ACCOUNT = conf.account,
            TYPE = "M",
            TRANS_ID = tostring(os.time()),
            OPERATION = tostring(operation),
            QUANTITY = tostring(qty),
            PRICE = string.format("%i", tonumber(price)),
            ACTION = "NEW_ORDER",
			COMMENT = table_caption
          }
	if conf.test_mode then
		result = "Test mode"
		PlaceLabel(conf.tag_price, carrent_price, test_msg)
		params.pos_number = pos
		params.sum_profit = params.sum_profit + (profit * qty)
		TabSave (params, params_path)
	else
		result = sendTransaction(trans_params)
	end	
	while pos ~= params.pos_number do
		sleep(100)
	end
	
--	message('Òðàíçàêöèÿ: '..trans_params.TRANS_ID..'   '..trans_params.OPERATION..' Öåíà: '.. trans_params.PRICE,3)
   if string.len(result) ~= "" then
--       message('Error: '..result,3)
       return nil, result
   else
       return trans_id, result
   end      
end
function CloseAllPos()
	if params.pos_number > 0 then
		trans_id, trans_msg = SendMarketOrder("S", abs_pos_number)
	elseif params.pos_number < 0 then
		trans_id, trans_msg = SendMarketOrder("B", abs_pos_number)
	end
end
------------------------
function CreateTable ()
-- ñîçäàòü ýêçåìïëßð QTable
	local t = QTable.new()
	if not t then
		message("Create table error!", 3)
		return nil
	else
		t:AddColumn("SEC", QTABLE_CACHED_STRING_TYPE, 10)
		t:AddColumn("Ïîç.", QTABLE_CACHED_STRING_TYPE, 10)
		t:AddColumn("Öåíà ñäåëêè", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("Öåíà òåê.", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("Ìàðæà", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("Ïðèáûëü", QTABLE_CACHED_STRING_TYPE, 20)
		SetTableNotificationCallback (t.t_id, OnTableEvent)
		t:SetCaption(table_caption)
		t:Show()
		t:AddLines(6)
		t:SetPosition(0, 0, 600, 145)
		SetCell(t.t_id, 6, 1, "Ñòîï")
		SetCell(t.t_id, 6, 6, "Çàêðûòü âñ¸")
		return t
	end	
end
function UpdateTableRow(t, row, col1, col2, col3, col4, col5, col6)

	SetCell(t.t_id, row, 1, tostring(col1))
	SetCell(t.t_id, row, 2, tostring(col2))
	SetCell(t.t_id, row, 3, tostring(col3))
	SetCell(t.t_id, row, 4, tostring(col4))
	SetCell(t.t_id, row, 5, tostring(col5))
	SetCell(t.t_id, row, 6, tostring(col6))
end
function OnTableEvent (t_id, msg, par1, par2)
	if msg == QTABLE_LBUTTONDBLCLK and par1 ==6 then
		if par2 == 1 then
			message (table_caption.." --> Ñòîï ñêðèïò âðó÷íóþ", 2)
			OnStop()
		end
		if par2 == 6 then
			message (table_caption.." --> Çàêðûâàåì ïîçèöèè âðó÷íóþ è ñòîï", 2)
			CloseAllPos()
			OnStop()
		end
	end

end

