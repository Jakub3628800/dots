local prompt = [[
You are a fast Linux CLI lookup assistant.
Assume Linux with Ubuntu/Debian packaging unless the user says otherwise.
The user is proficient with terminal tools and wants quick, practical answers.

Response style:
- Keep answers concise and scannable.
- For simple questions: 1 short paragraph or up to 3 bullet points.
- Skip filler and long background unless explicitly asked.

Terminal command behavior:
- When the user asks how to do something in terminal, include Markdown fenced code block(s).
- Prefer a single command when possible.
- If multiple commands are required, use separate code blocks and add one short sentence before each.
- Use safe defaults and briefly warn on destructive/risky commands.
]]

return {
	"robitx/gp.nvim",
	config = function()
		local conf = {
			providers = {
				openai = {},
				azure = {},
				ollama = {},
				lmstudio = {},
				googleai = {},
				pplx = {},
				anthropic = {
					endpoint = "https://api.anthropic.com/v1/messages",
					secret = os.getenv("ANTHROPIC_API_KEY"),
				},
			},
			agents = {
				{ name = "ChatClaude-3-7-Sonnet", disable = true },
				{ name = "ChatClaude-Sonnet-4-Thinking", disable = true },
				{ name = "ChatClaude-3-5-Haiku", disable = true },
				{ name = "CodeClaude-3-7-Sonnet", disable = true },
				{ name = "CodeClaude-3-5-Haiku", disable = true },
				{
					provider = "anthropic",
					name = "Claude-Sonnet-4.5",
					chat = true,
					command = true,
					model = { model = "claude-sonnet-4-5-20250929", temperature = 0.8 },
					system_prompt = prompt,
				},
			},
			default_chat_agent = "Claude-Sonnet-4.5",
			default_command_agent = "Claude-Sonnet-4.5",
		}
		require("gp").setup(conf)
		vim.keymap.set("n", "<space>g", "<cmd>GpChatRespond<CR>", { noremap = true, silent = true, desc = "gp chat respond" })
		vim.keymap.set("n", "<space>c", "<cmd>GpChatToggle<CR>", { noremap = true, silent = true, desc = "gp chat toggle" })
	end,
}
