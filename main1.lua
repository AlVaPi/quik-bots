function OnInit(script)              
	params = TabRead(params_path)
	if params == nil then
		message('Нет файла параметров: '..params_path,3)
		is_run = false
	else
		last_buy_price = params.last_buy_price
		last_sell_price =  params.last_sell_price
		pos_number = params.pos_number
		last_trade_num = 0
		time_step = conf.timeframe * 60
		buy_time = os.time()
		sell_time = os.time()
		buy_time_diff = time_step
		sell_time_diff = time_step
		profit = 0
		ds = CreateDataSource(conf.class_code, conf.sec_code, conf.timeframe)  -- подписываемся на получение данных свечей по инструменту в массив ds
		while ds:Size() == 0 do
			sleep(100)
		end
		
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
			sell_time = os.time()
          else 
--            Покупка
			last_buy_price = trade.price
			params.last_buy_price = last_buy_price	
			buy_time = os.time()
          end
		  TabSave (params, params_path)
        end
    end
end

function main()
	while is_run do
 		if isConnected() == 1 and status_torg == 1 then -- проверка наличия соеденения с сервером и поподания в торговое окно

			local ds_num = ds:Size()
			carrent_price = ds:C(ds_num)
			local bb_candles = getNumCandles(conf.tag_bb)
			local bb_0, bb_0_num, bb_0_legend = getCandlesByIndex(conf.tag_bb, 0, 0, bb_candles)
			local bb_1, bb_1_num, bb_1_legend = getCandlesByIndex(conf.tag_bb, 1, 0, bb_candles)
			local bb_2, bb_2_num, bb_2_legend = getCandlesByIndex(conf.tag_bb, 2, 0, bb_candles)
			bb_center = bb_0[bb_0_num-1].close
			bb_high = bb_1[bb_1_num-1].close
			bb_low = bb_2[bb_2_num-1].close
			local bulls_candles = getNumCandles(conf.tag_bulls)
			local bulls_0, bulls_0_num, bulls_0_legend = getCandlesByIndex(conf.tag_bulls, 0, 0, bulls_candles)
			local bears_candles = getNumCandles(conf.tag_bears)
			local bears_0, bears_0_num, bears_0_legend = getCandlesByIndex(conf.tag_bears, 0, 0, bears_candles)
			bu_power = bulls_0[bulls_0_num-1].close
			be_power = bears_0[bears_0_num-1].close
			bube_power = bu_power + be_power
			abs_pos_number = math.abs (pos_number)			
--			if  pos_number == 0 then
--				balance_price = bb_0[bb_0_num-1].close
--			else
--				balance_price = futures_holding.avrposnprice
--			end
			
			if pos_number > 0 then 
				buy_time_diff = time_step * abs_pos_number / conf.trade_lots
				last_trade_price = last_buy_price 
				profit = carrent_price - last_buy_price
			elseif 	pos_number < 0 then 
				sell_time_diff = time_step * abs_pos_number / conf.trade_lots
				last_trade_price = last_sell_price 
				profit = last_sell_price - carrent_price
			else
				buy_time_diff = time_step
				sell_time_diff = time_step	
				profit = 0
			end
			UpdateTableRow(table_show, 1, conf.sec_code, pos_number, last_trade_price, carrent_price, profit, profit * abs_pos_number)  
			UpdateTableRow(table_show, 3, "BB", "", MathRound(bb_center), MathRound(bb_high), MathRound(bb_low), "")			
			UpdateTableRow(table_show, 4, "Bulls", "", MathRound(bu_power), "", "", "")
			UpdateTableRow(table_show, 5, "Bears", "", MathRound(be_power), "", "", "")
-- место для размещения торговой логики	
			if profit >= conf.profit then -- закрываем позицию, если достигнут профит 
				CloseAllPos()
			else
				-- if bulls_0[bulls_0_num-1].close + bears_0[bears_0_num-1].close > 0 then
					-- buy_enable = carrent_price < bb_0[bb_0_num-1].close 
					-- sell_enable = carrent_price > bb_1[bb_1_num-1].close
				-- elseif bulls_0[bulls_0_num-1].close + bears_0[bears_0_num-1].close < 0 then
					-- buy_enable = carrent_price < bb_2[bb_2_num-1].close 
					-- sell_enable = carrent_price > bb_0[bb_0_num-1].close
				-- else
					-- buy_enable = carrent_price < bb_2[bb_2_num-1].close 
					-- sell_enable = carrent_price > bb_1[bb_1_num-1].close
				-- end
					buy_enable = carrent_price < bb_low 
					sell_enable = carrent_price > bb_high				
				if conf.safe_mode then
					if pos_number == 0 then
						buy_enable = buy_enable and bube_power > 0
						sell_enable = sell_enable and bube_power < 0
					else
						-- buy_enable = buy_enable and carrent_price < last_sell_price			
						-- sell_enable = sell_enable and carrent_price > last_buy_price					
					end	
				end
				if conf.lond_disable and pos_number >= 0 then -- запретить лонги
					buy_enable = false
				end
				if conf.short_disable and pos_number <= 0 then -- запретить шорты
					sell_enable = false
				end	
				buy_enable = buy_enable and pos_number < conf.trade_max -- проверка на макс. лотов
				sell_enable = sell_enable and pos_number > -conf.trade_max -- проверка на макс. лотов

				if os.time() < buy_time + buy_time_diff then       
					buy_enable = false  
				end
				if os.time() < sell_time + sell_time_diff then       
					sell_enable = false  
				end			
	--		message ("sell_enable >> "..tostring(sell_enable),2)	
				if buy_enable then
--					local trans_id, trans_msg = send_order(conf, "B", trade_lots, carrent_price)
					trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", conf.trade_lots)
					buy_time = os.time()
	--				sleep(1001)
				end
				if sell_enable then
--					local trans_id, trans_msg = send_order(conf, "S", trade_lots, carrent_price)
					trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", conf.trade_lots)
					sell_time = os.time()
	--				sleep(1001)
				end
			end
		end

		sleep(2000)            -- обрабатываем цикл с задержкой 2сек.
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
		t:AddLine(6)
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