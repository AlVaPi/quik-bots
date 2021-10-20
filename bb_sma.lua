function main()
	while is_run do
		is_torg = false
		if isConnected() == 1 and status_torg == 1 then -- �������� ������� ���������� � �������� � ��������� � �������� ����
			table_show:SetCaption(table_caption..' - ������� ������')
			ds_num = ds:Size() or 0
			carrent_price = ds:C(ds_num)
--			bb_candles = getNumCandles(conf.tag_bb) or 0
--			hac_candles = getNumCandles(conf.tag_haclose) or 0
			
			is_torg = ds:Size() > 0  and isChartExist(conf.tag_bb) and isChartExist(conf.tag_haclose)
		end
 		
		if is_torg then -- ��������
			table_show:SetCaption(table_caption..' - ��������')

			abs_pos_number = math.abs (params.pos_number)		
-- ����� ��� ���������� �������� ������			
			trend_up = getLastCandle(conf.tag_bb).close > getPrevCandle(conf.tag_bb).close
			trend_down = getLastCandle(conf.tag_bb).close < getPrevCandle(conf.tag_bb).close
			trend_ind = IIIF(trend_up, "trend up", trend_down, "trend down", "no trend")
			
			wait_long = CrossOver(0, conf.tag_haclose, conf.tag_bb, "close", 0, 0)
			wait_short = CrossUnder(0, conf.tag_haclose, conf.tag_bb,  "close", 0, 0)
			wls_ind = IIIF(wait_long, "wait long", wait_short, "wait short", "no wait")
			
			open_long = CrossOver(1, conf.tag_haclose, conf.tag_bb, "close", 0, 0) and ds_num > candle_long_num -- and trend_up
			open_short = CrossUnder(1, conf.tag_haclose, conf.tag_bb,  "close", 0, 0)	and ds_num > candle_short_num--  and trend_down 	
			ols_ind = IIIF(open_long, "open long", open_short, "open short", "no open")			

			close_long = open_short -- or CrossUnder(1, conf.tag_haclose, conf.tag_bb,  "close", 0, 1)
			close_short = open_long -- or CrossOver(1, conf.tag_haclose, conf.tag_bb, "close", 0, 1)
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
			UpdateTableRow(table_show, 2, "BB", MathRound(getLastCandle(conf.tag_bb).close), "","", "", "")
			UpdateTableRow(table_show, 3, "Logic", "",trend_ind, wls_ind, ols_ind, cls_ind)			
			UpdateTableRow(table_show, 4, "Candle", CandleDiff(conf.tag_price,0), can_ind, "", "", "")
			UpdateTableRow(table_show, 5, "�����", "", "", "", "", RubPrice(params.sum_profit))
			

			if profit >= conf.profit then -- ��������� �������, ���� ��������� ������ 
				CloseAllPos()
			else
				if params.pos_number == 0 then   -- ���� � �������
					if open_long then
						trans_id, trans_msg = SendMarketOrder("B")
						candle_long_num = ds_num
					elseif 	open_short then
						trans_id, trans_msg = SendMarketOrder("S")
						candle_short_num = ds_num
					else
					
					end
				elseif params.pos_number >= conf.trade_lots then -- ����� �� �����
					if close_long then
						trans_id, trans_msg = SendMarketOrder("S", abs_pos_number)
					else

					end
				elseif params.pos_number <= -conf.trade_lots then --����� �� �����
					if close_short then
						trans_id, trans_msg = SendMarketOrder("B", abs_pos_number)
					else 
					
					end	
				end
			end
			
		end

		sleep(1000)            -- ������������ ���� � ��������� 1���.
    end
end 
