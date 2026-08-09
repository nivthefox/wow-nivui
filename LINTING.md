# Lua linting

NivUI uses [LuaCheck](https://github.com/lunarmodules/luacheck) with the repository's `.luacheckrc`. On Windows, download the official single-file `luacheck.exe` from the [latest LuaCheck release](https://github.com/lunarmodules/luacheck/releases/latest). LuaRocks is also supported:

```powershell
luarocks install luacheck
luacheck .
```

Run a downloaded Windows binary from the addon root with `& 'C:\path\to\luacheck.exe' .`.

The WoW globals in `.luacheckrc` are vendored from the retail `default.luacheckrc` release published by [LiangYuxuan/wow-addon-luacheckrc](https://github.com/LiangYuxuan/wow-addon-luacheckrc). The NivUI configuration adds:

- The `NivUI_DB` and `NivUI_CurrentProfile` saved-variable globals.
- Midnight APIs that are not yet present upstream.
- Optional third-party addon globals used for integrations.
- Narrow warning suppressions for WoW registration and underscore-prefixed unused values.

To update the global set:

1. Download the latest retail `default.luacheckrc` from the upstream releases page.
2. Replace `.luacheckrc` with that file.
3. Reapply the NivUI-specific settings and globals listed above from the previous revision.
4. Run `luacheck .` and the LuaJIT test suite.
5. Review the diff before committing so upstream changes do not remove local saved-variable or Midnight API declarations.

Local and upvalue shadowing warnings remain enabled. If WoW integration code requires an intentional exception, suppress that specific warning at the narrowest practical scope instead of disabling the warning class globally.
