dofile(getScriptPath() .. "\\lib.lua");

-- ������������� ���������� ��������� ������� �������� ��������� ���������
config_path = getScriptPath()..'\\bb.conf'
conf = TabRead(config_path)
if conf == nil then
  conf = {}
  conf.account = "A717yt9"     -- �������� ����
  conf.class_code = "SPBFUT"         -- ����� ���������� �����������
  conf.sec_code = "SiM1"            -- ��� ���������� �����������
  conf.timeframe = INTERVAL_M1             -- �������� ���������
  conf.trade_lots = 1                   -- ���������� ��������� ���
  conf.tag_bb = "graf_bb_bot"       -- ��� ������� BB
  conf.last_price_buy = 0          -- ��������� ���� �������
  conf.last_price_sell = 100000         -- ��������� ���� �������
  TabSave (conf, config_path)
end
last_trade_num = 0
function OnInit(script)              
  is_run = true
	ds = CreateDataSource(conf.class_code, conf.sec_code, conf.timeframe)  -- ������������� �� ��������� ������ ������ �� ����������� � ������ ds

end

function OnStop()              
     is_run = false
     ds:Close() 
end

function OnTrade(trade)
    -- ���� ����� ���������� ������ �� �� ����� ������ ��������
    if last_trade_num < trade.trade_num then
        -- �������� ����� ���������� ������
        last_trade_num = trade.trade_num;
        -- ���� ������ �� ������� � ���������
        if bit_set(trade.flags, 0) == false and bit_set(trade.flags, 1) == false then
          if bit_set(trade.flags, 2) == true then
            conf.last_price_sell = trade.price
            TabSave (conf, config_path)
          else 
            conf.last_price_buy = trade.price
            TabSave (conf, config_path)
          end
        end
    end
end

function main()
	while is_run do
    local serv_time = tonumber(timeformat(getInfoParam("SERVERTIME"))) -- �������� � ���������� ������� ������� � ������� HHMMSS                  
    if isConnected()==1 and serv_time>=10000 and serv_time<235000 then -- �������� ������� ���������� � �������� � ��������� � �������� ����
			ds:SetEmptyCallback()  -- ��������� ������ �� ����������� � ������� ds 
			local ds_num = ds:Size()
			local bb_candles = getNumCandles(conf.tag_bb)
			local bb_1, bb_1_num, bb_1_legend = getCandlesByIndex(conf.tag_bb, 1, 0, bb_candles)
			local bb_2, bb_2_num, bb_2_legend = getCandlesByIndex(conf.tag_bb, 2, 0, bb_candles)
			local carrent_price = ds:C(ds_num)
			local trans_price_buy = carrent_price 
			local trans_price_sell = carrent_price 
-- ����� ��� ���������� �������� ������
			if carrent_price < bb_2[bb_2_num-1].close and carrent_price < conf.last_price_sell then
				send_order("B", conf.trade_lots, trans_price_buy)
				sleep(60000)
			end
			if carrent_price > bb_1[bb_1_num-1].close and carrent_price > conf.last_price_buy then
				send_order("S", conf.trade_lots, trans_price_sell)
				sleep(60000)
			end
      
    end
		   
		sleep(1001)            -- ������������ ���� � ��������� 1���.
    end
end 

-- ������� ���������� ���������� ��� � ���������� �������� �� ��������� �����������
function get_lots()
    local lots = 0
    local n = getNumberOf("futures_client_holding")
    local futures_client_holding={}                    
    for i=0,n-1 do             
       futures_client_holding = getItem("futures_client_holding", i)
       if tostring(futures_client_holding["sec_code"])==conf.sec_code then
          lots=tonumber(futures_client_holding["totalnet"])
       end
    end      
    return lots
end
----------------------

-- �������� ����������
function send_order(operation, quantity, price)       
    -- ��������� ������������ ���� ���� ��� ���������� ���� ������������� ������
    local step=tonumber(getParamEx(conf.class_code, conf.sec_code, "SEC_PRICE_STEP").param_value)
    local trans_params = 
          {
            CLIENT_CODE = conf.account,
            CLASSCODE = conf.class_code,
            SECCODE = conf.sec_code,
            ACCOUNT = conf.account,
            TYPE = "M",
            TRANS_ID = tostring(os.time()),
			EXECUTION_CONDITION = "PUT_IN_QUEUE",
            OPERATION = tostring(operation),
            QUANTITY = tostring(math.abs(quantity)),
            PRICE = string.format("%i",0),
            ACTION = "NEW_ORDER",
			COMMENT = "BB_bot"
          }
   local result = sendTransaction(trans_params)
--	message('����������: '..trans_params.TRANS_ID..'   '..trans_params.OPERATION..' ����: '.. trans_params.PRICE,3)
   if string.len(result) ~= "" then
       message('Error: '..result,3)
       return nil, result
   else
       return trans_id
   end      
end


