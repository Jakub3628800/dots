local prompt = [[
When asked general question about a system, assume linux. Ubuntu (or debian) with packaging.
Answer in a consise way, shortly explaining the main point but not too much. The user is looking for a quick answer, not a lenghty one.

The user is a proficient linux user, familiar with terminal commands and concepts.
When they ask you for how to do a certain task in a terminal, provide a code snippet that is compatible with markdown, starting with ``` and ending with ```. The code snippet should ideally be a single command. When the task requires multiple commands, split them into multiple code blocks, describing each with one sentence.
]]

return {
	"robitx/gp.nvim",
	config = function()
		local conf = {
			providers = {
				anthropic = {
					endpoint = "https://api.anthropic.com/v1/messages",
					secret = os.getenv("ANTHROPIC_API_KEY"),
				},
				pplx = {
					endpoint = "https://api.perplexity.ai/chat/completions",
					secret = os.getenv("PERPLEXITY_API_KEY"),
				},
			},
			agents = {
				{
					provider = "anthropic",
					name = "claude-sonnet-4-20250514",
					chat = true,
					command = true,
					model = { model = "claude-sonnet-4-20250514", temperature = 0.8, top_p = 1 },
					system_prompt = prompt,
				},
				{
					name = "Perplexity",
					provider = "pplx",
					chat = true,
					command = true,
					model = { model = "sonar" },
					system_prompt = prompt,
				},
			},
		}
		require("gp").setup(conf)
		vim.keymap.set("n", "<space>g", ":GpChatRespond<CR>", { noremap = true, silent = true })
		vim.keymap.set("n", "<space>c", ":GpChatClose<CR>", { noremap = true, silent = true })
	end,
}
