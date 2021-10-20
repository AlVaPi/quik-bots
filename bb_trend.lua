function OnInit(script)              
	params = TabRead(params_path)
	if params == nil then
		message('Нет файла параметров: '..params_path,3)
		is_run = false
	else
		last_buy_price = params.last_buy_price
		last_sell_price =  params.last_sell_price
		pos_number = params.pos_number
		pos_next = params.pos_number
		last_trade_num = 0
		profit = 0
		ds = CreateDataSource(conf.class_code, conf.sec_code, conf.timeframe)  -- подписываемся на получение данных свечей по инструменту в массив ds
		table_show = CreateTable()
		is_run = true
	end
end


--    is_run = true	
	
	
	
--	local futures_holding = getFuturesHolding("SPBFUT01", conf.account, conf.sec_code,0)
--			message ("futures_holding.avrposnprice >> "..tostring(futures_holding.avrposnprice),2)
--	pos_number = futures_holding.totalnet

function OnParam( class, sec )
	if class == conf.class_code and sec == conf.sec_code then 
		status_torg =  tonumber(getParamEx(class, sec, "TRADINGSTATUS").param_value)
--		carrent_price = tonumber(getParamEx(class, sec, "LAST").param_value)
	end
end
function OnFuturesClientHolding(fch)
	if fch.sec_code == conf.sec_code then
		pos_number = fch.totalnet
		params.pos_number = pos_number
		TabSave (params, params_path)
	end
end

function OnStop()              
     is_run = false
	 params.last_buy_price = last_buy_price
	 params.last_sell_price = last_sell_price
	 params.pos_number = pos_number
	 TabSave (params, params_path)
     ds:Close() 
	 table_show:delete()
end

function OnTrade(trade)
    -- Если номер последнего трейда не не равен номеру текущего
    if trade.sec_code == conf.sec_code and last_trade_num < trade.trade_num then
        -- Запомним номер последнего трейда
        last_trade_num = trade.trade_num
        -- Если заявка не активна и исполнена
        if bit_set(trade.flags, 0) == false and bit_set(trade.flags, 1) == false then
          if bit_set(trade.flags, 2) == true then
--            Продажа
			last_sell_price = trade.price
			params.last_sell_price = last_sell_price
          else 
--            Покупка
			last_buy_price = trade.price
			params.last_buy_price = last_buy_price	
          end
		  TabSave (params, params_path)
        end
    end
end

function main()
	while is_run do
		is_torg = false
		if isConnected() == 1 and status_torg == 1 then -- проверка наличия соеденения с сервером и поподания в торговое окно
			table_show:SetCaption("Bot - ожидаем данные")
			ds_num = ds:Size()
			carrent_price = ds:C(ds_num)
			bb_candles = getNumCandles(conf.tag_bb)
			bb_0, bb_0_num, bb_0_legend = getCandlesByIndex(conf.tag_bb, 0, 0, bb_candles)
			bb_1, bb_1_num, bb_1_legend = getCandlesByIndex(conf.tag_bb, 1, 0, bb_candles)
			bb_2, bb_2_num, bb_2_legend = getCandlesByIndex(conf.tag_bb, 2, 0, bb_candles)
	
			is_torg = ds:Size() > 0 and bb_candles > 0
		end
 		
		if is_torg then 
			table_show:SetCaption("Bot - торговля")
			bb_center = MathRound(bb_0[bb_0_num-1].close)
			bb_center1 = MathRound(bb_0[bb_0_num-2].close)
			bb_center2 = MathRound(bb_0[bb_0_num-3].close)
			bb_high = MathRound(bb_1[bb_1_num-1].close)
			bb_low = MathRound(bb_2[bb_2_num-1].close)
			bb_trend_up = MathRound(bb_0[bb_0_num-1].close) > MathRound(bb_0[bb_0_num-2].close)
			bb_trend_down = MathRound(bb_0[bb_0_num-1].close) < MathRound(bb_0[bb_0_num-2].close)
			if bb_trend_up then 
				bb_trend_ind = "bb trend up"
			elseif bb_trend_down then
				bb_trend_ind = "bb trend down"
			else
				bb_trend_ind = "bb no trend"
			end			
			abs_pos_number = math.abs (pos_number)			
			open_long = bb_center > bb_center1 and bb_center2 > bb_center1
			open_short = bb_center < bb_center1 and bb_center2 < bb_center1
			if open_long then 
				ls_ind = "open long"
			elseif open_short then
				ls_ind = "open short"
			else
				ls_ind = "no open"
			end
			if pos_number > 0 then 
				last_trade_price = last_buy_price 
				profit = carrent_price - last_buy_price
			elseif 	pos_number < 0 then 
				last_trade_price = last_sell_price 
				profit = last_sell_price - carrent_price
			else
				profit = 0
			end
			UpdateTableRow(table_show, 1, conf.sec_code, pos_number, last_trade_price, carrent_price, profit, profit * abs_pos_number)  
			UpdateTableRow(table_show, 3, "BB", "", bb_trend_ind, "", "", "")			
--			UpdateTableRow(table_show, 4, "BuBe", "", MathRound(bube_power), bb_trend_ind, stab_long_ind, "")
			UpdateTableRow(table_show, 5, "LOGIC", "", ls_ind, "", "", "")
			
-- место для размещения торговой логики	
			if pos_number == pos_next then
				if profit >= conf.profit then -- закрываем позицию, если достигнут профит 
					CloseAllPos()
					pos_next = 0
				else
					if pos_number == 0 then
						if open_long then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", conf.trade_lots)
							pos_next = conf.trade_lots
						elseif open_short then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", conf.trade_lots)
							pos_next = -conf.trade_lots
						else
						
						end
					elseif pos_number >= conf.trade_lots then
						if bb_trend_down then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
							pos_next = 0
						end
					elseif pos_number <= -conf.trade_lots then
						if bb_trend_up then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", abs_pos_number)
							pos_next = 0
						end	
					end
				end
			
			end
		end

		sleep(1000)            -- обрабатываем цикл с задержкой 1сек.
    end
end 
function CloseAllPos()
	if pos_number > 0 then
		trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
	elseif pos_number < 0 then
		trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", abs_pos_number)
	end
end
function CreateTable ()
-- создать экземплЯр QTable
	local t = QTable.new()
	if not t then
		message("Create table error!", 3)
		return nil
	else
		t:AddColumn("SEC", QTABLE_CACHED_STRING_TYPE, 10)
		t:AddColumn("Поз.", QTABLE_CACHED_STRING_TYPE, 10)
		t:AddColumn("Цена сделки", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("Цена тек.", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("Маржа", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("Прибыль", QTABLE_CACHED_STRING_TYPE, 20)
		SetTableNotificationCallback (t.t_id, OnTableEvent)
		t:Show()
		t:SetCaption("Bot")
		t:AddLines(6)
		t:SetPosition(0, 0, 600, 145)
		SetCell(t.t_id, 6, 1, "Стоп")
		SetCell(t.t_id, 6, 6, "Закрыть всё")
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
	if msg == QTABLE_LBUTTONDBLCLK and par1 ==4 then
		if par2 == 1 then
			message ('Bot --> Стоп скрипт вручную', 2)
			OnStop()
		end
		if par2 == 6 then
			message ('Bot --> Закрываем позиции вручную и стоп', 2)
			CloseAllPos()
			OnStop()
		end
	end

end