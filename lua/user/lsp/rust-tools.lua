local rt = require("rust-tools")

local extension_path = vim.env.HOME .. '/.vscode/extensions/vadimcn.vscode-lldb-1.8.1'
local codelldb_path = extension_path .. '/adapter/codelldb'
local liblldb_path = extension_path .. '/lldb/lib/liblldb.dylib'

rt.setup({
  server = {
    on_attach = function(_, bufnr)
      local opts = { noremap = true, silent = false, buffer = bufnr }
      -- Hover actions
      vim.keymap.set("n", "K", rt.hover_actions.hover_actions, opts)
      -- vim.keymap("n", "K", vim.lsp.buf.hover(), opts)
      -- Code action groups
      vim.keymap.set("n", "<Leader>la", rt.code_action_group.code_action_group, opts)
      -- vim.keymap.set("n", "<leader>la", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "gI", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "gl", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "<leader>lf", function() vim.lsp.buf.format{ async = true } end, opts)
      vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", opts)
      vim.keymap.set("n", "<leader>lj", vim.diagnostic.goto_next, opts)
      vim.keymap.set("n", "<leader>lk", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, opts)
      vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, opts)
    end,
  },
  dap = {
    adapter = require('rust-tools.dap').get_codelldb_adapter(
      codelldb_path, liblldb_path)
  },
})
