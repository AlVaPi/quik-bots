dofile(getScriptPath() .. "\\lib.lua");

-- присванивание переменным начальных базовых значений торгового алгоритма
config_path = getScriptPath()..'\\bot2.conf'
conf = TabRead(config_path)
if conf == nil then
	message('Нет файла конфигурации: '..config_path,3)
end
params_path = getScriptPath()..'\\bot.params'
params = TabRead(params_path)
if params == nil then
	message('Нет файла параметров: '..params_path,3)
end

function OnInit(script)              
	params = TabRead(params_path)
	if params == nil then
		message('Нет файла параметров: '..params_path,3)
		is_run = false
	else
		ds1 = CreateDataSource(conf.class_code, conf.sec_code1, conf.timeframe)  -- подписываемся на получение данных свечей по инструменту в массив ds1
		ds2 = CreateDataSource(conf.class_code, conf.sec_code2, conf.timeframe)  -- подписываемся на получение данных свечей по инструменту в массив ds2
		table_show = CreateTable()
		is_run = true
	end
	profit = 0	
	profit1 = 0	
	profit2 = 0	
	last_trade_num1 = 0	
	candle_close_num1 = 0
	candle_long_num1 = 0
	candle_short_num 1= 0
	last_trade_num2 = 0	
	candle_close_num2 = 0
	candle_long_num2 = 0
	candle_short_num2 = 0	
	if conf.test_mode then
		table_caption = conf.table_caption_test
	else
		table_caption = conf.table_caption
	end
end
function OnParam( class, sec )
	if class == conf.class_code and sec == conf.sec_code1 then 
		status_torg1 =  tonumber(getParamEx(class, sec, "TRADINGSTATUS").param_value)
	end
	if class == conf.class_code and sec == conf.sec_code2 then 
		status_torg2 =  tonumber(getParamEx(class, sec, "TRADINGSTATUS").param_value)
	end
end
function OnFuturesClientHolding(fch)
	if fch.sec_code == conf.sec_code1 and not conf.test_mode then
		params.pos_number1 = fch.totalnet
		TabSave (params, params_path)
	end
	if fch.sec_code == conf.sec_code2 and not conf.test_mode then
		params.pos_number2 = fch.totalnet
		TabSave (params, params_path)
	end	
end
function OnStop()              
     is_run = false
	 TabSave (params, params_path)
     ds1:Close() 
     ds2:Close() 
	 table_show:delete()
end

function OnTrade(trade)
    -- Если номер последнего трейда не не равен номеру текущего
    if trade.sec_code == conf.sec_code1 and last_trade_num1 < trade.trade_num then
        -- Запомним номер последнего трейда
        last_trade_num1 = trade.trade_num;
        -- Если заявка не активна и исполнена
        if bit_set(trade.flags, 0) == false and bit_set(trade.flags, 1) == false then
          if bit_set(trade.flags, 2) == true then
--            Џродажа
			params.last_sell_price1 = trade.price
          else 
			params.last_buy_price1 = trade.price
          end
			params.sum_profit1 = params.sum_profit1 + (profit1 * trade.qty)         
			TabSave (params, params_path)
        end
    end
    if trade.sec_code == conf.sec_code2 and last_trade_num2 < trade.trade_num then
        -- Запомним номер последнего трейда
        last_trade_num2 = trade.trade_num;
        -- Если заявка не активна и исполнена
        if bit_set(trade.flags, 0) == false and bit_set(trade.flags, 1) == false then
          if bit_set(trade.flags, 2) == true then
--            Џродажа
			params.last_sell_price2 = trade.price
          else 
			params.last_buy_price2 = trade.price
          end
			params.sum_profit2 = params.sum_profit2 + (profit2 * trade.qty)        
		  TabSave (params, params_path)
        end
    end	
end

function main()
	while is_run do
	if table_show:IsClosed() then
		table_show = CreateTable()
	end	

 	if isConnected()==1 and status_torg1==1 and status_torg2==1 then -- проверка наличия соеденения с сервером и поподания в торговое окно
		while carrent_price1 <= 0 and carrent_price2 <= 0 do
			sleep(100)
		end
		if pos_number1 < 0 then
			diff_price1 = last_trade_price1 - carrent_price1
		elseif pos_number1 > 0 then
			diff_price1 = carrent_price1 - last_trade_price1
		end
		if pos_number2 < 0 then
			diff_price2 = last_trade_price2 - carrent_price2
		elseif pos_number2 > 0 then
			diff_price2 = carrent_price2 - last_trade_price2
		end
		profit1 = diff_price1 * math.abs (pos_number1)
		
		profit2 = diff_price2 * math.abs (pos_number2)
		profit = profit1 + profit2	
		UpdateTableRow(table_show, 1, conf.sec_code1, pos_number1, last_trade_price1, carrent_price1, diff_price1, profit1) 
		UpdateTableRow(table_show, 2, conf.sec_code2, pos_number2, last_trade_price2, carrent_price2, diff_price2, profit2)
		UpdateTableRow(table_show, 3, "Итого", "", "", "", "", profit)		
		if pos_number1 == 0 then
			if bot2_direct == "short" then
				trans_id1, trans_msg1 = SendMarketOrder(conf, conf.sec_code1, "S", conf.trade_lots1)
			elseif bot2_direct == "long" then
				trans_id1, trans_msg1 = SendMarketOrder(conf, conf.sec_code1, "B", conf.trade_lots1)
			end
		end
		if pos_number2 == 0 then
			if bot2_direct == "short" then
				trans_id2, trans_msg2 = SendMarketOrder(conf, conf.sec_code2, "S", conf.trade_lots2)
			elseif bot2_direct == "long" then
				trans_id2, trans_msg2 = SendMarketOrder(conf, conf.sec_code2, "B", conf.trade_lots2)
			end
		end	

		if profit > conf.profit then
			message ('Bot2 --> '..profit..' Больше чем '..conf.profit..' поэтому закрываем', 2)
			-- if bot2_direct == "short" then 
				-- bot2_direct = "long"
			-- else
				-- bot2_direct = "short"
			-- end
			-- params.bot2_direct = bot2_direct
			-- TabSave (params, params_path)
			CloseAllPos()
			sleep(3001)            -- обрабатываем цикл с задержкой 3сек.
		end
		end
	sleep(3001)            -- обрабатываем цикл с задержкой 3сек.
    end
end 
function CloseAllPos()
	if pos_number1 > 0 then
		trans_id1, trans_msg1 = SendMarketOrder(conf, conf.sec_code1, "S", math.abs (pos_number1))
	elseif pos_number1 < 0 then
		trans_id1, trans_msg1 = SendMarketOrder(conf, conf.sec_code1, "B", math.abs (pos_number1))
	end
	if pos_number2 > 0 then
		trans_id2, trans_msg2 = SendMarketOrder(conf, conf.sec_code2, "S", math.abs (pos_number2))
	elseif pos_number2 < 0 then
		trans_id2, trans_msg2 = SendMarketOrder(conf, conf.sec_code2, "B", math.abs (pos_number2))
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
		t:SetCaption(table_caption)
		t:Show()
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
			message ('Bot2 --> Стоп скрипт вручную', 2)
			OnStop()
		end
		if par2 == 6 then
			message ('Bot2 --> Закрываем позиции вручную и стоп', 2)
			CloseAllPos()
			OnStop()
		end
	end

end
