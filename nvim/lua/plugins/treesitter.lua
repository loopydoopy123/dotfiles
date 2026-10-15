return {
	'nvim-treesitter/nvim-treesitter',
	branch = 'main',
	lazy = false,
	build = ':TSUpdate',
	config = function()
		require("nvim-treesitter").setup({
			highlight = { enable = true },
			indent = { enable = true },
			auto_install = false,
		})

		local parsers = {
			"lua",
			"python",
			"bash",
			"vim",
			"c",
			"cpp",
			"markdown",
			"markdown_inline",
		}
		require("nvim-treesitter").install(parsers)
	end,
}
