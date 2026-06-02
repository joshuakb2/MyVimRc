-- Project-wide / subtree TypeScript diagnostics via tsgo → quickfix
-- tsc line shape: path(line,col): error TS1234: message
local TSC_PAT = "^(.-)%((%d+),(%d+)%):%s+(%a+)%s+TS(%d+):%s+(.*)$"

-- Run tsgo against one tsconfig, anchored at `base` (= cwd for the run and the
-- directory that emitted relative paths are resolved against). Returns qf items.
local function run_tsgo(tsconfig, base)
  local root = vim.fs.root(vim.api.nvim_buf_get_name(0), { 'package.json' })
  local res = vim.system(
    { root .. "/node_modules/.bin/tsgo", "--noEmit", "--pretty", "false", "-p", tsconfig },
    { cwd = base, text = true }
  ):wait()
  local items = {}
  for line in vim.gsplit((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true }) do
    local file, lnum, col, sev, code, msg = line:match(TSC_PAT)
    if file then
      local fname = file:sub(1, 1) == "/" and file
        or vim.fs.normalize(vim.fs.joinpath(base, file))
      table.insert(items, {
        filename = fname,
        lnum = tonumber(lnum),
        col = tonumber(col),
        nr = tonumber(code),
        type = sev == "warning" and "W" or "E",
        text = msg,
      })
    end
  end
  return items
end

local function show(items, title)
  vim.fn.setqflist({}, " ", { title = title, items = items })
  if #items > 0 then
    vim.cmd("copen")
  else
    vim.cmd("cclose")
    vim.notify("tsgo: no diagnostics", vim.log.levels.INFO)
  end
end

-- Scope to the tsconfig nearest the current buffer (walks upward).
-- In a single-tsconfig project this naturally resolves to the root config.
local function tsgo_buffer()
  local start = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  if start == "" then start = vim.uv.cwd() end
  local found = vim.fs.find("tsconfig.json", { upward = true, path = start })
  if vim.tbl_isempty(found) then
    return vim.notify("tsgo: no tsconfig.json above this buffer", vim.log.levels.WARN)
  end
  local tsconfig = found[1]
  show(run_tsgo(tsconfig, vim.fs.dirname(tsconfig)), "tsgo " .. tsconfig)
end

-- Every tsconfig under the project root (pruning node_modules/.git/dotdirs), merged.
local function find_tsconfigs(dir, acc)
  acc = acc or {}
  for name, type in vim.fs.dir(dir) do
    if type == "directory" then
      if name ~= "node_modules" and name:sub(1, 1) ~= "." then
        find_tsconfigs(vim.fs.joinpath(dir, name), acc)
      end
    elseif name == "tsconfig.json" then
      table.insert(acc, vim.fs.joinpath(dir, name))
    end
  end
  return acc
end

local function tsgo_project()
  local root = vim.fs.root(0, { ".git" }) or vim.uv.cwd()
  local configs = find_tsconfigs(root)
  if vim.tbl_isempty(configs) then
    return vim.notify("tsgo: no tsconfig.json under " .. root, vim.log.levels.WARN)
  end
  local items = {}
  for _, cfg in ipairs(configs) do
    vim.list_extend(items, run_tsgo(cfg, root))
  end
  show(items, ("tsgo project (%d configs)"):format(#configs))
end

vim.api.nvim_create_user_command("TsgoDiagnostics", tsgo_buffer, {})
vim.api.nvim_create_user_command("TsgoDiagnosticsProject", tsgo_project, {})
vim.keymap.set("n", "<leader>di", tsgo_buffer,
  { silent = true, desc = "tsgo diagnostics (buffer's tsconfig)" })
vim.keymap.set("n", "<leader>dI", tsgo_project,
  { silent = true, desc = "tsgo diagnostics (whole project)" })
