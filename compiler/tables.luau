--!strict

local StaticStrings = require('./static-strings')

type Node = { [string]: any }

export type TableKey = {
	kind: 'number' | 'boolean' | 'string',
	id: string,
	numberValue: number?,
	booleanValue: boolean?,
	stringValue: string?
}

export type TableEntry = {
	key: TableKey,
	value: TableValue
}

export type TableInfo = {
	entries: { TableEntry }
}

export type TableValue =
	{ kind: 'scalar', valueCell: number }
	| { kind: 'table', tableInfo: TableInfo }

local Tables = {}

local function makeNumberKey(value: number): TableKey
	return {
		kind = 'number',
		id = `number:{value}`,
		numberValue = value
	}
end

local function makeBooleanKey(value: boolean): TableKey
	return {
		kind = 'boolean',
		id = `boolean:{if value then 'true' else 'false'}`,
		booleanValue = value
	}
end

local function makeStringKey(value: string): TableKey
	return {
		kind = 'string',
		id = `string:{value}`,
		stringValue = value
	}
end

function Tables.resolveKey(node: Node): TableKey?
	local numberValue = StaticStrings.resolveNumber(node)
	if numberValue ~= nil then
		return makeNumberKey(numberValue)
	end

	if node.tag == 'boolean' then
		return makeBooleanKey(node.value)
	end

	if node.tag == 'group' then
		return Tables.resolveKey(node.expression)
	end

	local stringValue = StaticStrings.resolve(node)
	if stringValue ~= nil then
		return makeStringKey(stringValue)
	end

	return nil
end

function Tables.createListKey(index: number): TableKey
	return makeNumberKey(index)
end

function Tables.createRecordKey(name: string): TableKey
	return makeStringKey(name)
end

function Tables.findEntry(info: TableInfo, key: TableKey): TableEntry?
	for _, entry in info.entries do
		if entry.key.id == key.id then
			return entry
		end
	end

	return nil
end

function Tables.lowerIndexName(node: Node): Node
	return {
		tag = 'index',
		location = node.location,
		expression = node.expression,
		index = {
			tag = 'string',
			location = node.indexLocation or node.location,
			token = {
				text = node.index.text
			}
		}
	}
end

return Tables