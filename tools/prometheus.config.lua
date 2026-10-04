-- Prometheus' settings for every script of this repo (tools/obfuscate.sh): the Medium preset's steps, for Luau,
-- without its VM (Vmify), which miscompiled our scripts at random and made them about 3.5 times slower
return {
	LuaVersion = "LuaU",
	VarNamePrefix = "",
	NameGenerator = "MangledShuffled",
	PrettyPrint = false,
	Seed = 0,
	Steps = {
		{ Name = "EncryptStrings", Settings = {} },
		{ Name = "AntiTamper", Settings = { UseDebug = false } },
		{ Name = "ConstantArray", Settings = { Threshold = 1, StringsOnly = true, Shuffle = true, Rotate = true, LocalWrapperThreshold = 0 } },
		{ Name = "NumbersToExpressions", Settings = {} },
		{ Name = "WrapInFunction", Settings = {} },
	},
}
