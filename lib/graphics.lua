--[[
Graphics functions
]]
function isChartExist(chart_name)
	-- âîçâðàùàåò true, åñëè ãðàôèê ñ èäåíòèôèêàòîðîì chart_name ñóùåñòóåò èíà÷å false
	if chart_name==nil or chart_name=='' then return false end
	local n=getNumCandles(chart_name)
	if n==nil or n<1 then return false end
	return true
end
function getCandle(chart_name,bar,line)
	-- âîçâðàùàåò ñâå÷ó ñî ñäâèãîì bar îò ïîñëåäíåé ñóùåñòâóþùåé äëÿ ãðàôèêà ñ èäåíòèôèêàòîðîì chart_name
	-- ïàðàìåòð line íå îáÿçàòåëüíûé (ïî óìîë÷àíèþ 0)
	-- ïàðàìåòð bar íå îáÿçàòåëüíûé (ïî óìîë÷àíèþ 0)
	-- âîçâðàùàåò òàáëèöó Ëóà ñ çàïðèøèâàåìîé ñâå÷åé èëè nil è ñîîáùåíèå ñ äèàãíîñòèêîé
	if not isChartExist(chart_name) then return nil,'Chart doesn`t exist' end
	local n=getNumCandles(chart_name)
	local lline=0
	local lbar=n-1
	if line~=nil then lline=tonumber(line) end
	if bar~=nil then lbar=lbar-tonumber(bar) end
	if lbar>n or lbar<1 then return nil,'Spacified bar='..bar..' doesn`t exist' end
	local t,n,p=getCandlesByIndex(chart_name,lline,lbar,1)
	if t~=nil and n>=1 and t[0]~=nil and t[0].doesExist==1 then return t[0] else return nil,'Error gettind Candles from '..chart_name end
end
function getPrevCandle(chart_name,line)
	-- âîçâðàùàåò ïðåä-ïîñëåäíþþ ñâå÷ó äëÿ ãðàôèêà ñ èäåíòèôèêàòîðîì chart_name
	-- ïàðàìåòð line íå îáÿçàòåëüíûé (ïî óìîë÷àíèþ 0)
	-- âîçâðàùàåò òàáëèöó Ëóà ñ çàïðèøèâàåìîé ñâå÷åé èëè nil è ñîîáùåíèå ñ äèàãíîñòèêîé
	if not isChartExist(chart_name) then return nil,'Chart doesn`t exist' end
	local n=getNumCandles(chart_name)
	return getCandle(chart_name,1,line)
end
function getLastCandle(chart_name,line)
	-- âîçâðàùàåò ïîñëåäíþþ ñâå÷ó äëÿ ãðàôèêà ñ èäåíòèôèêàòîðîì chart_name
	-- ïàðàìåòð line íå îáÿçàòåëüíûé (ïî óìîë÷àíèþ 0)
	-- âîçâðàùàåò òàáëèöó Ëóà ñ çàïðèøèâàåìîé ñâå÷åé èëè nil è ñîîáùåíèå ñ äèàãíîñòèêîé
	return getCandle(chart_name,nil,line)
end
--[[
Commmon Trading Signals
]]

function CrossOver(bar,chart_name1,val2,parameter,line1,line2)
	-- Âîçâðàùàåò true åñëè ãðàôèê ñ èäåíòèôèêàòîðîì chart_name1 ïåðåñåê ñíèçó ââåðõ ãðàôèê (èëè çíà÷åíèå) val2 â áàðå ñî ñìåùåíèåì bar.
	-- ïàðàìåòðû parameter,line1,line2 íåîáÿçàòåëüíû. Ïî óìîë÷àíèÿ ðàâíû close,0,0 ñîîòâåòñòâåííî
	-- âòîðûì ïàðàìåòðîì âîçâðàùàåòñÿ òî÷êà ïåðåñå÷åíèÿ (öåíà)
	if bar==nil or chart_name1==nil or val2==nil then return false,'Bad parameters' end
	local candle1l=getCandle(chart_name1,bar,line1)
	local candle1p=getCandle(chart_name1,bar+1,line1)
	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name1 end
	local par=parameter or 'close'
	--toLog(log,'par='..par)
	if type(val2)=='string' then
		local candle2l=getCandle(val2,bar,line2)
		local candle2p=getCandle(val2,bar+1,line2)
		if candle2l==nil or candle2p==nil then return false,'Eror on getting candles for '..val2 end
		if candle1l[par]>candle2l[par] and candle1p[par]<=candle2p[par] then
			local p=(candle2p[par]*(candle1l[par]-candle1p[par])-candle1p[par]*(candle2l[par]-candle2p[par]))/((candle1l[par]-candle1p[par])-(candle2l[par]-candle2p[par]))
			return true,tonumber(p)
		else return false 
		end
	elseif type(val2)=='number' then
		if candle1l[par]>val2 and candle1p[par]<=val2 then return true else return false end
	else
		return false,'Unsupported type for 3rd parameter'
	end
