#define SYNTHESIZER_MAX_CARTRIDGES 40
#define SYNTHESIZER_MAX_RECIPES 20
#define SYNTHESIZER_MAX_QUEUE 40

// Recipes are stored as a list which alternates between chemical id's and volumes to add.

// TODO: 
// Design UI 
// TGUI procs
// Create procs to take synthesis steps as an input and stores as a 1 click synthesis button. Needs name, expected output volume. 
// DONE Create procs to actually perform the reagent transfer/etc. for a synthesis, reading the stored synthesis steps. 
// Implement a step-mode where the player manually clicks on each step and an expert mode where players input a comma-delineated list. 
// DONE Add process() code which makes the machine actually work. Perhaps tie a boolean and single start proc into process().
// Give the machine queue-behavior which allows players to queue up multiple recipes, even when the machine is busy. Reference protolathe code.
// Give the machine a way to stop a synthesis and purge/bottle the reaction vessel. 
// Perhaps use recipes as a "ID" "num" "ID" "num" list to avoid using multiple lists.
// Panel open button.
// DONE Code for power usage.
// Update_icon() overrides.
// Underlay code for the reaction vessel.
// Add an eject catalyst bottle button.
// Make sure recipes can only be removed when the machine is idle. Adding should be fine.
// May need yet another list which is just strings which match recipe ID's. 

/obj/machinery/chemical_synthesizer
	name = "chemical synthesizer"
	desc = "A programmable machine capable of automatically synthesizing medicine."
	icon = 'icons/obj/chemical_ch.dmi'
	icon_state = "synth_idle_bottle"

	use_power = USE_POWER_IDLE
	power_channel = EQUIP
	idle_power_usage = 100
	active_power_usage = 150
	anchored = TRUE
	unacidable = TRUE
	panel_open = TRUE

	var/busy = FALSE
	var/expert_mode = FALSE // Toggle between click-step input and comma-delineated text input for creating recipes.
	var/use_catalyst = TRUE // Determines whether or not the catalyst will be added to reagents while processing a recipe.
	var/delay_modifier = 3 // This is multiplied by the volume of a step to determine how long each step takes. Bigger volume = slower.
	var/obj/item/weapon/reagent_containers/glass/catalyst = null // This is where the user adds catalyst. Usually phoron.

	var/list/recipes = list(list()) // This holds chemical recipes up to a maximum determined by SYNTHESIZER_MAX_RECIPES. Two-dimensional.
	var/list/queue = list() // This holds the recipe id's for queued up recipes.
	var/list/catalyst_ids = list() // This keeps track of the chemicals in the catalyst to remove before bottling. 
	var/list/cartridges = list() // Associative, label -> cartridge

	var/list/spawn_cartridges = list(
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/hydrogen,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/lithium,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/carbon,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/nitrogen,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/oxygen,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/fluorine,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/sodium,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/aluminum,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/silicon,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/phosphorus,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/sulfur,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/chlorine,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/potassium,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/iron,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/copper,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/mercury,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/radium,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/water,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/ethanol,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/sugar,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/sacid,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/tungsten,
			/obj/item/weapon/reagent_containers/chem_disp_cartridge/calcium
		)

	var/_recharge_reagents = TRUE
	var/process_tick = 0
	var/list/dispense_reagents = list(
		"hydrogen", "lithium", "carbon", "nitrogen", "oxygen", "fluorine", "sodium",
		"aluminum", "silicon", "phosphorus", "sulfur", "chlorine", "potassium", "iron",
		"copper", "mercury", "radium", "water", "ethanol", "sugar", "sacid", "tungsten", "calcium"
		)

/obj/machinery/chemical_synthesizer/Initialize()
	. = ..()
	// Create the reagents datum which will act as the machine's reaction vessel.
	create_reagents(600)
	catalyst = new /obj/item/weapon/reagent_containers/glass/beaker(src)

	if(spawn_cartridges)
		for(var/type in spawn_cartridges)
			add_cartridge(new type(src))
		panel_open = FALSE

/obj/machinery/chemical_synthesizer/examine(mob/user)
	. = ..()
	if(panel_open)
		. += "It has [cartridges.len] cartridges installed, and has space for [SYNTHESIZER_MAX_CARTRIDGES - cartridges.len] more."

/obj/machinery/chemical_synthesizer/proc/add_cartridge(obj/item/weapon/reagent_containers/chem_disp_cartridge/C, mob/user)
	if(!panel_open)
		if(user)
			to_chat(user, "<span class='warning'>\The panel is locked!</span>")
		return

	if(!istype(C))
		if(user)
			to_chat(user, "<span class='warning'>\The [C] will not fit in \the [src]!</span>")
		return

	if(cartridges.len >= SYNTHESIZER_MAX_CARTRIDGES)
		if(user)
			to_chat(user, "<span class='warning'>\The [src] does not have any slots open for \the [C] to fit into!</span>")
		return

	if(!C.label)
		if(user)
			to_chat(user, "<span class='warning'>\The [C] does not have a label!</span>")
		return

	if(cartridges[C.label])
		if(user)
			to_chat(user, "<span class='warning'>\The [src] already contains a cartridge with that label!</span>")
		return

	if(user)
		user.drop_from_inventory(C)
		to_chat(user, "<span class='notice'>You add \the [C] to \the [src].</span>")

	C.loc = src
	cartridges[C.label] = C
	cartridges = sortAssoc(cartridges)
	SStgui.update_uis(src)

