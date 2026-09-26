const src = require("@src")
const test = require("@std/test")

test.suite("sandbox", function(suite)
	suite:case("config files cannot reach host globals", function(asserts)
		const conf = src.new(function()
			return {}
		end, {})

		const res = conf:run("tests/samples/sandbox_escape.luau")

		if not res.ok and res.status == "config_file_err" then
			const _, err = coroutine.close(res.thread)
			asserts.that(false, tostring(err))
		end
		asserts.that(res.ok)
	end)
end)
