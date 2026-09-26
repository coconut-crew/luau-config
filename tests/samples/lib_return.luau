const api = require("@api")

if api.double(1) ~= 2 then
	error("library return value did not reach the config")
end
