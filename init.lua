vim.loader.enable() -- supposed to improve startup times. (experimental)

local path_package = vim.fn.stdpath('data') .. '/site/'
local mini_path = path_package .. 'pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local minirepo = 'https://github.com/echasnovski/mini.nvim'
  vim.fn.system({ 'git', 'clone', '--filter=blob:none', minirepo, mini_path })
  vim.cmd('packadd mini.nvim | echo "Installed `mini.nvim`" | redraw')
end

require('mini.deps').setup({ path = { package = path_package } })
local pkg = MiniDeps.add;
local doNow, doLater = MiniDeps.now, MiniDeps.later

vim.cmd([[
  set tabstop=2 shiftwidth=2 expandtab
  " set fillchars+=lastline:. display=truncate
  set relativenumber number
  set signcolumn=yes
  let mapleader=' '
  let maplocalleader=' '
  tnoremap <C-W><C-W> <C-\><C-N><C-W><C-W>
  tnoremap <C-W><Esc> <C-\><C-N>
  " actually execute the `man` command instead of `man.lua`.
  nnoremap K :<C-U>let g:MAN_SV=@m<CR>"myiw:sp term://man <C-R>m<CR><CMD>let @m=g:MAN_SV<CR>
  vnoremap K :<C-U>let g:MAN_SV=@m<CR>gv"my:sp term://man <C-R>m<CR><CMD>let @m=g:MAN_SV<CR>
  nnoremap <Leader>f :e<Space>
  nnoremap <Leader>h :tab<Space>help<Space>
  autocmd FileType make set noexpandtab
]])

doNow(function()
  pkg('rmehri01/onenord.nvim') -- colorscheme
  require('onenord').setup()
  local my_headers_present, my_headers = pcall(require, 'my.header')
  require('mini.starter').setup({ header = my_headers_present and my_headers or nil })
  require('mini.statusline').setup({
    content = {
      active = function()
        local mode, mode_hl = MiniStatusline.section_mode({ trunc_width = 80 })
        -- need gitsigns.nvim for this to work
        local git_ready, git = pcall(MiniStatusline.section_git,{ trunc_width = 1000 })
        local filename = MiniStatusline.section_filename({ trunc_width = 1000 })

        -- if I `set cmdheight=0`, this'll be good.
        local macro_reg_hl, macro_reg = 'DiagnosticInfo', vim.fn.reg_recording()
        macro_reg = macro_reg ~= "" and '(recording @' .. macro_reg .. ')'

        local hydra_ready, hydrastatus = pcall(require, 'hydra.statusline')
        if hydra_ready and hydrastatus.is_active() then mode = hydrastatus.get_name() end

        return MiniStatusline.combine_groups({
          { hl = mode_hl, strings = { mode } },
          '%<',
          { hl = 'MiniStatuslineFilename', strings = { filename } },
          '%=',
          '%S', { strings = { macro_reg } },
          git_ready and { hl = 'MiniStatuslineDevinfo', strings = { git } } or nil,
        })
      end
    }
  })
  vim.cmd('set showcmdloc=statusline')
  vim.cmd('set noshowmode')
end)

doLater(function()
  require('mini.pick').setup()
  vim.keymap.set('n', '<Leader><Leader>', MiniPick.builtin.buffers)
  vim.keymap.set('n', '<Leader>b', ':bn<CR>')
  vim.keymap.set('n', '<Leader>B', ':bN<CR>')
  vim.api.nvim_create_autocmd({ 'BufLeave', 'ExitPre', --[['BufUnload', 'VimLeavePre']] }, {
    callback = function()
      local curr_buf = vim.fn.bufnr('%')
      for m in string.gmatch('ABCDEFGHIJKLMNOPQRSTUVWXYZ', '.') do
        local buf = vim.api.nvim_get_mark(m, {})[3]
        if buf == curr_buf then vim.fn.setpos("'"..m, vim.fn.getpos('.')) end
      end
    end
  })
end)

doLater(function()
  pkg('numToStr/FTerm.nvim') -- floating terminal
  require('FTerm').setup({ ft = 'FTerm', cmd = (os.getenv('SHELL') .. ' -il'), blend = 5 })
  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function(ev) if(vim.bo[ev.buf].ft ~= 'FTerm') then require('FTerm').close() end end
  })
  vim.keymap.set('n', '<Leader>t', require('FTerm').toggle)
