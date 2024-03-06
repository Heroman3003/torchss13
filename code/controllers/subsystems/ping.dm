/*!
 * Copyright (c) 2022 Aleksej Komarov
 * SPDX-License-Identifier: MIT
 */

SUBSYSTEM_DEF(ping)
	name = "Ping"
	priority = FIRE_PRIORITY_PING
	// init_stage = INITSTAGE_EARLY
	wait = 4 SECONDS
	flags = SS_NO_INIT
	runlevels = RUNLEVEL_LOBBY | RUNLEVELS_DEFAULT
	var/list/currentrun = list()

/datum/controller/subsystem/ping/stat_entry()
	..("P:[GLOB.clients.len]")

/datum/controller/subsystem/ping/fire(resumed = FALSE)
	// Prepare the new batch of clients
	if (!resumed)
		src.currentrun = GLOB.clients.Copy()

	// De-reference the list for sanic speeds
	var/list/currentrun = src.currentrun

	while (currentrun.len)
		var/client/client = currentrun[currentrun.len]
		currentrun.len--

		if(client)
			if(!client.is_preference_enabled(/datum/client_preference/vchat_enable))
				winset(client, "output", "on-show=&is-disabled=0&is-visible=1")
				winset(client, "browseroutput", "is-disabled=1;is-visible=0")
				client.tgui_panel.oldchat = TRUE

			if (client?.tgui_panel?.is_ready())
				// Send a soft ping
				client.tgui_panel.window.send_message("ping/soft", list(
					// Slightly less than the subsystem timer (somewhat arbitrary)
					// to prevent incoming pings from resetting the afk state
					"afk" = client.is_afk(3.5 SECONDS),
				))

		if (MC_TICK_CHECK)
			return
