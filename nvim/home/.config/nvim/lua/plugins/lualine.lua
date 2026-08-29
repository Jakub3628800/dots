-- One Half Dark palette (matches Mitchell Hashimoto's airline/lightline theme).
local colors = {
	black = "#282c34",
	red = "#e06c75",
	green = "#98c379",
	yellow = "#e5c07b",
	blue = "#61afef",
	purple = "#c678dd",
	cyan = "#56b6c2",
	white = "#dcdfe4",
	med_hi = "#5d677a",
	med_lo = "#313640",
}

local theme = {
	normal = {
		a = { fg = colors.black, bg = colors.green },
		b = { fg = colors.white, bg = colors.med_hi },
		c = { fg = colors.green, bg = colors.med_lo },
	},
	insert = {
		a = { fg = colors.black, bg = colors.blue },
		b = { fg = colors.white, bg = colors.med_hi },
		c = { fg = colors.blue, bg = colors.med_lo },
	},
	replace = {
		a = { fg = colors.black, bg = colors.red },
		b = { fg = colors.white, bg = colors.med_hi },
		c = { fg = colors.red, bg = colors.med_lo },
	},
	visual = {
		a = { fg = colors.black, bg = colors.yellow },
		b = { fg = colors.white, bg = colors.med_hi },
		c = { fg = colors.yellow, bg = colors.med_lo },
	},
	command = {
		a = { fg = colors.black, bg = colors.cyan },
		b = { fg = colors.white, bg = colors.med_hi },
		c = { fg = colors.cyan, bg = colors.med_lo },
	},
	inactive = {
		a = { fg = colors.white, bg = colors.med_lo },
		b = { fg = colors.white, bg = colors.med_lo },
		c = { fg = colors.white, bg = colors.med_lo },
	},
}

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = theme,
			globalstatus = true,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
		},
		sections = {
			lualine_a = { "mode" },
			lualine_b = { "branch", "diff" },
			lualine_c = {
				{ "filename", path = 1 },
				{
					function()
						return require("nvim-navic").get_location()
					end,
					cond = function()
						return package.loaded["nvim-navic"] and require("nvim-navic").is_available()
					end,
				},
			},
			lualine_x = { "diagnostics", "encoding", "fileformat", "filetype" },
			lualine_y = { "progress", "location" },
			lualine_z = {
				function()
					return "󰥔 " .. os.date("%H:%M")
				end,
			},
		},
	},
}
