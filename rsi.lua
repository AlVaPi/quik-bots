function OnInit(script)              
	params = TabRead(params_path)
	if params == nil then
		message('Нет файла параметров: '..params_path,3)
		is_run = false
	else
--		pos_number = params.pos_number
		pos_next = params.pos_number
--		sum_profit = params.sum_profit

	
		ds = CreateDataSource(conf.class_code, conf.sec_code, conf.timeframe)  -- подписываемся на получение данных свечей по инструменту в массив ds
		table_show = CreateTable()
		is_run = true
	end
	profit = 0	
	last_trade_num = 0	
	candle_close_num = 0
	candle_long_num = 0
	candle_short_num = 0
	if conf.test_mode then
		table_caption = "Bot (rsi) TEST MODE"
	else
		table_caption = "Bot (rsi)"
	end
end


function OnParam( class, sec )
	if class == conf.class_code and sec == conf.sec_code then 
		status_torg =  tonumber(getParamEx(class, sec, "TRADINGSTATUS").param_value)
--		carrent_price = tonumber(getParamEx(class, sec, "LAST").param_value)
	end
end
function OnFuturesClientHolding(fch)
	if fch.sec_code == conf.sec_code then
		params.pos_number = fch.totalnet
		TabSave (params, params_path)
	end
end

function OnStop()              
     is_run = false
--	 params.pos_number = pos_number
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
			params.last_sell_price = trade.price
	
          else 
--            Покупка
			params.last_buy_price = trade.price

          end
		  params.sum_profit = params.sum_profit + (profit * trade.qty)
		  TabSave (params, params_path)
        end
    end
end

function main()
	while is_run do
		is_torg = false
		if isConnected() == 1 and status_torg == 1 then -- проверка наличия соеденения с сервером и поподания в торговое окно
			table_show:SetCaption(table_caption..' - ожидаем данные')
			ds_num = ds:Size() or 0
			carrent_price = ds:C(ds_num)

			rsi_candles = getNumCandles(conf.tag_rsi) or 0
			rsi_0, rsi_0_num, rsi_0_legend = getCandlesByIndex(conf.tag_rsi, 0, 0, rsi_candles)	
						
			is_torg = ds:Size() > 0  and rsi_candles > 0
		end
 		
		if is_torg then -- торговля
			table_show:SetCaption(table_caption..' - торговля')

			rsi_value = rsi_0[rsi_0_num-1].close
			rsi_min, rsi_max, rsi_avr = MinMax(0, conf.tag_rsi, 5,"close", 0)
			trend_up = rsi_value > 50
			trend_down = rsi_value < 50
			if trend_up then 
				trend_ind = "trend up"
				
			elseif trend_down then
				trend_ind = "trend down"
				
			else
				trend_ind = "no trend"
			end			
			abs_pos_number = math.abs (params.pos_number)		
-- место для размещения торговой логики				
			wait_long = CrossOver(1, conf.tag_rsi, 50, "close")
			
			wait_short = CrossUnder(1, conf.tag_rsi, 50,  "close")
			if wait_long then 
				wls_ind = "wait long"
			elseif wait_short then
				wls_ind = "wait short"
			else
				wls_ind = "no wait"
			end
			open_long = wait_long -- and trend_up
			open_short = wait_short	--  and trend_down 		
			if open_long then 
				ols_ind = "open long"
				if ds_num > candle_long_num then
					PlaceLabel(conf.tag_rsi, 0, "open long")
					candle_long_num = ds_num
				end
			elseif open_short then
				ols_ind = "open short"
				if ds_num > candle_short_num then
					PlaceLabel(conf.tag_rsi, 100, "open short")
					candle_short_num = ds_num
				end
			else
				ols_ind = "no open"
			end			
			close_long = wait_short --or CrossUnder(0, conf.tag_rsi, 80,  "close")
			close_short = wait_long --or CrossOver(0, conf.tag_rsi, 20, "close")	
			if close_long then 
				cls_ind = "close long"
			elseif close_short then
				cls_ind = "close short"
			else
				cls_ind = "no close"
			end						
			
			if CandleUp(conf.tag_price,0) then 
				can_ind = "Candle Up"
			elseif CandleDown(conf.tag_price,0) then
				can_ind = "Candle Down"
			else
				can_ind = "Candle undefine"
			end	

			
		
			if params.pos_number > 0 then 
				last_trade_price = params.last_buy_price 
				profit = carrent_price - params.last_buy_price
			elseif 	params.pos_number < 0 then 
				last_trade_price = params.last_sell_price 
				profit = params.last_sell_price - carrent_price
			else
				profit = 0
			end
			
			UpdateTableRow(table_show, 1, conf.sec_code, params.pos_number, last_trade_price, carrent_price, profit, profit * abs_pos_number)
			UpdateTableRow(table_show, 2, "RSI", MathRound(rsi_value), MathRound(rsi_min),MathRound(rsi_max), MathRound(rsi_avr), "")
			UpdateTableRow(table_show, 3, "Logic", "",trend_ind, wls_ind, ols_ind, cls_ind)			
			UpdateTableRow(table_show, 4, "Candle", CandleDiff(conf.tag_price,0), can_ind, "", "", "")
			UpdateTableRow(table_show, 5, "Итого", "", "", "", "", params.sum_profit)
			
			if params.pos_number == pos_next then
				if profit >= conf.profit and ds_num > candle_close_num then -- закрываем позицию, если достигнут профит 
					CloseAllPos()
					candle_close_num = ds_num
					pos_next = 0
				else
					if params.pos_number == 0 then   -- вход в позицию
						if open_long then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", conf.trade_lots)
							pos_next = conf.trade_lots
						elseif 	open_short then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", conf.trade_lots)
							pos_next = -conf.trade_lots
						else
						
						end
					elseif params.pos_number >= conf.trade_lots then -- выход из лонга
						if close_long then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
							pos_next = 0
						else
	
						end
					elseif params.pos_number <= -conf.trade_lots then --выход из шорта
						if close_short then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", abs_pos_number)
							pos_next = 0
						else 
						
						end	
					end
				end
			
			end
		end

		sleep(1000)            -- обрабатываем цикл с задержкой 1сек.
    end
end 
function CloseAllPos()
	if params.pos_number > 0 then
		trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
	elseif params.pos_number < 0 then
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
		t:SetCaption(table_caption)
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
	if msg == QTABLE_LBUTTONDBLCLK and par1 ==6 then
		if par2 == 1 then
			message ('Bot (rsi) --> Стоп скрипт вручную', 2)
			OnStop()
		end
		if par2 == 6 then
			message ('Bot (rsi) --> Закрываем позиции вручную и стоп', 2)
			CloseAllPos()
			OnStop()
		end
	end

end