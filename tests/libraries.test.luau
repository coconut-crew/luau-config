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

test.suite("libraries", function(suite)
	suite:case("library return values reach the config", function(asserts)
		const conf = src.new(empty_ctx, {})
		conf:add_library("api", {
			double = function(_ctx: {}, n: unknown)
				return (n :: number) * 2
			end,
		})

		const res = conf:run("tests/samples/lib_return.luau")

		if not res.ok and res.status == "config_file_err" then
			const _, err = coroutine.close(res.thread)
			asserts.that(false, tostring(err))
		end
		asserts.that(res.ok)
	end)

	suite:case("each run binds libraries to its own ctx", function(asserts)
		type Ctx = { api_call_count: number }

		const conf = src.new<<Ctx>>(function()
			return { api_call_count = 0 }
		end, {})

		conf:add_library("api", {
			increment = function(ctx: Ctx)
				ctx.api_call_count += 1
			end,
			decrement = function(ctx: Ctx)
				ctx.api_call_count -= 1
			end,
		})

		const first = conf:run("tests/samples/lib_usage.luau")
		const second = conf:run("tests/samples/lib_usage.luau")

		assert(first.ok and second.ok)
		asserts.eq(first.ctx.api_call_count, 1)
		asserts.eq(second.ctx.api_call_count, 1)
	end)

	suite:case("a config that yields is not reported as finished", function(asserts)
		type Ctx = { finished: boolean }

		const conf = src.new<<Ctx>>(function()
			return { finished = false }
		end, {})

		conf:add_library("api", {
			wait = function(_ctx: Ctx)
				coroutine.yield()
			end,
			finish = function(ctx: Ctx)
				ctx.finished = true
			end,
		})

		const res = conf:run("tests/samples/lib_yield.luau")

		asserts.that(not res.ok or res.ctx.finished, "run returned ok before the config finished executing")
	end)

	suite:case("requiring an unregistered library fails the config", function(asserts)
		const conf = src.new(empty_ctx, {})

		const res = conf:run("tests/samples/require_unknown.luau")

		assert(not res.ok)
		asserts.eq(res.status, "config_file_err")
	end)
end)