end
function CrossUnder(bar,chart_name1,val2,parameter,line1,line2)
	-- Âîçâðàùàåò true åñëè ãðàôèê ñ èäåíòèôèêàòîðîì chart_name1 ïåðåñåê ñâåðõó âíèç  ãðàôèê (èëè çíà÷åíèå) val2 â áàðå bar.
	-- ïàðàìåòðû parameter,line1,line2 íåîáÿçàòåëüíû. Ïî óìîë÷àíèÿ ðàâíû close,0,0 ñîîòâåòñòâåííî
	-- âòîðûì ïàðàìåòðîì âîçâðàùàåòñÿ òî÷êà ïåðåñå÷åíèÿ (öåíà), åñëè åñòü ïåðåñå÷åíèå
	if bar==nil or chart_name1==nil or val2==nil then return false,'Bad parameters' end
	local candle1l=getCandle(chart_name1,bar,line1)
	local candle1p=getCandle(chart_name1,bar+1,line1)
	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name1 end
	local par=parameter or 'close'
	if type(val2)=='string' then
		local candle2l=getCandle(val2,bar,line2)
		local candle2p=getCandle(val2,bar+1,line2)
		if candle2l==nil or candle2p==nil then return false,'Eror on getting candles for '..val2 end
		if candle1l[par]<candle2l[par] and candle1p[par]>=candle2p[par] then
			local p=(candle2p[par]*(candle1l[par]-candle1p[par])-candle1p[par]*(candle2l[par]-candle2p[par]))/((candle1l[par]-candle1p[par])-(candle2l[par]-candle2p[par]))
			--toLog(Log,'-----')
			--toLog(Log,candle2l)
			--toLog(Log,'-----')
			--toLog(Log,candle2p)

			return true,tonumber(p)
		else return false end
	elseif type(val2)=='number' then
		if candle1l[par]<val2 and candle1p[par]>=val2 then return true else return false end
	else
		return false,'Unsupported type for 3rd parameter'
	end
end
function TrendDown(bar,chart_name,parameter,line)
	-- Âîçâðàùàåò true åñëè ãðàôèê ñ èäåíòèôèêàòîðîì chart_name "ðàçâåðíóëñÿ âíèç". Ò.å. çíà÷åíèå ãðàôèêà â áàðå bar ìåíüøå çíà÷åíèÿ â áàðå bar-1.
	-- ïàðàìåòðû parameter,line íåîáÿçàòåëüíû. Ïî óìîë÷àíèÿ ðàâíû close,0 ñîîòâåòñòâåííî
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
	local candle1l,candle1p=getCandle(chart_name,bar,line),getCandle(chart_name,bar+1,line)
	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name end
	local par=parameter or "close"
	if candle1l[par]<candle1p[par] then return true else return false end
end
function TrendUp(bar,chart_name,parameter,line)
	-- Âîçâðàùàåò true åñëè ãðàôèê ñ èäåíòèôèêàòîðîì chart_name "ðàçâåðíóëñÿ ââåðõ". Ò.å. çíà÷åíèå ãðàôèêà â áàðå bar áîëüøå çíà÷åíèÿ â áàðå bar-1.
	-- ïàðàìåòðû parameter,line íåîáÿçàòåëüíû. Ïî óìîë÷àíèÿ ðàâíû close,0 ñîîòâåòñòâåííî
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
	local candle1l,candle1p=getCandle(chart_name,bar,line),getCandle(chart_name,bar+1,line)
	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name end
	local par=parameter or "close"
	if candle1l[par]>candle1p[par] then return true else return false end
end
function CandleUp(chart_name,bar,line)
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
	local candle = getCandle(chart_name,bar,line)
	if candle["close"] > candle["open"] then
		return true
	else
		return false
	end
end
function CandleDown(chart_name,bar,line)
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
	local candle = getCandle(chart_name,bar,line)
	if candle["close"] < candle["open"] then
		return true
	else
		return false
	end
end
function CandleDiff(chart_name,bar,line)
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
	local candle = getCandle(chart_name,bar,line)
	return candle["close"] - candle["open"] 
end
function Average(bar,chart_name,number,parameter,line)
	-- Âîçâðàùàåò ñðåäíåå àðèôìåòè÷åñêîå number ñâå÷åé äî bar ñâå÷è
	-- ïàðàìåòðû parameter,line,number íåîáÿçàòåëüíû. Ïî óìîë÷àíèþ ðàâíû close,0,2 ñîîòâåòñòâåííî
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
--	local candle1l,candle1p=getCandle(chart_name,bar,line),getCandle(chart_name,bar+1,line)
--	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name end
	local par=parameter or "close"
	local num=number or 2
	if num < 2 then return false,'Bad number' end
	local sum = 0
	for i = bar, bar+num-1, 1 do
		local candle =getCandle(chart_name,i,line)
		sum = sum + candle[par]
	end
	local aver = sum / num
	return aver
