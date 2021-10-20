dofile(getScriptPath() .. "\\lib.lua")


function OnStop(s)
	
	stopped = true
end

function main()

	-- исполнять цикл, пока пользователь не остановит скрипт из диалога управления
	while not stopped do 
		-- если таблица закрыта, то показать ее заново
		-- при этом все предыдущие данные очищаются
os.execute ('cmd')
	end





end

