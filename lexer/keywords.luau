--!strict
-- Keyword and unsupported character tables.

local Keywords = {}

Keywords.KEYWORDS = {
	['local'] = true,
	['if'] = true,
	['then'] = true,
	['else'] = true,
	['elseif'] = true,
	['end'] = true,
	['while'] = true,
	['do'] = true,
	['for'] = true,
	['print'] = true,
	['true'] = true,
	['false'] = true,
	['not'] = true,
	['and'] = true,
	['or'] = true,
}

Keywords.UNSUPPORTED_CHARS = {
	['{'] = 'Tables are not supported',
	['}'] = 'Tables are not supported',
	['\''] = 'String literals are not supported',
	['"'] = 'String literals are not supported',
	['['] = 'Tables/string indexing is not supported',
	[']'] = 'Tables/string indexing is not supported',
	['#'] = 'Length operator is not supported',
	['.'] = 'Dot operator is not supported',
}

return Keywords
