local M = {}

-- Return a complete top-level Markdown fence pair containing the cursor.
-- Fence lines belong to their own block; prose and unclosed blocks do not.
function M.find_bounds(lines, cursor_line)
	local start_line, marker, fence_length
	for i, line in ipairs(lines) do
		local indent, fence, rest = line:match("^( *)(`+)(.*)$")
		if not fence then
			indent, fence, rest = line:match("^( *)(~+)(.*)$")
		end
		if indent and #indent <= 3 and #fence >= 3 then
			if start_line then
				if fence:sub(1, 1) == marker and #fence >= fence_length and rest:match("^%s*$") then
					if cursor_line >= start_line and cursor_line <= i then
						return start_line, i
					end
					start_line = nil
				end
			elseif fence:sub(1, 1) ~= "`" or not rest:find("`", 1, true) then
				start_line, marker, fence_length = i, fence:sub(1, 1), #fence
			end
		end
	end
	return nil, nil
end

return M