/obj/machinery/chemical_synthesizer/proc/remove_cartridge(label)
	. = cartridges[label]
	cartridges -= label
	SStgui.update_uis(src)

/obj/machinery/chemical_synthesizer/attackby(obj/item/weapon/W, mob/user)
	// Why do so many people code in wrenching when there's already a proc for it?
	if(!busy && default_unfasten_wrench(user, W, 40))
		return

	if(istype(W, /obj/item/weapon/reagent_containers/chem_disp_cartridge))
		add_cartridge(W, user)
		return

	// But we won't use the screwdriver proc because chem dispenser behavior.
	if(panel_open && W.is_screwdriver())
		var/label = tgui_input_list(user, "Which cartridge would you like to remove?", "Chemical Synthesizer", cartridges)
		if(!label) 
			return
		var/obj/item/weapon/reagent_containers/chem_disp_cartridge/C = remove_cartridge(label)
		if(C)
			to_chat(user, "<span class='notice'>You remove \the [C] from \the [src].</span>")
			C.loc = loc
			playsound(src, W.usesound, 50, 1)
			return

	// We don't need a busy check here as the catalyst slot must be occupied for the machine to function. 
	if(istype(W, /obj/item/weapon/reagent_containers/glass))
		if(catalyst)
			to_chat(user, "<span class='warning'>There is already \a [catalyst] in \the [src] catalyst slot!</span>")
			return

		var/obj/item/weapon/reagent_containers/RC = W

		if(!RC.is_open_container())
			to_chat(user, "<span class='warning'>You don't see how \the [src] could extract reagents from \the [RC].</span>")
			return

		catalyst =  RC
		user.drop_from_inventory(RC)
		RC.loc = src
		to_chat(user, "<span class='notice'>You set \the [RC] on \the [src].</span>")
		update_icon()
		return

	return ..()

// More stolen chemical_dispenser code.
/obj/machinery/chemical_synthesizer/process()
	if(!_recharge_reagents)
		return
	if(stat & (BROKEN|NOPOWER))
		return
	if(--process_tick <= 0)
		process_tick = 15
		. = 0
		for(var/id in dispense_reagents)
			var/datum/reagent/R = SSchemistry.chemical_reagents[id]
			if(!R)
				stack_trace("[src] at [x],[y],[z] failed to find reagent '[id]'!")
				dispense_reagents -= id
				continue
			var/obj/item/weapon/reagent_containers/chem_disp_cartridge/C = cartridges[R.name]
			if(C && C.reagents.total_volume < C.reagents.maximum_volume)
				var/to_restore = min(C.reagents.maximum_volume - C.reagents.total_volume, 5)
				use_power(to_restore * 500)
				C.reagents.add_reagent(id, to_restore)
				. = 1
		if(.)
			SStgui.update_uis(src)