end)

doLater(function()
  pkg('anuvyklack/hydra.nvim') -- making new modes
  pkg('lewis6991/gitsigns.nvim') 
  local Hydra = require("hydra")
  local gitsigns = require('gitsigns')
  local git_hint = [[
  _j_: next hunk   _s_: stage hunk        _d_: show deleted   _b_: blame line
  _k_: prev hunk   _u_: undo last stage   _p_: preview hunk   _B_: blame show full 
  ^ ^              _S_: stage buffer      ^ ^                 _/_: show base file
  ^
  ^ ^              _<Esc>_: exit
  ]]
  gitsigns.setup() 
  Hydra({
    name = 'Git',
    hint = git_hint,
    config = {
      buffer = false,
      color = 'pink',
      invoke_on_body = true,
      hint = {
        border = 'rounded'
      },
    },
    mode = {'n','x'},
    body = '<Leader>g',
    heads = {
      { 'j',
        function()
          if vim.wo.diff then return ']c' end
          vim.schedule(function() gitsigns.next_hunk() end)
          return '<Ignore>'
        end,
        { expr = true, desc = 'next hunk' } },
      { 'k',
        function()
          if vim.wo.diff then return '[c' end
          vim.schedule(function() gitsigns.prev_hunk() end)
          return '<Ignore>'
        end,
        { expr = true, desc = 'prev hunk' } },
      { 's', ':Gitsigns stage_hunk<CR>', { silent = true, desc = 'stage hunk' } },
      { 'u', gitsigns.undo_stage_hunk, { desc = 'undo last stage' } },
      { 'S', gitsigns.stage_buffer, { desc = 'stage buffer' } },
      { 'p', gitsigns.preview_hunk_inline, { desc = 'preview hunk' } },
      { 'd', gitsigns.toggle_deleted, { nowait = true, desc = 'toggle deleted' } },
      { 'b', gitsigns.blame_line, { desc = 'blame' } },
      { 'B', function() gitsigns.blame_line{ full = true } end, { desc = 'blame show full' } },
      { '/', gitsigns.show, { exit = true, desc = 'show base file' } }, -- show the base of the file
      { '<Esc>', nil, { exit = true, nowait = true, desc = 'exit' } },
    }
  })
end)

doLater(function()
  pkg('nvim-treesitter/nvim-treesitter')
  require('nvim-treesitter.configs').setup({
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    textobjects = {
      select = {
        enable = true,
        keymaps = {
          ["af"] = "@function.outer",
          ["if"] = "@function.inner",
        }
      },
      move = {
        enable = true,
        set_jumps = true,
        goto_next_start = { [']]'] = '@function.outer' },
        goto_next_end = { [']['] = '@function.outer' },
        goto_previous_start = { ['[['] = '@function.outer' },
        goto_previous_end = { ['[]'] = '@function.outer' },
      }
    },
  })
  vim.cmd('set foldmethod=expr foldexpr=nvim_treesitter#foldexpr() nofoldenable')
end)

doLater(function()
  pkg('williamboman/mason.nvim') -- nice interface for installing DAPs, LSPs, linters, etc.
  pkg({
    source = 'nvim-treesitter/nvim-treesitter-textobjects',
    depends = { 'nvim-treesitter/nvim-treesitter' }
  })
  pkg({
    source = 'williamboman/mason-lspconfig.nvim',
    depends = { 'neovim/nvim-lspconfig' }
  })
  pkg('nvim-tree/nvim-web-devicons') -- for mini.statusline filetype icons

  require('mini.completion').setup()
  vim.cmd([[set completeopt+=menuone,noselect ]])

  local lspconfig = require('lspconfig')
  require('mason').setup({})
  require("mason-lspconfig").setup({
    handlers = { function(lsp) lspconfig[lsp].setup({}) end },
    automatic_installation = true
  })

  vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('UserLspConfig', {}),
    callback = function(ev)
      vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'
      local opts = { buffer = ev.buf }
      vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
      vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, opts)
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
      vim.keymap.set('n', '<Leader>K', vim.lsp.buf.hover, opts)
      vim.keymap.set('n', '<Leader>gi', vim.lsp.buf.implementation, opts)
      vim.keymap.set('n', '<Leader><C-k>', vim.lsp.buf.signature_help, opts)
    end
  })
end)

doLater(function() vim.cmd('helptags ALL') end)
