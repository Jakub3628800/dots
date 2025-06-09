return -- lazy.nvim
{
	"robitx/gp.nvim",
	config = function()
		local conf = {
			-- For customization, refer to Install > Configuration in the Documentation/Readme
			providers = {
				anthropic = {
					endpoint = "https://api.anthropic.com/v1/messages",
					secret = os.getenv("ANTHROPIC_API_KEY"),
				},
			},
			agents = {
				{
					provider = "anthropic",
					name = "claude-sonnet-4-20250514",
					chat = true,
					command = true,
					-- string with model name or table with model name and parameters
					model = { model = "claude-sonnet-4-20250514", temperature = 0.8, top_p = 1 },
					system_prompt = os.getenv("ANTHROPIC_SYSTEM_PROMPT"),
				},
				{
					provider = "anthropic",
					name = "claude-opus-4-20250501",
					chat = true,
					command = true,
					-- string with model name or table with model name and parameters
					model = { model = "claude-opus-4-20250501", temperature = 0.8, top_p = 1 },
					system_prompt = os.getenv("ANTHROPIC_SYSTEM_PROMPT"),
				},
			},
		}
		require("gp").setup(conf)
		vim.keymap.set("n", "<space>g", ":GpChatRespond<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<space>c", ":GpChatClose<CR>", { noremap = true, silent = true })

		-- Setup shortcuts here (see Usage > Shortcuts in the Documentation/Readme)
	end,
}
