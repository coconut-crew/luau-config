const luau_config = {
	languagemode = `strict`,

	aliases = {
		lune = "~/.lune/.typedefs/0.10.5/",
		std = "~/.lute/typedefs/1.0.1/std",
		vendor = "vendor",
		src = "src",
		tests = "tests",
	},

	lint = {
		[`*`] = true,
	},
}

return {
	luau = luau_config,
}
