function OnInit(script)              
	params = TabRead(params_path)
	if params == nil then
		message('��� ����� ����������: '..params_path,3)
		is_run = false
	else
		last_buy_price = params.last_buy_price
		last_sell_price =  params.last_sell_price
		pos_number = params.pos_number
		pos_next = params.pos_number
		last_trade_num = 0
		profit = 0
		ds = CreateDataSource(conf.class_code, conf.sec_code, conf.timeframe)  -- ������������� �� ��������� ������ ������ �� ����������� � ������ ds
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
    -- ���� ����� ���������� ������ �� �� ����� ������ ��������
    if trade.sec_code == conf.sec_code and last_trade_num < trade.trade_num then
        -- �������� ����� ���������� ������
        last_trade_num = trade.trade_num
        -- ���� ������ �� ������� � ���������
        if bit_set(trade.flags, 0) == false and bit_set(trade.flags, 1) == false then
          if bit_set(trade.flags, 2) == true then
--            �������
			last_sell_price = trade.price
			params.last_sell_price = last_sell_price
          else 
--            �������
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
		if isConnected() == 1 and status_torg == 1 then -- �������� ������� ���������� � �������� � ��������� � �������� ����
			table_show:SetCaption("Bot - ������� ������")
			ds_num = ds:Size()
			carrent_price = ds:C(ds_num)
			bb_candles = getNumCandles(conf.tag_bb)
			bb_0, bb_0_num, bb_0_legend = getCandlesByIndex(conf.tag_bb, 0, 0, bb_candles)
			bb_1, bb_1_num, bb_1_legend = getCandlesByIndex(conf.tag_bb, 1, 0, bb_candles)
			bb_2, bb_2_num, bb_2_legend = getCandlesByIndex(conf.tag_bb, 2, 0, bb_candles)

			bulls_candles = getNumCandles(conf.tag_bulls)
			bulls_0, bulls_0_num, bulls_0_legend = getCandlesByIndex(conf.tag_bulls, 0, 0, bulls_candles)
			bears_candles = getNumCandles(conf.tag_bears)
			bears_0, bears_0_num, bears_0_legend = getCandlesByIndex(conf.tag_bears, 0, 0, bears_candles)		
			is_torg = ds:Size() > 0 and bb_candles > 0 and bulls_candles > 3 and bears_candles > 3
		end
 		
		if is_torg then 
			table_show:SetCaption("Bot - ��������")
			bb_center = bb_0[bb_0_num-1].close
			bb_high = bb_1[bb_1_num-1].close
			bb_low = bb_2[bb_2_num-1].close

			bu_power = bulls_0[bulls_0_num-1].close
			be_power = bears_0[bears_0_num-1].close
			bube_power = bu_power + be_power
			bu_power_up = bulls_0[bulls_0_num-2].close > bulls_0[bulls_0_num-3].close
			bu_power_down = bulls_0[bulls_0_num-2].close < bulls_0[bulls_0_num-3].close
			be_power_up = bears_0[bears_0_num-2].close > bears_0[bears_0_num-3].close
			be_power_down = bears_0[bears_0_num-2].close < bears_0[bears_0_num-3].close	
			bube_power_up = bulls_0[bulls_0_num-2].close + bears_0[bears_0_num-2].close > bulls_0[bulls_0_num-3].close + bears_0[bears_0_num-3].close
			bube_power_down = bulls_0[bulls_0_num-2].close + bears_0[bears_0_num-2].close < bulls_0[bulls_0_num-3].close + bears_0[bears_0_num-3].close
			bube_power_nomove = bulls_0[bulls_0_num-2].close + bears_0[bears_0_num-2].close == bulls_0[bulls_0_num-3].close + bears_0[bears_0_num-3].close
			if bube_power_up then 
				stab_power_ind = "trend up"
			elseif bube_power_down then
				stab_power_ind = "trend down"
			else
				stab_power_ind = "no trend"
			end			
			abs_pos_number = math.abs (pos_number)			
			wait_long = bube_power_up and bube_power > conf.power_high
			wait_short = bube_power_down and bube_power < conf.power_low
			-- wait_long = bube_power_up
			-- wait_short = bube_power_down
			if wait_long then 
				stab_long_ind = "wait long"
			elseif wait_short then
				stab_long_ind = "wait short"
			else
				stab_long_ind = "no open"
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
			UpdateTableRow(table_show, 3, "BB", "", MathRound(bb_center), MathRound(bb_high), MathRound(bb_low), "")			
			UpdateTableRow(table_show, 4, "BuBe", "", MathRound(bube_power), stab_power_ind, stab_long_ind, "")
--			UpdateTableRow(table_show, 5, "Bears", "", MathRound(be_power), be_power_up, be_power_down, "")
			
-- ����� ��� ���������� �������� ������	
			if pos_number == pos_next then
				if profit >= conf.profit then -- ��������� �������, ���� ��������� ������ 
					CloseAllPos()
					pos_next = 0
				else
					if pos_number == 0 then
						if wait_long and carrent_price < bb_low then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", conf.trade_lots)
							pos_next = conf.trade_lots
						elseif wait_short and carrent_price > bb_high then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", conf.trade_lots)
							pos_next = -conf.trade_lots
						else
						
						end
					elseif pos_number >= conf.trade_lots then
						if wait_long then
							if carrent_price > bb_high and profit > 0 then
								trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
								pos_next = 0
							end
						else
							if profit > 0 then
								trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
								pos_next = 0
							end						
						end
					elseif pos_number <= -conf.trade_lots then
						if wait_short then
							if carrent_price < bb_low and profit > 0 then
								trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", abs_pos_number)
								pos_next = 0
							end		
						else 
							if profit > 0 then
								trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", abs_pos_number)
								pos_next = 0
							end	
						end	
					end
				end
			
			end
		end

		sleep(2000)            -- ������������ ���� � ��������� 2���.
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
-- ������� ��������� QTable
	local t = QTable.new()
	if not t then
		message("Create table error!", 3)
		return nil
	else
		t:AddColumn("SEC", QTABLE_CACHED_STRING_TYPE, 10)
		t:AddColumn("���.", QTABLE_CACHED_STRING_TYPE, 10)
		t:AddColumn("���� ������", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("���� ���.", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("�����", QTABLE_CACHED_STRING_TYPE, 20)
		t:AddColumn("�������", QTABLE_CACHED_STRING_TYPE, 20)
		SetTableNotificationCallback (t.t_id, OnTableEvent)
		t:Show()
		t:SetCaption("Bot")
		t:AddLines(6)
		t:SetPosition(0, 0, 600, 145)
		SetCell(t.t_id, 6, 1, "����")
		SetCell(t.t_id, 6, 6, "������� ��")
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
			message ('Bot --> ���� ������ �������', 2)
			OnStop()
		end
		if par2 == 6 then
			message ('Bot --> ��������� ������� ������� � ����', 2)
			CloseAllPos()
			OnStop()
		end
	end

end