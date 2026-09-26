const nil_table: any = {
	_G = _G,
	getfenv = getfenv,
	setfenv = setfenv,
	loadstring = loadstring,
	setmetatable = setmetatable,
	getmetatable = getmetatable,
	rawset = rawset,
	debug = debug,
	coroutine = coroutine,
	os = os,
}

for name, value in nil_table do
	if value ~= nil then
		error(`{name} exists`)
	end
end
