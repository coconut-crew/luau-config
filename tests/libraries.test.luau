const src = require("@src")
const path = require("@std/path")
const test = require("@std/test")

const function empty_ctx()
	return {}
end

test.suite("basic usage", function(suite)
	suite:case("construction works", function(asserts)
		type Test1Ctx = { api_call_count: number }

		const conf = src.new<<Test1Ctx>>(function()
			return {
				api_call_count = 0,
			}
		end, {})

		conf:add_library("api", {
			increment = function(ctx: Test1Ctx)
				ctx.api_call_count += 1
			end,

			decrement = function(ctx: Test1Ctx)
				ctx.api_call_count -= 1
			end,
		})

		const res = conf:run("tests/samples/lib_usage.luau")

		asserts.that(res.ok)
		assert(res.ok)
		asserts.that(res.ctx.api_call_count == 1)
	end)
end)
