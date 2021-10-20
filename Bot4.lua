
-- присванивание переменным начальных базовых значений торгового алгоритма
conf = {
	account="A717yt9",
	class_code="SPBFUT",
	sec_code="SiU1",
	timeframe=30,
	test_mode=false,
	tag_price="price_bot4",
	tag_bb="bb_bot4",
	tag_haclose="haclose_bot4",
	tag_rsi="rsi_bot4",
	table_caption = "Bot4 (bb_sma)",
	table_caption_test = "Bot4 (bb_sma) TEST MODE",
	trade_lots=9,
	trade_max=9,
	profit=500,
	lost=500,
	sar_diff = 30,
	power_high=50,
	power_low=-50,
	trade_start=100100,
	trade_stop=210000
}
params_path = getScriptPath().."\\bot4.params"
dofile(getScriptPath() .. "\\qtable.lua");
dofile(getScriptPath() .. "\\graphics.lua");
dofile(getScriptPath() .. "\\lib.lua");
dofile(getScriptPath() .. "\\func.lua");
dofile(getScriptPath() .. "\\bb_sma.lua");