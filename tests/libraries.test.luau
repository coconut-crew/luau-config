const src = require("@src")
const pretty_print = require("@src/utils/pretty_print")
const fs = require("@std/fs")
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

		const lib = src.library<<Test1Ctx>>("counter")

		lib:add_function("increment", "(amount: number) -> number", function(ctx: Test1Ctx, amount)
			assert(type(amount) == "number", `first argument expected to be a number, got {type(amount)}`)

			ctx.api_call_count += amount
		end)

		conf:add_library(lib)

		const res = conf:run("tests/samples/lib_usage.luau")

		asserts.that(res.ok)

		assert(res.ok)
		asserts.that(res.ctx.api_call_count == 1)
	end)

	suite:case("definition file writing works", function(asserts)
		type Test1Ctx = { api_call_count: number }

		const conf = src.new<<Test1Ctx>>(function()
			return {
				api_call_count = 0,
			}
		end, {})

		const lib = src.library<<Test1Ctx>>("counter")

		lib:add_function("increment", "(amount: number) -> number", function(ctx: Test1Ctx, amount)
			assert(type(amount) == "number", `first argument expected to be a number, got {type(amount)}`)

			ctx.api_call_count += amount
		end)

		conf:add_library(lib)

		if not fs.exists("tests/tmp") then
			fs.createDirectory("tests/tmp")
		end

		lib:write_interface(path.parse("tests/tmp/counter.luau"))
	end)
end)
