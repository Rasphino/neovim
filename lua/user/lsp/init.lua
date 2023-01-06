local status_ok, lspconfig = pcall(require, "lspconfig")
if not status_ok then
  return
end


local servers = {
  "sumneko_lua",
  "rnix",
  "gopls",
  "sourcekit"
  -- "rust_analyzer", -- auto setup by rust-tools.nvim
}

local opts = {}
for _, server in pairs(servers) do
  opts = {
    on_attach = require("user.lsp.handlers").on_attach,
    capabilities = require("user.lsp.handlers").capabilities,
  }

  server = vim.split(server, "@")[1]

  local require_ok, conf_opts = pcall(require, "user.lsp.settings." .. server)
  if require_ok then
    opts = vim.tbl_deep_extend("force", conf_opts, opts)
  end

  lspconfig[server].setup(opts)
end

require("user.lsp.handlers").setup()
require "user.lsp.null-ls"
