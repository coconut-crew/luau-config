const path = require("@std/path")
const src = require("@src")
const test = require("@std/test")

const function empty_ctx()
	return {}
end

test.suite("error_handling", function(suite)
	suite:case("a runtime error returns the dead thread", function(asserts)
		const conf = src.new(empty_ctx, {})

		const res = conf:run("tests/samples/runtime_error.luau")

		assert(not res.ok)
		asserts.eq(res.status, "config_file_err")
		assert(res.status == "config_file_err")
		asserts.that(res.thread)
	end)

	suite:case("thread is the correct stack trace", function(asserts)
		const conf = src.new(empty_ctx, {})

		const res = conf:run("tests/samples/runtime_error.luau")

		assert((res.ok == false) and res.status == "config_file_err")

		asserts.strContains(debug.traceback(res.thread), "runtime_error")
	end)

	suite:case("a syntax error returns a compilation error", function(asserts)
		const conf = src.new(empty_ctx, {})

		const res = conf:run("tests/samples/syntax_error.luau")

		assert(not res.ok)
		asserts.eq(res.status, "compilation_err")
		assert(res.status == "compilation_err")
	end)

	suite:case("a missing file returns a file access error", function(asserts)
		const conf = src.new(empty_ctx, {})

		const res = conf:run("tests/samples/does_not_exist.luau")

		assert(not res.ok)
		asserts.eq(res.status, "file_access_err")
		assert(res.status == "file_access_err")
		asserts.strContains(res.msg, "does_not_exist.luau")
	end)

	suite:case("an error while building the ctx returns a ctx constructor error", function(asserts)
		const conf = src.new(function(): {}
			error("ctx failed")
		end, {})

		const res = conf:run("tests/samples/empty.luau")

		assert(not res.ok)
		asserts.eq(res.status, "ctx_constructor_err")
		assert(res.status == "ctx_constructor_err")
		const _, err = coroutine.close(res.thread)
		asserts.strContains(tostring(err), "ctx failed")
	end)
end)
