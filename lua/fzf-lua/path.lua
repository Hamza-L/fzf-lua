local utils = require "fzf-lua.utils"

local M = {}

M.separator = function()
  return '/'
end

M.starts_with_separator = function(path)
  return path:find(M.separator()) == 1
end

M.tail = (function()
  local os_sep = M.separator()
  local match_string = '[^' .. os_sep .. ']*$'

  return function(path)
    return string.match(path, match_string)
  end
end)()

function M.to_matching_str(path)
  return path:gsub('(%-)', '(%%-)'):gsub('(%.)', '(%%.)'):gsub('(%_)', '(%%_)')
end

function M.join(paths)
  return table.concat(paths, M.separator())
end

function M.split(path)
  return path:gmatch('[^'..M.separator()..']+'..M.separator()..'?')
end

---Get the basename of the given path.
---@param path string
---@return string
function M.basename(path)
  path = M.remove_trailing(path)
  local i = path:match("^.*()" .. M.separator())
  if not i then return path end
  return path:sub(i + 1, #path)
end

function M.extension(path)
  -- path = M.basename(path)
  -- return path:match(".+%.(.*)")
  -- search for the first dotten string part up to space
  -- then match anything after the dot up to ':/\.'
  path = path:match("(%.[^ :\t\x1b]+)")
  if not path then return path end
  return path:match("^.*%.([^ :\\/]+)")
end

---Get the path to the parent directory of the given path. Returns `nil` if the
---path has no parent.
---@param path string
---@param remove_trailing boolean
---@return string|nil
function M.parent(path, remove_trailing)
  path = " " .. M.remove_trailing(path)
  local i = path:match("^.+()" .. M.separator())
  if not i then return nil end
  path = path:sub(2, i)
  if remove_trailing then
    path = M.remove_trailing(path)
  end
  return path
end

---Get a path relative to another path.
---@param path string
---@param relative_to string
---@return string
function M.relative(path, relative_to)
  local p, _ = path:gsub("^" .. M.to_matching_str(M.add_trailing(relative_to)), "")
  return p
end

function M.is_relative(path, relative_to)
  local p = path:match("^" .. M.to_matching_str(M.add_trailing(relative_to)))
  return p ~= nil
end

function M.add_trailing(path)
  if path:sub(-1) == M.separator() then
    return path
  end

  return path..M.separator()
end

function M.remove_trailing(path)
  local p, _ = path:gsub(M.separator()..'$', '')
  return p
end

function M.shorten(path, max_length)
  if string.len(path) > max_length - 1 then
    path = path:sub(string.len(path) - max_length + 1, string.len(path))
    local i = path:match("()" .. M.separator())
    if not i then
      return "…" .. path
    end
    return "…" .. path:sub(i, -1)
  else
    return path
  end
end

local function strsplit(inputstr, sep)
  local t={}
  for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
    table.insert(t, str)
  end
  return t
end

--[[ local function lastIndexOf(haystack, needle)
    local i, j
    local k = 0
    repeat
        i = j
        j, k = string.find(haystack, needle, k + 1, true)
    until j == nil
    return i
end ]]

local function lastIndexOf(haystack, needle)
    local i=haystack:match(".*"..needle.."()")
    if i==nil then return nil else return i-1 end
end

function M.entry_to_file(entry, cwd)
  local sep = ":"
  local s = strsplit(entry, sep)
  local file = s[1]:match("[^"..utils.nbsp.."]*$")
  local idx = lastIndexOf(s[1], utils.nbsp) or 0
  local noicons = string.sub(entry, idx+1)
  local line = s[2]
  local col  = s[3]
  if cwd and #cwd>0 and not M.starts_with_separator(file) then
    file = M.join({cwd, file})
    noicons = M.join({cwd, noicons})
  end
  return {
    noicons = noicons,
    path = file,
    line = line or 1,
    col  = col or 1,
  }
end

return M
