local home = assert(os.getenv("HOME"), "HOME is not set")
local SHELL = "com.superlogical.terminal.shell"

-- A floating pane running argv, closed when the program exits (herdr's popups).
local function float(bounds, argv, cwd)
  local _, err = rex.session.new_layer{
    bounds = bounds,
    focus = true,
    layout = rex.layout.block{ flavor = SHELL, options = { command = argv, cwd = cwd } },
  }
  if err ~= nil then error(err, 0) end
end

-- The focused terminal's directory. pwd answers with a file://host/path URL.
local function focused_cwd()
  local r = rex.block.call("com.superlogical.terminal", "pwd", {})
  local path = r and r.pwd and r.pwd:match("^file://[^/]*(/.*)$")
  return path and path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end)
end

-- ctrl+space>f, the project picker: a floating fzf over your git repos (see
-- rex/project-picker). The floating pane closes once you pick or press Escape.
rex.action{
  name = "project_picker",
  title = "Open Project…",
  category = "Projects",
  description = "Pick a git repo and open or return to its session",
  keywords = "project directory workspace folder sessionizer",
  run = function(ctx)
    float({ 0.15, 0.2, 0.7, 0.6 }, { home .. "/.config/rex/project-picker", ctx.client_id or "" })
  end,
}

rex.action{
  name = "lazygit_popup",
  title = "Lazygit",
  description = "lazygit in a floating pane, in the focused pane's directory",
  run = function()
    float({ 0.05, 0.05, 0.9, 0.9 }, { "lazygit" }, focused_cwd())
  end,
}

-- herdr's prefix+c asks for the tab's name straight away.
rex.action{
  name = "new_named_tab",
  title = "New Tab with Name",
  run = function()
    rex.client.queue("client.tab.new")
    rex.client.queue("client.tab.rename")
  end,
}

