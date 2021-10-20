-- ������������� ���������� ��������� ������� �������� ��������� ���������
conf = {
	account="A717yt9",
	class_code="SPBFUT",
	sec_code="RIU1",
	timeframe=30,
	test_mode=true,
	tag_price="price_bot1",
	tag_rsi="rsi_bot1",
	tag_bb="bb_bot1",
	tag_sar="sar_bot1",
	tag_bulls="bulls_bot1",
	tag_bears="bears_bot1",
	trade_lots=1,
	trade_max=1,
	profit=5000,
	lost=1000,
	sar_diff = 250,
	power_high=200,
	power_low=-200,
	trade_start=100100,
	trade_stop=210000		
}
params_path = getScriptPath()..'\\bot1.params'
dofile(getScriptPath() .. "\\qtable.lua");
dofile(getScriptPath() .. "\\graphics.lua");
dofile(getScriptPath() .. "\\lib.lua");
dofile(getScriptPath() .. "\\func.lua");
dofile(getScriptPath() .. "\\rsi.lua");