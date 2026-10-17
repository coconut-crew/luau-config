const fs = require("@std/fs")
const path = require("@std/path")

const library = {}
library.__index = library
export type Identity<T> = setmetatable<{
	identifier: string,
	fns: {
		[string]: {
			type_signature: string,
			fn: (ctx: T, ...unknown) -> ...unknown,
		},
	},
	types: { [string]: string },
}, typeof(library)>

const function constructor<T>(identifier: string): Identity<T>
	const self = setmetatable({
		identifier = identifier,
		fns = {},
		types = {},
	}, library)

	return self
end

function library.add_type<T>(self: Identity<T>, name: string, expr: string)
	self.types[name] = expr
end

function library.add_function<T>(self: Identity<T>, name: string, type_signature: string, fn: (ctx: T, ...unknown) -> ...unknown)
	self.fns[name] = {
		type_signature = type_signature,
		fn = fn,
	}
end

function library.write_interface<T>(self: Identity<T>, location: path.Pathlike)
	const file = {}

	for type_name, type_sig in self.types do
		table.insert(file, `export type {type_name} = {type_sig}`)
	end

	table.insert(file, `const {self.identifier} = \{\}`)

	for fn_name, fn_sig in self.fns do
		table.insert(file, `{self.identifier}.{fn_name} = (nil :: any) :: {fn_sig.type_signature}`)
	end

	table.insert(file, `return {self.identifier}`)

	fs.writeStringToFile(location, table.concat(file, "\n") .. "\n")
end

function library.instantiate<T>(self: Identity<T>, ctx: T): any
	const lib_inst = {}

	for fn_name, fn_sig in self.fns do
		lib_inst[fn_name] = function(...: unknown)
			return fn_sig.fn(ctx, ...)
		end
	end

	table.freeze(lib_inst)
	return lib_inst
end

table.freeze(library)
return { new = constructor }
