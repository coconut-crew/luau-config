const fs = require("@std/fs")
const luau = require("@std/luau")
const path = require("@std/path")

export type Library<T> = { [string]: (ctx: T, ...unknown) -> ...any }

export type Settings = {
	print: ((...unknown) -> ())?,
	warn: ((...unknown) -> ())?,
	error: ((any, number) -> ())?,
}

type ErrConfigYielded = {
	ok: false,
	status: "yielded",
	thread: thread,
}

type ErrCtxConstructorFail = {
	ok: false,
	status: "ctx_constructor_err",
	thread: thread,
}
type ErrCompilationFail = {
	ok: false,
	status: "compilation_err",
	msg: string,
}
type ErrFileAccessFail = {
	ok: false,
	status: "file_access_err",
	msg: string,
}
type ErrConfigFileFail = {
	ok: false,
	status: "config_file_err",
	thread: thread,
}
type Success<T> = {
	ok: true,
	ctx: T,
}

export type ConfigResult<T> =
	| Success<T>
	| ErrConfigYielded
	| ErrFileAccessFail
	| ErrCompilationFail
	| ErrConfigFileFail
	| ErrCtxConstructorFail

const luau_conf = {}
luau_conf.__index = luau_conf
export type Identity<T> = setmetatable<{
	ctx_constructor: (path.Path) -> T,
	lib_constructors: { [string]: (ctx: T) -> Library<T> },
	settings: Settings,
}, typeof(luau_conf)>

const function constructor<T>(ctx_constructor: (path.Path) -> T, settings: Settings): Identity<T>
	const self = setmetatable({
		ctx_constructor = ctx_constructor,
		lib_constructors = {},
		settings = settings,
	}, luau_conf)

	return self
end

function luau_conf.add_library<T>(self: Identity<T>, name: string, lib: Library<T>)
	self.lib_constructors[name] = function(ctx: any)
		const derived_lib = {}

		for lib_key, lib_value in lib do
			derived_lib[lib_key] = function(...)
				return lib_value(ctx, ...)
			end
		end

		table.freeze(derived_lib)
		return derived_lib :: any
	end
end

function luau_conf.run<T>(self: Identity<T>, conf_path: path.Pathlike): ConfigResult<T>
	const ctx_thread = coroutine.create(self.ctx_constructor)
	const ctx_ok, ctx = coroutine.resume(ctx_thread, path.parse(conf_path))
	if not ctx_ok then
		return {
			ok = false,
			status = "ctx_constructor_err",
			thread = ctx_thread,
		}
	end

	const lib_table = {}

	for lib_name, lib_constructor in self.lib_constructors do
		lib_table[lib_name] = lib_constructor(ctx)
	end

	const env: { [string]: any } = {
		string = string,

		error = error,
		assert = assert,
		print = print,

		tostring = tostring,
		tonumber = tonumber,

		unpack = unpack,

		require = function(path: string): any
			const alias = string.match(path, "@([%w_]+)$")
			if not alias then
				error("TBD ERR 2")
			end

			if lib_table[alias] then
				return lib_table[alias]
			end

			error("TBD ERR 1")
		end,
	}

	const read_ok, file_content = pcall(fs.readFileToString, conf_path)
	if not read_ok then
		return {
			ok = false,
			status = "file_access_err",
			msg = tostring(file_content),
		}
	end

	const load_ok, fn = pcall(luau.load, luau.compile(file_content), path.format(conf_path), env :: any)
	if not load_ok then
		return {
			ok = false,
			status = "compilation_err",
			msg = tostring(fn),
		}
	end

	const thread = coroutine.create(fn)

	const status = coroutine.resume(thread)
	if status then
		if coroutine.status(thread) == "suspended" then
			return {
				ok = false,
				status = "yielded",
				thread = thread,
			}
		end

		return {
			ok = true,
			ctx = ctx,
		}
	else
		return {
			ok = false,
			status = "config_file_err",
			thread = thread,
		}
	end
end

table.freeze(luau_conf)
return { new = constructor }
