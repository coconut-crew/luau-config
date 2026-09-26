const src = require("@src")
const path = require("@std/path")
const test = require("@std/test")

const function empty_ctx()
	return {}
end

test.suite("basic usage", function(suite)
	suite:case("construction works", function()
		src.new(function()
			return {}
		end, {})
	end)

	suite:case("keeps the settings table it was given", function(asserts)
		const settings: src.Settings = {}
		const conf = src.new(empty_ctx, settings)

		asserts.eq(conf.settings, settings)
	end)

	suite:case("builds the ctx with the config's path", function(asserts)
		local path_to_set: path.Pathlike
		const conf = src.new(function(p)
			path_to_set = p
			return {}
		end, {})

		conf:run("tests/samples/empty.luau")

		asserts.eq(path.format(path.parse("tests/samples/empty.luau")), path.format(path_to_set))
	end)

	suite:case("can run a file with a context", function(asserts)
		const conf = src.new(function()
			return {
				marker = true,
			}
		end, {})

		const res = conf:run(path.parse("tests/samples/empty.luau"))

		asserts.that(res.ok)
		assert(res.ok)
		asserts.eq(res.ctx.marker, true)
	end)
end)
