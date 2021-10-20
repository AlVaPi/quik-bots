dofile(getScriptPath() .. "\\lib.lua");

-- присванивание переменным начальных базовых значений торгового алгоритма
conf = {
	account="A717yt9",
	class_code="SPBFUT",
	sec_code="SFU1",
	timeframe=5,
	test_mode=true,
	tag_bulls="bulls_bot5",
	tag_bears="bears_bot5",
	tag_bb="bb_bot5",
	trade_lots=1,
	trade_max=1,
	profit=2,
	lost=200,
	sar_diff = 0.5,
	power_high=0.5,
	power_low=-0.5
}
params_path = getScriptPath()..'\\bot5.params'

dofile(getScriptPath() .. "\\main.lua");