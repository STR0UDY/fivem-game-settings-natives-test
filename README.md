# fivem-game-settings-natives-test

A small client resource for testing the game settings natives proposed in
[citizenfx/fivem#4313](https://github.com/citizenfx/fivem/pull/4313):

- `GET_GAME_SETTINGS`
- `GET_AVAILABLE_SCREEN_RESOLUTIONS`
- `SET_GAME_SETTING` / `CLEAR_PENDING_GAME_SETTINGS`
- `APPLY_GAME_SETTINGS`
- `GET_GAME_SETTING_REQUIRES_RESTART`

It needs a FiveM client built from that PR. On official clients, the natives don't exist yet.

## Setup

1. Build the FiveM client from the PR branch (see [`docs/building.md`](https://github.com/citizenfx/fivem/blob/master/docs/building.md)).
2. Put this folder in your server's `resources` and run `ensure fivem-game-settings-natives-test` (or add it to your `server.cfg`).
3. Connect with the dev client, open the **F8** console and run the commands below.

Results are printed to the F8 console and shown in an on-screen overlay.

## Commands

| Command | Does |
|---|---|
| `gs_get` / `gs_get <name>` | Print all settings, or one |
| `gs_res` | List the resolutions the game offers for the current monitor |
| `gs_set <name> <value>` | Stage a change |
| `gs_apply` / `gs_apply 1` | Apply staged changes; `1` also asks to save them to `settings.xml` |
| `gs_clear` | Drop staged changes |
| `gs_res_set <width> <height>` | Stage and apply a resolution (not saved) |
| `gs_restart <name>` | Whether changing a setting requires a game restart |

## Test checklist

| Step | Expected |
|---|---|
| `gs_get` | `GetGameSettings returned 53 settings`, matching the pause menu |
| `gs_res` | The same resolutions as the pause menu's resolution list |
| `gs_set MSAA 4`, then `gs_apply` | `1 (applied)`, and the change is visible in-game |
| `gs_res_set <width> <height>` (a resolution from `gs_res`) | `1 (applied)`, the display resets to the new resolution |
| `gs_res_set 1234 567` | `0 (rejected)`, nothing changes |
| `gs_restart TextureQuality` / `gs_restart MSAA` | `1` (true) / `false` |
| `gs_set TextureQuality 1`, then `gs_apply` | `2 (restart required)`, textures are not changed live |
| `gs_set MSAA 4`, `gs_apply`, then `disconnect` and rejoin, then `gs_get MSAA` | Back to its previous value: live changes are reverted when leaving the server |
| `gs_set MSAA 4`, then `gs_apply 1` | An in-game prompt asks whether this server may save your graphics settings |
| ...choose **Don't allow**, then `gs_apply 1` again | Nothing is saved, and the prompt is not shown again for this server |
| ...after restarting the game, choose **Allow** | `settings.xml` is updated, and the change is kept after leaving the server |

BOOL natives return `1`/`false` in Lua, as with other FiveM natives.