end
function MinMax(bar,chart_name,number,parameter,line)
	-- Âîçâðàùàåò ìèíèìóì, ìàêñèìóì è ñðåäíåå number ñâå÷åé äî bar ñâå÷è
	-- ïàðàìåòðû parameter,line,number íåîáÿçàòåëüíû. Ïî óìîë÷àíèþ ðàâíû close,0,2 ñîîòâåòñòâåííî
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
--	local candle1l,candle1p=getCandle(chart_name,bar,line),getCandle(chart_name,bar+1,line)
--	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name end
	local par=parameter or "close"
	local num=number or 2
	if num < 2 then return false,'Bad number' end
	local sum = 0
	local minimum = 0
	local maximum = 0
	for i = bar, bar+num-1, 1 do
		local candle =getCandle(chart_name,i,line)
		sum = sum + candle[par]
		if candle[par] > maximum or maximum == 0 then
			maximum = candle[par]
		end
		if candle[par] < minimum or minimum == 0 then
			minimum = candle[par]
		end		
	end
	local aver = sum / num
	return minimum, maximum, aver
end

function PlaceLabel(chart_tag, price, name, text, date_pos, time_pos)
	-- Âíèìàíèå, íàçâàíèå âñåõ ïàðàìåòðîâ äîëæíû ïèñàòüñÿ áîëüøèìè áóêâàìè
	label_params = {
		-- Åñëè ïîäïèñü íå òðåáóåòñÿ òî îñòàâèòü ñòðîêó ïóñòîé ""
		TEXT = text or "",
		-- Ðàñïîëîæåíèå êàðòèíêè îòíîñèòåëüíî òåêñòà (âîçìîæíî 4 âàðèàíòà: LEFT, RIGHT, TOP, BOTTOM)
		ALIGNMENT = "LEFT",
		-- Çíà÷åíèå ïàðàìåòðà íà îñè Y, ê êîòîðîìó áóäåò ïðèâÿçàíà ìåòêà
		YVALUE = price,
		-- Äàòà â ôîðìàòå «ÃÃÃÃÌÌÄÄ», ê êîòîðîé ïðèâÿçàíà ìåòêà
		DATE = date_pos or os.date("%Y%m%d"),
		-- Âðåìÿ â ôîðìàòå «××ÌÌÑÑ», ê êîòîðîìó áóäåò ïðèâÿçàíà ìåòêà
		TIME = time_pos or os.date("%H%M%S",os.time()),
		-- Êðàñíàÿ êîìïîíåíòà öâåòà â ôîðìàòå RGB. ×èñëî â èíòåðâàëå [0;255]
		R = 100,
		-- Çåëåíàÿ êîìïîíåíòà öâåòà â ôîðìàòå RGB. ×èñëî â èíòåðâàëå [0;255]
		G = 200,
		-- Ñèíÿÿ êîìïîíåíòà öâåòà â ôîðìàòå RGB. ×èñëî â èíòåðâàëå [0;255]
		B = 80,
		-- Ïðîçðà÷íîñòü ìåòêè â ïðîöåíòàõ. Çíà÷åíèå äîëæíî áûòü â ïðîìåæóòêå [0; 100]
		TRANSPARENCY = 0,
		-- Ïðîçðà÷íîñòü ôîíà êàðòèíêè. Âîçìîæíûå çíà÷åíèÿ: «0»  ïðîçðà÷íîñòü îòêëþ÷åíà, «1»  ïðîçðà÷íîñòü âêëþ÷åíà
		TRANSPARENT_BACKGROUND = 1,
		-- Íàçâàíèå øðèôòà (íàïðèìåð «Arial»)
		FONT_FACE_NAME = "Arial",
		-- Ðàçìåð øðèôòà
		FONT_HEIGHT = 12,
		-- Òåêñò âñïëûâàþùåé ïîäñêàçêè
		HINT = name.." ïî öåíå "..price
	}
	if name == "open long" or name == "trend up" then
		label_params.IMAGE_PATH = getScriptPath() .. "\\images\\buy.bmp"
	elseif name == "open short" or name == "trend down"  then
		label_params.IMAGE_PATH = getScriptPath() .. "\\images\\sell.bmp"
		
	end
	-- Äîáàâëÿåì ìåòêó è çàïîìèíàåì åå ID
	label_id = AddLabel(chart_tag, label_params)
end
