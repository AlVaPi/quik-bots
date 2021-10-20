--[[
Graphics functions
]]
function isChartExist(chart_name)
	-- возвращает true, если график с идентификатором chart_name сущестует иначе false
	if chart_name==nil or chart_name=='' then return false end
	local n=getNumCandles(chart_name)
	if n==nil or n<1 then return false end
	return true
end
function getCandle(chart_name,bar,line)
	-- возвращает свечу со сдвигом bar от последней существующей для графика с идентификатором chart_name
	-- параметр line не обязательный (по умолчанию 0)
	-- параметр bar не обязательный (по умолчанию 0)
	-- возвращает таблицу Луа с запришиваемой свечей или nil и сообщение с диагностикой
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
	-- возвращает пред-последнюю свечу для графика с идентификатором chart_name
	-- параметр line не обязательный (по умолчанию 0)
	-- возвращает таблицу Луа с запришиваемой свечей или nil и сообщение с диагностикой
	if not isChartExist(chart_name) then return nil,'Chart doesn`t exist' end
	local n=getNumCandles(chart_name)
	return getCandle(chart_name,1,line)
end
function getLastCandle(chart_name,line)
	-- возвращает последнюю свечу для графика с идентификатором chart_name
	-- параметр line не обязательный (по умолчанию 0)
	-- возвращает таблицу Луа с запришиваемой свечей или nil и сообщение с диагностикой
	return getCandle(chart_name,nil,line)
end
--[[
Commmon Trading Signals
]]

function CrossOver(bar,chart_name1,val2,parameter,line1,line2)
	-- Возвращает true если график с идентификатором chart_name1 пересек снизу вверх график (или значение) val2 в баре со смещением bar.
	-- параметры parameter,line1,line2 необязательны. По умолчания равны close,0,0 соответственно
	-- вторым параметром возвращается точка пересечения (цена)
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
	-- Возвращает true если график с идентификатором chart_name1 пересек сверху вниз  график (или значение) val2 в баре bar.
	-- параметры parameter,line1,line2 необязательны. По умолчания равны close,0,0 соответственно
	-- вторым параметром возвращается точка пересечения (цена), если есть пересечение
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
	-- Возвращает true если график с идентификатором chart_name "развернулся вниз". Т.е. значение графика в баре bar меньше значения в баре bar-1.
	-- параметры parameter,line необязательны. По умолчания равны close,0 соответственно
	if bar==nil or chart_name==nil then return false,'Bad parameters' end
	local candle1l,candle1p=getCandle(chart_name,bar,line),getCandle(chart_name,bar+1,line)
	if candle1l==nil or candle1p==nil then return false,'Eror on getting candles for '..chart_name end
	local par=parameter or "close"
	if candle1l[par]<candle1p[par] then return true else return false end
end
function TrendUp(bar,chart_name,parameter,line)
	-- Возвращает true если график с идентификатором chart_name "развернулся вверх". Т.е. значение графика в баре bar больше значения в баре bar-1.
	-- параметры parameter,line необязательны. По умолчания равны close,0 соответственно
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
	-- Возвращает среднее арифметическое number свечей до bar свечи
	-- параметры parameter,line,number необязательны. По умолчанию равны close,0,2 соответственно
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
	-- Возвращает минимум, максимум и среднее number свечей до bar свечи
	-- параметры parameter,line,number необязательны. По умолчанию равны close,0,2 соответственно
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
	-- Внимание, название всех параметров должны писаться большими буквами
	label_params = {
		-- Если подпись не требуется то оставить строку пустой ""
		TEXT = text or "",
		-- Расположение картинки относительно текста (возможно 4 варианта: LEFT, RIGHT, TOP, BOTTOM)
		ALIGNMENT = "LEFT",
		-- Значение параметра на оси Y, к которому будет привязана метка
		YVALUE = price,
		-- Дата в формате «ГГГГММДД», к которой привязана метка
		DATE = date_pos or os.date("%Y%m%d"),
		-- Время в формате «ЧЧММСС», к которому будет привязана метка
		TIME = time_pos or os.date("%H%M%S",os.time()),
		-- Красная компонента цвета в формате RGB. Число в интервале [0;255]
		R = 100,
		-- Зеленая компонента цвета в формате RGB. Число в интервале [0;255]
		G = 200,
		-- Синяя компонента цвета в формате RGB. Число в интервале [0;255]
		B = 80,
		-- Прозрачность метки в процентах. Значение должно быть в промежутке [0; 100]
		TRANSPARENCY = 0,
		-- Прозрачность фона картинки. Возможные значения: «0» – прозрачность отключена, «1» – прозрачность включена
		TRANSPARENT_BACKGROUND = 1,
		-- Название шрифта (например «Arial»)
		FONT_FACE_NAME = "Arial",
		-- Размер шрифта
		FONT_HEIGHT = 12,
		-- Текст всплывающей подсказки
		HINT = name.." по цене "..price
	}
	if name == "open long" or name == "trend up" then
		label_params.IMAGE_PATH = getScriptPath() .. "\\images\\buy.bmp"
	elseif name == "open short" or name == "trend down"  then
		label_params.IMAGE_PATH = getScriptPath() .. "\\images\\sell.bmp"
		
	end
	-- Добавляем метку и запоминаем ее ID
	label_id = AddLabel(chart_tag, label_params)
end