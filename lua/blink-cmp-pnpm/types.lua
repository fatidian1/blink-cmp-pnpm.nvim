---@alias PackageManager "npm" | "pnpm"

---@class NpmPackage
---@field name string
---@field description string
---@field version string
---@field date string
---@field links NpmPackageLink
---@field license string
---@field keywords string[]

---@class NpmPackageLink
---@field npm string
---@field homepage string

---@class blink-cmp-pnpm.Catalogs
---@field default table<string, string>
---@field named table<string, table<string, string>>
