function main()
	while is_run do
		is_torg = false
		if isConnected() == 1 and status_torg == 1 then -- �������� ������� ���������� � �������� � ��������� � �������� ����
			table_show:SetCaption(table_caption..' - ������� ������')
			ds_num = ds:Size() or 0
			carrent_price = ds:C(ds_num)

			rsi_candles = getNumCandles(conf.tag_rsi) or 0
			rsi_0, rsi_0_num, rsi_0_legend = getCandlesByIndex(conf.tag_rsi, 0, 0, rsi_candles)	
						
			is_torg = ds:Size() > 0  and rsi_candles > 0
		end
 		
		if is_torg then -- ��������
			table_show:SetCaption(table_caption..' - ��������')
			abs_pos_number = math.abs (params.pos_number)

			rsi_value = rsi_0[rsi_0_num-1].close
			rsi_min, rsi_max, rsi_avr = MinMax(0, conf.tag_rsi, 5,"close", 0)
			trend_up = rsi_value > 50
			trend_down = rsi_value < 50
			trend_ind = IIIF(trend_up, "trend up", trend_down, "trend down", "no trend")		
				
-- ����� ��� ���������� �������� ������				
			wait_long = CrossOver(1, conf.tag_rsi, 50, "close")
			wait_short = CrossUnder(1, conf.tag_rsi, 50,  "close")
			wls_ind = IIIF(wait_long, "wait long", wait_short, "wait short", "no wait")
			
			open_long = wait_long -- and trend_up
			open_short = wait_short	--  and trend_down 		
			ols_ind = IIIF(open_long, "open long", open_short, "open short", "no open")
			
			close_long = wait_short --or CrossUnder(0, conf.tag_rsi, 80,  "close")
			close_short = wait_long --or CrossOver(0, conf.tag_rsi, 20, "close")	
			cls_ind = IIIF(close_long, "close long", close_short, "close short", "no close")				
			
			can_ind = IIIF(CandleUp(conf.tag_price,0), "Candle Up", CandleDown(conf.tag_price,0), "Candle Down", "Candle undefine")
		
			if params.pos_number > 0 then 
				last_trade_price = params.last_buy_price 
				profit = carrent_price - params.last_buy_price
			elseif 	params.pos_number < 0 then 
				last_trade_price = params.last_sell_price 
				profit = params.last_sell_price - carrent_price
			else
				profit = 0
			end
			if GetLTime() < conf.trade_start or GetLTime() > conf.trade_stop then
				open_long = false
				open_short = false
				table_show:SetCaption(table_caption..' - �� ����� ��������� �������')
			end
			UpdateTableRow(table_show, 1, conf.sec_code, params.pos_number, last_trade_price, carrent_price, profit, profit * abs_pos_number)
			UpdateTableRow(table_show, 2, "RSI", MathRound(rsi_value), MathRound(rsi_min),MathRound(rsi_max), MathRound(rsi_avr), "")
			UpdateTableRow(table_show, 3, "Logic", "",trend_ind, wls_ind, ols_ind, cls_ind)			
			UpdateTableRow(table_show, 4, "Candle", CandleDiff(conf.tag_price,0), can_ind, "", "", "")
			UpdateTableRow(table_show, 5, "�����", "", "", "", "", params.sum_profit)
			
			if params.pos_number == pos_next then
				if profit >= conf.profit and ds_num > candle_close_num then -- ��������� �������, ���� ��������� ������ 
					CloseAllPos()
					candle_close_num = ds_num
					pos_next = 0
				else
					if params.pos_number == 0 then   -- ���� � �������
						if open_long then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", conf.trade_lots)
							pos_next = conf.trade_lots
						elseif 	open_short then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", conf.trade_lots)
							pos_next = -conf.trade_lots
						else
						
						end
					elseif params.pos_number >= conf.trade_lots then -- ����� �� �����
						if close_long then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "S", abs_pos_number)
							pos_next = 0
						else
	
						end
					elseif params.pos_number <= -conf.trade_lots then --����� �� �����
						if close_short then
							trans_id, trans_msg = SendMarketOrder(conf, conf.sec_code, "B", abs_pos_number)
							pos_next = 0
						else 
						
						end	
					end
				end
			
			end
		end

		sleep(1000)            -- ������������ ���� � ��������� 1���.
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
		t:SetCaption(table_caption)
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
	if msg == QTABLE_LBUTTONDBLCLK and par1 ==6 then
		if par2 == 1 then
			message ('Bot (rsi) --> ���� ������ �������', 2)
			OnStop()
		end
		if par2 == 6 then
			message ('Bot (rsi) --> ��������� ������� ������� � ����', 2)
			CloseAllPos()
			OnStop()
		end
	end

end