/*
/obj/machinery/chemical_synthesizer/tgui_interact(mob/user, datum/tgui/ui = null)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ChemSynthesizer", ui_title)
		ui.open()

/obj/machinery/chemical_synthesizer/tgui_data(mob/user)
	var/data[0]

/obj/machinery/chemical_synthesizer/tgui_act(action, params)
	if(..())
		return TRUE

	. = TRUE
	switch(action)



	add_fingerprint(usr)
*/
/obj/machinery/chemical_synthesizer/attack_ghost(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return
	tgui_interact(user)

/obj/machinery/chemical_synthesizer/attack_ai(mob/user)
	attack_hand(user)

/obj/machinery/chemical_synthesizer/attack_hand(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return
	tgui_interact(user)

// This proc handles adding the catalyst starting the synthesizer's queue. 
/obj/machinery/chemical_synthesizer/proc/start_queue(mob/user)
	if(stat & (BROKEN|NOPOWER))
		return

	if(!queue)
		to_chat(user, "You can't start an empty queue!")
		return

	if(!catalyst)
		to_chat(user, "Place a bottle in the catalyst slot before starting the queue!")
		return

	if(panel_open)
		to_chat(user, "Close the panel before starting the queue!")
		return

	if(reagents.total_volume)
		to_chat(user, "Empty the reaction vessel before starting the queue!")
		return

	busy = TRUE
	use_power = USE_POWER_ACTIVE
	if(use_catalyst)
		// Populate the list of catalyst chems. This is important when it's time to bottle_product().
		for(var/datum/reagent/chem in catalyst.reagents.reagent_list)
			catalyst_ids += chem.id

		// Transfer the catalyst to the synthesizer's reagent holder.
		catalyst.reagents.trans_to_holder(src.reagents, catalyst.reagents.total_volume)

	// Start the first recipe in the queue, starting with step 1.
	follow_recipe(queue[1], 1)


// This proc controls the timing for each step in a reaction. Step is the index for the current chem of our recipe, step + 1 is the volume of said chem.
/obj/machinery/chemical_synthesizer/proc/follow_recipe(var/r_id, var/step as num)
	if(stat & (BROKEN|NOPOWER))
		stall()
		return

	icon_state = "synth_working"
	if(!step)
		step = 1

	// The time between each step is the volume required by a step multiplied by the delay_modifier (in ticks/deciseconds). 
	addtimer(CALLBACK(src, .proc/perform_reaction, r_id, step), recipes[r_id][step + 1] * delay_modifier)

// This proc carries out the actual steps in each reaction. 
/obj/machinery/chemical_synthesizer/proc/perform_reaction(var/r_id, var/step as num)
	if(stat & (BROKEN|NOPOWER))
		stall()
		return

	//Let's store these as temporary variables to make the code more readable.
	var/label = recipes[r_id][step]
	var/quantity = recipes[r_id][step+1]

	// If we're missing a cartridge somehow or lack space for the next step, stall. It's now up to the chemist to fix this. 
	if(!cartridges[label])
		visible_message("<span class='warning'>The [src] beeps loudly, flashing a 'cartridge missing' error!</span>", "You hear loud beeping!")
		playsound(src, 'sound/weapons/smg_empty_alarm.ogg', 40)
		stall()
		return

	if(quantity > reagents.get_free_space())
		visible_message("<span class='warning'>The [src] beeps loudly, flashing a 'maximum volume exceeded' error!</span>", "You hear loud beeping!")
		playsound(src, 'sound/weapons/smg_empty_alarm.ogg', 40)
		stall()
		return

	// If there isn't enough reagent left for this step, try again in a minute.
	var/obj/item/weapon/reagent_containers/chem_disp_cartridge/C = cartridges[label]
	if(quantity > C.reagents.total_volume)
		visible_message("<span class='notice'>The [src] flashes an 'insufficient reagents' warning.</span>")
		addtimer(CALLBACK(src, .proc/perform_reaction, r_id, step), 1 MINUTE)
		return

	// After all this mess of code, we reach the line where the magic happens. 
	C.reagents.trans_to_holder(src.reagents, quantity)
	// playsound(src, 'sound/machinery/HPLC_binary_pump.ogg', 25, 1)

	// Advance to the next step in the recipe. If this is outside of the recipe's index, we're finished. Otherwise, proceed to next step.
	step += 2
	var/list/tmp = recipes[r_id]
	if(step > tmp.len)
		icon_state = "synth_finished"

		// First extract the catalyst(s), if any remain.
		if(use_catalyst)
			for(var/chem in catalyst_ids)
				var/amount = reagents.get_reagent_amount(chem)
				reagents.trans_id_to(catalyst, chem, amount)
		
		// Add a delay of 1 tick per unit of reagent. Clear the catalyst_ids. 
		catalyst_ids = list()
		var/delay = reagents.total_volume
		addtimer(CALLBACK(src, .proc/bottle_product, r_id), delay)

	else
		follow_recipe(r_id, step)

// Now that we're done, bottle up the product.
/obj/machinery/chemical_synthesizer/proc/bottle_product(var/r_id)
	if(stat & (BROKEN|NOPOWER))
		stall()
		return

	while(reagents.total_volume)
		var/obj/item/weapon/reagent_containers/glass/bottle/B = new(src.loc)
		B.name = "[r_id] bottle"
		B.pixel_x = rand(-7, 7) // random position
		B.pixel_y = rand(-7, 7)
		B.icon_state = "bottle-4"
		reagents.trans_to_obj(B, min(reagents.total_volume, MAX_UNITS_PER_BOTTLE))
		B.update_icon()
	
	// Sanity check when manual bottling is triggered.
	if(queue)
		queue -= queue[1]

	// If the queue is now empty, we're done. Otherwise, re-add catalyst and proceed to the next recipe. 
	if(queue)
		if(use_catalyst)
			for(var/datum/reagent/chem in catalyst.reagents.reagent_list)
				catalyst_ids += chem.id
			catalyst.reagents.trans_to_holder(src.reagents, catalyst.reagents.total_volume)		
		follow_recipe(queue[1], 1)

	else
		busy = FALSE
		use_power = USE_POWER_IDLE
		queue = list()
		update_icon()
		

// What happens to the synthesizer if it breaks or loses power in the middle of running. Chemists must fix things manually.
/obj/machinery/chemical_synthesizer/proc/stall()
	busy = FALSE
	use_power = USE_POWER_IDLE
	queue = list()
	catalyst_ids = list()
	update_icon()

#undef SYNTHESIZER_MAX_CARTRIDGES
#undef SYNTHESIZER_MAX_RECIPES
#undef SYNTHESIZER_MAX_QUEUE