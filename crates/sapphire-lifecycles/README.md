# sapphire-lifecycles
More lifecycles for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)
- `.on_post_simulation(delta_time: number)` for `RunService.PostSimulation`
- `.on_pre_simulation(delta_time: number)` for `RunService.PreSimulation`
- `.on_pre_render(delta_time: number)` for `RunService.PreRender`, client only
- `.on_heartbeat(delta_time: number)` for `RunService.Heartbeat`
- `.on_stepped(running_for: number, delta_time: number)` for `RunService.Stepped`
- `.on_render_stepped(delta_time: number)` for `RunService.RenderStepped`, client only
- `.on_player_added(player: Player)` for `Players.PlayerAdded`, uses custom player types
- `.on_player_removing(player: Player)` for `Players.PlayerRemoving`, uses custom player types
- `.on_shutdown()` for `game:BindToClose()`
