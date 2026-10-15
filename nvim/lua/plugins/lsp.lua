-- ~/.config/nvim/lua/plugins/lsp.lua
return {
	{
		'neovim/nvim-lspconfig',
		dependencies = {
			'hrsh7th/cmp-nvim-lsp',
		},
		config = function()
			vim.lsp.config('*', {
				root_markers = { '.git' },
			})

			vim.diagnostic.config({
				virtual_text  = true,
				severity_sort = true,
				float         = {
					style  = 'minimal',
					border = 'rounded',
					source = 'if_many',
					header = '',
					prefix = '',
				},
				signs         = {
					text = {
						[vim.diagnostic.severity.ERROR] = '✘',
						[vim.diagnostic.severity.WARN]  = '▲',
						[vim.diagnostic.severity.HINT]  = '⚑',
						[vim.diagnostic.severity.INFO]  = '»',
					},
				},
			})

			local orig = vim.lsp.util.open_floating_preview
			---@diagnostic disable-next-line: duplicate-set-field
			function vim.lsp.util.open_floating_preview(contents, syntax, opts, ...)
				opts            = opts or {}
				opts.border     = opts.border or 'rounded'
				opts.max_width  = opts.max_width or 80
				opts.max_height = opts.max_height or 24
				opts.wrap       = opts.wrap ~= false
				return orig(contents, syntax, opts, ...)
			end

			vim.api.nvim_create_autocmd('LspAttach', {
				group = vim.api.nvim_create_augroup('my.lsp', {}),
				callback = function(args)
					local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
					local buf    = args.buf
					local map    = function(mode, lhs, rhs) vim.keymap.set(mode, lhs, rhs,
							{ buffer = buf }) end

					map('n', 'K', vim.lsp.buf.hover)
					map('n', 'gd', vim.lsp.buf.definition)
					map('n', 'gD', vim.lsp.buf.declaration)
					map('n', 'gi', vim.lsp.buf.implementation)
					map('n', 'go', vim.lsp.buf.type_definition)
					map('n', 'gr', vim.lsp.buf.references)
					map('n', 'gs', vim.lsp.buf.signature_help)
					map('n', 'gl', vim.diagnostic.open_float)
					map('n', '<F2>', vim.lsp.buf.rename)
					map({ 'n', 'x' }, '<F3>', function() vim.lsp.buf.format({ async = true }) end)
					map('n', '<F4>', vim.lsp.buf.code_action)

					if client:supports_method('textDocument/documentHighlight') then
						local highlight_augroup = vim.api.nvim_create_augroup('my.lsp.highlight',
							{ clear = false })
						vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
							buffer = buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})
						vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
							buffer = buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})
					end

					-- Don't auto-format C/C++ on save (matches Tony's config; delete if you want clangd to format)
					local excluded_filetypes = { c = true, cpp = true }
					if not client:supports_method('textDocument/willSaveWaitUntil')
					    and client:supports_method('textDocument/formatting')
					    and not excluded_filetypes[vim.bo[buf].filetype]
					then
						vim.api.nvim_create_autocmd('BufWritePre', {
							group = vim.api.nvim_create_augroup('my.lsp.format',
								{ clear = false }),
							buffer = buf,
							callback = function()
								vim.lsp.buf.format({ bufnr = buf, id = client.id, timeout_ms = 1000 })
							end,
						})
					end
				end,
			})

			local caps = require('cmp_nvim_lsp').default_capabilities()

			-- Lua
			vim.lsp.config['luals'] = {
				cmd = { 'lua-language-server' },
				filetypes = { 'lua' },
				root_markers = { { '.luarc.json', '.luarc.jsonc' }, '.git' },
				capabilities = caps,
				settings = {
					Lua = {
						runtime = { version = 'LuaJIT' },
						diagnostics = { globals = { 'vim' } },
						workspace = {
							checkThirdParty = false,
							library = vim.api.nvim_get_runtime_file('', true),
						},
						telemetry = { enable = false },
					},
				},
			}

			-- C / C++
			vim.lsp.config['clangd'] = {
				cmd = { 'clangd' },
				filetypes = { 'c', 'cpp', 'objc', 'objcpp' },
				root_markers = { 'compile_commands.json', '.clangd', 'configure.ac', 'Makefile', '.git' },
				capabilities = caps,
			}

			-- Python
			vim.lsp.config['pyright'] = {
				cmd = { 'pyright-langserver', '--stdio' },
				filetypes = { 'python' },
				root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', '.git' },
				capabilities = caps,
			}

			-- Bash
			vim.lsp.config['bashls'] = {
				cmd = { 'bash-language-server', 'start' },
				filetypes = { 'sh', 'bash' },
				root_markers = { '.git' },
				capabilities = caps,
			}

			-- Markdown
			vim.lsp.config['marksman'] = {
				cmd = { 'marksman', 'server' },
				filetypes = { 'markdown', 'markdown.mdx' },
				root_markers = { '.marksman.toml', '.git' },
				capabilities = caps,
			}

			vim.filetype.add({
				extension = {
					h = 'c',
				},
			})

			---@diagnostic disable-next-line: invisible
			for name, _ in pairs(vim.lsp.config._configs) do
				if name ~= '*' then
					vim.lsp.enable(name)
				end
			end
		end,
	},

	-- Autocompletion (referenced by cmp_nvim_lsp)
	{
		'hrsh7th/nvim-cmp',
		dependencies = {
			'hrsh7th/cmp-nvim-lsp',
			'hrsh7th/cmp-buffer',
			'hrsh7th/cmp-path',
			'L3MON4D3/LuaSnip',
			'saadparwaiz1/cmp_luasnip',
		},
		config = function()
			local cmp     = require('cmp')
			local luasnip = require('luasnip')

			cmp.setup({
				snippet = {
					expand = function(args) luasnip.lsp_expand(args.body) end,
				},
				mapping = cmp.mapping.preset.insert({
					['<C-b>']     = cmp.mapping.scroll_docs(-4),
					['<C-f>']     = cmp.mapping.scroll_docs(4),
					['<C-Space>'] = cmp.mapping.complete(),
					['<C-e>']     = cmp.mapping.abort(),
					['<CR>']      = cmp.mapping.confirm({ select = true }),
					['<Tab>']     = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { 'i', 's' }),
					['<S-Tab>']   = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { 'i', 's' }),
				}),
				sources = cmp.config.sources({
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
				}, {
					{ name = 'buffer' },
					{ name = 'path' },
				}),
			})
		end,
	},
}
