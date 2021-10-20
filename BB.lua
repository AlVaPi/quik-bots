-- ������������� ���������� ��������� ������� �������� ��������� ���������

Account = "A717yt9"     -- �������� ����
Class_Code = "SPBFUT"         -- ����� ���������� �����������
Sec_Code = "SiM1"            -- ��� ���������� �����������
TF = INTERVAL_M1             -- �������� ���������
g_lots = 1                   -- ���������� ��������� ���

function OnInit(script)              
    is_run = true
-- ������������� �� ��������� ������ ������ �� ����������� � ������ ds
	ds = CreateDataSource(Class_Code, Sec_Code, TF)
end

function OnStop()              
     is_run = false
     ds:Close() 
end


function main()
	
    while is_run do
 
        ds:SetEmptyCallback()  -- ��������� ������ �� ����������� � ������� ds
        local serv_time=tonumber(timeformat(getInfoParam("SERVERTIME"))) -- �������� � ���������� ������� ������� � ������� HHMMSS                  
        if isConnected()==1 and serv_time>=10000 and serv_time<235000 then -- �������� ������� ���������� � �������� � ��������� � �������� ����
             -- ����� ��� ���������� �������� ������
             -- ������ �������� ���������� �������
             local SMA = 0
             local period = 20
             local count_candle = ds:Size()
             if count_candle>20 then
                local sum = 0
                for i=0 , period-1 do                                                  
                    sum = sum + ds:C(count_candle-i)
                end
                SMA = sum / period
                local lots = get_lots()             

                -- ��������� ���������� ��� � ���������� �������� �� �����������
                if ds:C(count_candle)>SMA and lots<g_lots then
                    -- ��������� ������������ ���� ���� ��� ����������� �������� �������������� � ������
                    local step=tonumber(getParamEx(Class_Code, Sec_Code, "SEC_PRICE_STEP").param_value)
                    local price_order = ds:C(count_candle)+(step*20)
                    -- ���� ��� ������ ����� = ���� �������� + 20-�� ����������� ����� ����.
                    send_order("B", math.abs(g_lots-lots) , price_order)
                end
                if ds:C(count_candle)<SMA and lots>(g_lots*(-1)) then
                    -- ��������� ������������ ���� ���� ��� ����������� �������� �������������� � ������
                    local step=tonumber(getParamEx(Class_Code, Sec_Code, "SEC_PRICE_STEP").param_value)
                    local price_order = ds:C(count_candle)-(step*20)    
                    -- ���� ��� ������ ����� = ���� �������� - 20-�� ����������� ����� ����.
                    send_order("S", math.abs(g_lots+lots) , price_order)
                end
             end                  
        end
		   
		sleep(1000)            -- ������������ ���� � ��������� 1���.
    end
end 

-- ������� ���������� ���������� ��� � ���������� �������� �� ��������� �����������
function get_lots()
    local lots = 0
    local n = getNumberOf("futures_client_holding")
    local futures_client_holding={}                    
    for i=0,n-1 do             
       futures_client_holding = getItem("futures_client_holding", i)
       if tostring(futures_client_holding["sec_code"])==Sec_Code then
          lots=tonumber(futures_client_holding["totalnet"])
       end
    end      
    return lots
end
----------------------

-- �������� ����������
function send_order(operation, quantity, price)       
    -- ��������� ������������ ���� ���� ��� ���������� ���� ������������� ������
    local step=tonumber(getParamEx(Class_Code, Sec_Code, "SEC_PRICE_STEP").param_value)
    local trans_params = 
          {
            CLIENT_CODE = Account,
            CLASSCODE = Class_Code,
            SECCODE = Sec_Code,
            ACCOUNT = Account,
            TYPE = "L",
            TRANS_ID = tostring(1),
            OPERATION = tostring(operation),
            QUANTITY = tostring(math.abs(quantity)),
            PRICE = tostring(math.floor(tonumber(price)/step)*step),  -- ���������� ���� ��� ����������� ����������
            ACTION = "NEW_ORDER" 
          }
--    local res = sendTransaction(trans_params)
	message('����������: '..trans_params.TRANS_ID..'   '..trans_params.OPERATION..' ����: '.. trans_params.PRICE,3)
 --   if string.len(res) ~= 0 then
 --       message('Error: '..res,3)
 --       return 0
 --   else
 --       return trans_id
 --   end      
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