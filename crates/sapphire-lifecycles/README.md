# sapphire-lifecycles
More lifecycles for [Mark-Marks/sapphire](https://github.com/Mark-Marks/sapphire)
- `.on_heartbeat(delta_time: number)` for `RunService.Heartbeat`
- `.on_render_stepped(delta_time: number)` for `RunService.OnRenderStepped`, client only
- `.on_stepped(time_elapsed: number, delta_time: number)` for `RunService.Stepped`
- `.on_pre_simulation(delta_time: number)` for `RunService.PreSimulation`
- `.on_post_simulation(delta_time: number)` for `RunService.PostSimulation`
- `.on_pre_animation(delta_time: number)` for `RunService.PreAnimation`, client only
- `.on_pre_render(delta_time: number)` for `RunService.PreRender`, client only
- `.on_player_added(player: Player)` for `Players.PlayerAdded`
- `.on_player_removing(player: Player)` for `Players.PlayerRemoving`
- `.on_game_shutdown()` for `game.Close`
