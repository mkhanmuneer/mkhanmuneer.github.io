-- Appends the shared "Let's Collaborate" CTA to the end of every page this
-- filter is applied to. Wired up once in projects/_metadata.yml, so it covers
-- every current and future project page automatically — no per-file
-- {{< include ../../_includes/_connect.html >}} line needed.
--
-- The homepage keeps its own explicit include; this filter is project-only.

local function read_file(path)
  local fh = io.open(path, "rb")
  if not fh then return nil end
  local data = fh:read("*a")
  fh:close()
  return data
end

function Pandoc(doc)
  local base = (quarto and quarto.project and quarto.project.directory) or "."
  local html = read_file(base .. "/_includes/_connect.html")
  if html and #html > 0 then
    doc.blocks:insert(pandoc.RawBlock("html", html))
  end
  return doc
end
