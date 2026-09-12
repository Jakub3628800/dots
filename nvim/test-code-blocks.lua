-- Pure fence-selection regressions: no plugins, clipboard, or tmux required.
local find_bounds = require("code-block").find_bounds
local cases = {
	{
		name = "prose between blocks is not code",
		lines = { "before", "```sh", "echo first", "```", "prose", "", "```sh", "echo second", "```", "after" },
		blocks = { { 2, 4 }, { 7, 9 } },
	},
	{
		name = "adjacent blocks keep their own opening and closing fences",
		lines = { "```sh", "echo first", "```", "```sh", "echo second", "```" },
		blocks = { { 1, 3 }, { 4, 6 } },
	},
	{
		name = "unclosed block is not selected",
		lines = { "before", "```sh", "echo unfinished" },
		blocks = {},
	},
	{
		name = "empty block",
		lines = { "```", "```" },
		blocks = { { 1, 2 } },
	},
	{
		name = "plain text and inline backticks",
		lines = { "text", "inline ``` text", "``short``" },
		blocks = {},
	},
	{
		name = "shorter nested fences remain content",
		lines = { "````markdown", "```sh", "echo nested", "```", "````" },
		blocks = { { 1, 5 } },
	},
	{
		name = "closing fence may be longer",
		lines = { "```sh", "echo test", "`````  " },
		blocks = { { 1, 3 } },
	},
	{
		name = "mismatched fence is not a closing fence",
		lines = { "```sh", "echo test", "~~~" },
		blocks = {},
	},
	{
		name = "closing fence cannot have an info string",
		lines = { "```sh", "```not-a-close", "echo test", "```" },
		blocks = { { 1, 4 } },
	},
	{
		name = "tilde fences",
		lines = { "~~~sh", "```", "echo test", "~~~~" },
		blocks = { { 1, 4 } },
	},
	{
		name = "up to three leading spaces are allowed",
		lines = { "   ```sh", "echo test", "  ```\t" },
		blocks = { { 1, 3 } },
	},
	{
		name = "four-space indentation is not a fence",
		lines = { "    ```sh", "    echo test", "    ```" },
		blocks = {},
	},
	{
		name = "backticks are not allowed in backtick fence info strings",
		lines = { "```invalid`info", "echo test", "```" },
		blocks = {},
	},
	{
		name = "tilde may start a backtick fence info string",
		lines = { "```~info", "echo test", "```" },
		blocks = { { 1, 3 } },
	},
}

for _, case in ipairs(cases) do
	-- Check every cursor position, including both fence lines and surrounding prose.
	for cursor_line = 1, #case.lines do
		local expected_start, expected_end
		for _, block in ipairs(case.blocks) do
			if cursor_line >= block[1] and cursor_line <= block[2] then
				expected_start, expected_end = block[1], block[2]
				break
			end
		end
		local start_line, end_line = find_bounds(case.lines, cursor_line)
		assert(
			start_line == expected_start and end_line == expected_end,
			string.format(
				"%s (cursor %d): expected %s,%s; got %s,%s",
				case.name,
				cursor_line,
				tostring(expected_start),
				tostring(expected_end),
				tostring(start_line),
				tostring(end_line)
			)
		)
	end
end