-- ctrl+space>space, tmux's next-layout, ported from herdr/flip: even-horizontal,
-- even-vertical, main-horizontal, main-vertical, tiled. Every layout is panes
-- grouped into columns (or rows): group heads chained one way, the rest of each
-- group the other. Panes are detached and placed back one by one, so they keep
-- their processes. Fewer than three panes only cycle the first two (the rest
-- look identical).
local function deal(ids, count)
  local groups, start = {}, 1
  for c = 1, count do
    local size = math.floor(#ids / count) + ((c <= #ids % count) and 1 or 0)
    local g = {}
    for i = start, start + size - 1 do g[#g + 1] = ids[i] end
    groups[c], start = g, start + size
  end
  return groups
end
local function each(ids) local g = {} for i, id in ipairs(ids) do g[i] = { id } end return g end
local function main(ids) return { { ids[1] }, { unpack(ids, 2) } } end
-- Rows of a near-square grid, so reading order survives the flip.
local function grid(ids) return deal(ids, math.ceil(#ids / math.ceil(math.sqrt(#ids)))) end
local H, V = "horizontal", "vertical"
local LAYOUTS = { -- name, grouping, between groups, inside a group
  { "even-horizontal", each, H, V },
  { "even-vertical", each, V, H },
  { "main-horizontal", main, V, H },
  { "main-vertical", main, H, V },
  { "tiled", grid, V, H },
}
-- ponytail: in memory, so a config reload restarts each window's cycle.
local layout_index = {}

rex.action{
  name = "next_layout",
  title = "Next Pane Layout",
  args = { window_id = "string?" }, -- defaults to the active tab
  run = function(_, args)
    local view, err = rex.session.view{}
    if err ~= nil then error(err, 0) end
    local win
    for _, w in ipairs(view.windows) do
      if w.window_id == (args.window_id or view.active_window_id) then win = w end
    end
    if not win then return end
    local leaves = {}
    local function walk(n)
      if n.block_id then leaves[#leaves + 1] = n
      elseif n.split then walk(n.split.before); walk(n.split.after) end
    end
    for _, layer in ipairs(win.layers) do
      if layer.kind == "tiled" and layer.layout then walk(layer.layout) end
    end
    if #leaves < 2 then return end
    -- Visual order (top to bottom, then left to right), not tree order.
    local function row(n) return math.floor(n.rect[2] * 1000 + 0.5) end
    table.sort(leaves, function(a, b)
      if row(a) ~= row(b) then return row(a) < row(b) end
      return a.rect[1] < b.rect[1]
    end)
    local ids = {}
    for i, n in ipairs(leaves) do ids[i] = n.block_id end

    local count = #ids > 2 and #LAYOUTS or 2
    local index = (layout_index[win.window_id] or 0) % count + 1
    layout_index[win.window_id] = index
    local name, group_by, outer, inner = unpack(LAYOUTS[index])
    local groups = {}
    for _, g in ipairs(group_by(ids)) do if #g > 0 then groups[#groups + 1] = g end end

    for i = 2, #ids do rex.session.detach_block{ block_id = ids[i] } end
    local failed
    -- Chained splits nest, so each anchor keeps 1/n of what is left: 1/n, 1/(n-1)...
    local function place(id, direction, anchor, ratio)
      local _, e = rex.session.move_block{
        block_id = id, anchor_block_id = anchor, direction = direction, ratio = ratio,
      }
      -- Never leave a pane detached (out of sight): fall back to beside the first.
      if e ~= nil then
        failed = e
        rex.session.move_block{ block_id = id, anchor_block_id = ids[1] }
      end
    end
    -- Group heads first, while each column is still a single cell.
    for g = 2, #groups do place(groups[g][1], outer, groups[g - 1][1], 1 / (#groups - g + 2)) end
    for _, group in ipairs(groups) do
      for j = 2, #group do place(group[j], inner, group[j - 1], 1 / (#group - j + 2)) end
    end
    if win.focused_block_id then rex.session.focus_block{ block_id = win.focused_block_id } end
    if failed then error(failed, 0) end
    return { layout = name }
  end,
}

-- The herdr keymap (herdr/config.toml and its cheatsheet) on the same ctrl+space
-- prefix. Herdr's agent bindings are left out on purpose: j/k focus panes here
-- (no agent list to walk) and 1..9 go to tabs (no agent-priority jump), and the
-- harness picker, background-agents popup, nvim and reviewr plugins are
-- herdr-only. Rex's own Cmd shortcuts are untouched.
local P = "ctrl+space>"
local keys = {
  -- sessions (herdr workspaces)
  { "w", "session.switch" },
  { "shift+n", "session.new" },
  { "shift+w", "session.rename" },
  { "shift+d", "session.close" },
  { "f", "project_picker" },
  -- tabs
  { "c", "new_named_tab" },
  { "n", "client.tab.next" },
  { "p", "client.tab.previous" },
  { "shift+t", "client.tab.rename" },
  { "shift+x", "client.tab.close" },
  -- panes
  { "v", "pane.split.right" },
  { "-", "pane.split.down" },
  { "h", "pane.focus.left" },
  { "j", "pane.focus.down" },
  { "k", "pane.focus.up" },
  { "l", "pane.focus.right" },
  { "tab", "pane.focus_next" },
  { "shift+tab", "pane.focus_previous" },
  { "z", "pane.zoom" },
  { "x", "pane.close" },
  { "b", "client.sidebar.toggle" },
  { "space", "next_layout" },
  -- tools and app
  { "d", "lazygit_popup" },
  { "shift+/", "client.palette.toggle" }, -- ?: herdr's help, here the palette that lists every action and key
  { "s", "client.settings" },
  { "shift+r", "client.config.reload" },
  -- ctrl+space starts every sequence, so press it twice to send one to the terminal.
  { "ctrl+space", "pane.send_key", { key = "ctrl+space" } },
}
for _, k in ipairs(keys) do rex.bind(P .. k[1], k[2], k[3]) end
for i = 1, 9 do rex.bind(P .. i, "client.tab.goto", { index = i }) end
