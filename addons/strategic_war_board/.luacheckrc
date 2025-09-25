std = "max"
unused_args = false
globals = {
  "ENT", "AddCSLuaFile", "include", "util", "net", "vgui", "language",
  "CLIENT", "SERVER", "IsValid"
}
files["lua/**.lua"] = { ignore = { "211/empty_block" } }
