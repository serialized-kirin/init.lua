vim.cmd([[
  let mapleader = ' '
  let maplocalleader = ' '
  set number relativenumber signcolumn=yes
  set tabstop=2 shiftwidth=2 expandtab smarttab autoindent
  set breakindent
  set updatetime=250 timeoutlen=300
  " this makes noice.nvim not annoying when using mini.completion
  " set completeopt+='menuone,noselect' 
  set termguicolors mouse=
  set winminheight=0
  " navigation like how I'm used to w/ tabs instead of buffers.
  nnoremap <silent> <Leader>b <CMD>bn<CR>
  nnoremap <silent> <Leader>B <CMD>bN<CR>
  nnoremap <Leader>f :e<Space>
  nnoremap <Leader>h :tab help<Space>
  " used to these in the :terminal from vim
  tnoremap <C-W><C-W> <C-\><C-N><C-W><C-W>
  tnoremap <C-W><Escape> <C-\><C-N>
  " I $%&^&*ing hate `Man.lua`. Worst plugin in existence.
  nnoremap K :<C-U>let g:MAN_SV=@m<CR>"myiw:sp term://man <C-R>m<CR><CMD>let @m=g:MAN_SV<CR>
  vnoremap K :<C-U>let g:MAN_SV=@m<CR>gv"my:sp term://man <C-R>m<CR><CMD>let @m=g:MAN_SV<CR>
  " for some reason this just feels right
  nnoremap <Tab> w
  cabbrev git !git

  " I need to figure out how to only show batt in the active statusline.
  function Batt()
    return system("echo -n `pmset -g ps | awk '/%/{print $3 $4}' | tr ';' ' ' | sed -e 's/ discharging//' -e 's/charging/⚡️/'`")
  endfunc 
  set statusline=%f%(\ %M%)%(\ %H%)%(\ %R%) 
  set statusline+=\ line\ %l/%L
  " set statusline+=%=
  " set statusline+=%(\ %{Batt()}%)%<
  set statusline+=%(\ %S%)
  set showcmdloc=statusline
  set laststatus=3 " one single global statusline
]])

vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- highlight on yank
-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup('YankHighlight', { clear = true })
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = '*',
})

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({
  'tpope/vim-sleuth',
  --[[ GIT ]]
  { 
    'lewis6991/gitsigns.nvim', 
    config = function() 
      -- need to add some keymaps for gitsigns commands-- I've been using it much
      -- more than i expected.
      require('gitsigns').setup()
    end 
  },
  --[[ COLORSCHEME ]]
  {
    'navarasu/onedark.nvim',
    priority = 1000,
    lazy = false,
    config = function()
      require('onedark').setup {
        style = 'warm',
      }
      require('onedark').load()
    end,
  },
  --[[ NAVIGATION ]]
  {
    'mrquantumcodes/bufferchad.nvim', 
    opts = { mapping = '<Leader>l' },
    lazy = true,
    keys = { '<Leader>l' },
  },
  {
    'nvim-treesitter/nvim-treesitter',
    dependencies = { 'nvim-treesitter/nvim-treesitter-textobjects', },
    build = ':TSUpdate',
    config = function()
      -- Defer Treesitter setup after first render to improve startup time of 'nvim {filename}'
      vim.defer_fn(function()
        require('nvim-treesitter.configs').setup {
          auto_install = true,
          sync_install = false,
          ignore_install = {},
          modules = {},
          highlight = { enable = true },
          indent = { enable = true },
          incremental_selection = {
            enable = true,
            keymaps = {
              init_selection = '<c-space>',
              node_incremental = '<c-space>',
              scope_incremental = '<c-s>',
              node_decremental = '<M-space>',
            },
          },
          textobjects = {
            select = {
              enable = true,
              lookahead = true,
              keymaps = {
                -- You can use the capture groups defined in textobjects.scm
                ['af'] = '@function.outer',
                ['if'] = '@function.inner',
                ['ac'] = '@class.outer',
                ['ic'] = '@class.inner',
              },
            },
            move = {
              enable = true,
              set_jumps = true,
              goto_next_start = {
                [']]'] = '@function.outer',
              },
              goto_next_end = {
                [']['] = '@function.outer',
              },
              goto_previous_start = {
                ['[['] = '@function.outer',
              },
              goto_previous_end = {
                ['[]'] = '@function.outer',
              },
            }
          },
        }
      end, 0)
    end
  },
  --[[ DEBUGGING ]]
  {
    {
      'mfussenegger/nvim-dap',
      config = function()
        vim.keymap.set('n', '<Leader>dc', function() require('dap').continue() end)
        vim.keymap.set('n', '<Leader>db', function() require('dap').toggle_breakpoint() end)
        -- s for step, n for next, f for finish
        -- vim.keymap.set('n', '<Leader>dn', function() require('dap').step_over() end)
        -- vim.keymap.set('n', '<Leader>ds', function() require('dap').step_into() end)
        -- vim.keymap.set('n', '<Leader>df', function() require('dap').step_out() end)
      end
    },
    { 'rcarriga/nvim-dap-ui', dependencies = { 'mfussenegger/nvim-dap' } },
    { 'theHamsta/nvim-dap-virtual-text', dependencies = { 'mfussenegger/nvim-dap' } },
    { 
      'jay-babu/mason-nvim-dap.nvim', 
      dependencies = { 'mfussenegger/nvim-dap', 'williamboman/mason.nvim' },
      config = function()
        require('mason').setup()
        require ('mason-nvim-dap').setup({
          automatic_installation = true,
          ensure_installed = {'codelldb'},
          handlers = {}, -- sets up dap in the predefined manner
        })
      end
    }
  },
  --[[ LSP ]]
  --[[{ -- still not sure how to use this one
    'RishabhRD/nvim-lsputils', lazy = false, 
    config = true, 
    dependencies = { 'RishabhRD/popfix' },
  },]]
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', config = true },
      'williamboman/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim', config = true },
    },
    config = function()
      local on_attach = function(_, bufnr)
        local nmap = function(keys, func, desc)
          desc = desc and 'LSP: ' .. desc
          vim.keymap.set('n', keys, func, { buffer = bufnr, desc = desc })
        end

        nmap('<leader>rn', vim.lsp.buf.rename, '[R]e[n]ame')
        vim.keymap.set({ 'n', 'v' }, '<Leader>ca', vim.lsp.buf.code_action, {})

        nmap('<leader>K', vim.lsp.buf.hover, 'Hover Documentation')
        nmap('<C-k>', vim.lsp.buf.signature_help, 'Signature Documentation')

        nmap('gd', vim.lsp.buf.definition, '[G]oto [D]efinition')
        -- set up simplistic two-step completion at some point..

        -- set up simplistic two-step completion at some point..
        -- vim.keymap.set('i', '<C-N>', '<C-X><C-O>')
        -- ill just make omnifunc access faster instead for now
        vim.keymap.set('i', '<C-X><C-X>', '<C-X><C-O>')
      end

      -- mason-lspconfig requires that these setup functions are called in this order
      -- before setting up the servers.
      require('mason').setup()
      require('mason-lspconfig').setup()

      local servers = {
        clangd = {},
      }

      local capabilities = vim.lsp.protocol.make_client_capabilities()

      -- Ensure the servers above are installed
      local mason_lspconfig = require 'mason-lspconfig'

      mason_lspconfig.setup {
        ensure_installed = vim.tbl_keys(servers),
      }

      mason_lspconfig.setup_handlers {
        function(server_name)
          require('lspconfig')[server_name].setup {
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name],
            filetypes = (servers[server_name] or {}).filetypes,
          }
        end,
      }
    end
  },
  --    For additional information see: https://github.com/folke/lazy.nvim#-structuring-your-plugins
  -- { import = 'custom.plugins' },
}, 
{
    performance = { 
      rtp = {
        disabled_plugins = {
          "gzip",
          "editorconfig",
          "health",
          -- idk, i think doing this'll let me jump between start and end html tags again lol.
          -- "matchit", 
          -- highlights matching parens
          -- "matchparen", 
          "netrwPlugin",
          "tarPlugin",
          "tohtml",
          "tutor",
          "zipPlugin",
          "man",
          "spellfile",
        },
      }
    }
  })

-- vim: ts=2 sts=2 sw=2 et
