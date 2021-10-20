-- присванивание переменным начальных базовых значений торгового алгоритма
conf = {
	account="A717yt9",
	class_code="SPBFUT",
	sec_code="BRV1",
	timeframe=30,
	test_mode=false,
	tag_price="price_bot3",
	tag_bb="bb_bot3",
	tag_haclose="haclose_bot3",
	tag_sar="sar_bot3",
	tag_mfi="mfi_bot3",
	tag_rsi="rsi_bot3",
	tag_bulls="bulls_bot3",
	tag_bears="bears_bot3",
	table_caption = "Bot3 (bb_sma)",
	table_caption_test = "Bot3 (bb_sma) TEST MODE",
	trade_lots=1,
	trade_max=1,
	profit=5,
	lost=1000,
	sar_diff = 0.2,
	power_high=200,
	power_low=-200,
	trade_start=100100,
	trade_stop=210000	
}
params_path = getScriptPath().."\\bot3.params"
dofile(getScriptPath() .. "\\qtable.lua");
dofile(getScriptPath() .. "\\graphics.lua");
dofile(getScriptPath() .. "\\lib.lua");
dofile(getScriptPath() .. "\\func.lua");
dofile(getScriptPath() .. "\\bb_sma.lua");