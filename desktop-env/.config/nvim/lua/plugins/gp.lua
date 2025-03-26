return -- lazy.nvim
{
	"robitx/gp.nvim",
	config = function()
		local conf = {
			-- For customization, refer to Install > Configuration in the Documentation/Readme
			providers = {
				openai = {
					endpoint = "https://api.openai.com/v1/chat/completions",
					secret = os.getenv("OPENAI_API_KEY"),
				},

				-- azure = {...},

				copilot = {
					endpoint = "https://api.githubcopilot.com/chat/completions",
					secret = {
						"bash",
						"-c",
						"cat ~/.config/github-copilot/hosts.json | sed -e 's/.*oauth_token...//;s/\".*//'",
					},
				},

				pplx = {
					endpoint = "https://api.perplexity.ai/chat/completions",
					secret = os.getenv("PPLX_API_KEY"),
				},

				ollama = {
					endpoint = "http://localhost:11434/v1/chat/completions",
				},

				googleai = {
					endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
					secret = os.getenv("GOOGLEAI_API_KEY"),
				},

				anthropic = {
					endpoint = "https://api.anthropic.com/v1/messages",
					secret = os.getenv("ANTHROPIC_API_KEY"),
				},
			},
			agents = {
				{
					provider = "anthropic",
					name = "claude-3.7-sonnet-20250219",
					chat = true,
					command = true,
					-- string with model name or table with model name and parameters
					model = { model = "claude-3-7-sonnet-20250219", temperature = 0.8, top_p = 1 },
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
