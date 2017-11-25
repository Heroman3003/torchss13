
/mob/living/handle_fall(var/turf/landing)
	var/mob/drop_mob= locate(/mob, loc)

	if(locate(/obj/structure/stairs) in landing)
		for(var/atom/A in landing)
			if(!A.CanPass(src, src.loc, 1, 0))
				return FALSE
		Move(landing)
		return 1

	for(var/obj/O in loc)
		if(!O.CanFallThru(src, landing))
			return 1

	if(drop_mob && drop_mob != src && ismob(drop_mob)) //Shitload of checks. This is because the game finds various ways to screw me over.
		drop_mob.fall_impact(src)

	// Then call parent to have us actually fall
	return ..()
/mob/CheckFall(var/atom/movable/falling_atom)
	return falling_atom.fall_impact(src)
/* //Leaving this here to show my previous iterations which failed.
/mob/living/fall_impact(var/atom/hit_atom) //This is called even when a humanoid falls. Dunno why, it just does.
	if(isliving(hit_atom)) //THIS WEAKENS THE PERSON FALLING & NOMS THE PERSON FALLEN ONTO. SRC is person fallen onto.  hit_atom is the person falling. Confusing.
		var/mob/living/pred = hit_atom
		pred.visible_message("<span class='danger'>\The [pred] falls onto \the [src]! FALL IMPACT MOB</span>")
		pred.Weaken(8) //Stun the person you're dropping onto! You /are/ suffering massive damage for a single stun.
		if(isliving(hit_atom) && isliving(src))
			var/mob/living/prey = src
			if(pred.can_be_drop_pred && prey.can_be_drop_prey) //Is person falling pred & person being fallen onto prey?
				pred.feed_grabbed_to_self_falling_nom(pred,prey)
			else if(prey.can_be_drop_pred && pred.can_be_drop_prey) //Is person being fallen onto pred & person falling prey
				pred.feed_grabbed_to_self_falling_nom(prey,pred) //oh, how the tables have turned.
*/
/mob/zshadow/fall_impact(var/atom/hit_atom) //You actually "fall" onto their shadow, first.
	/*
	var/floor_below = src.loc.below //holy fuck
	for(var/mob/M in floor_below.contents)
		if(M && M != src) //THIS WEAKENS THE MOBS YOU'RE FALLING ONTO
			M.visible_message("<span class='danger'>\The [src] drops onto \the [M]! FALL IMPACT SHADOW WEAKEN 8</span>")
			M.Weaken(8)
	*/
	if(isliving(hit_atom)) //THIS WEAKENS THE PERSON FALLING & NOMS THE PERSON FALLEN ONTO. SRC is person fallen onto.  hit_atom is the person falling. Confusing.
		var/mob/living/pred = hit_atom
		pred.visible_message("<span class='danger'>\The [hit_atom] falls onto \the [src]!</span>")
		pred.Weaken(8) //Stun the person you're dropping onto! You /are/ suffering massive damage for a single stun.
		var/mob/living/prey = src.owner //The shadow's owner
		if(isliving(prey))
			if(pred.can_be_drop_pred && prey.can_be_drop_prey) //Is person falling pred & person being fallen onto prey?
				pred.feed_grabbed_to_self_falling_nom(pred,prey)
			else if(prey.can_be_drop_pred && pred.can_be_drop_prey) //Is person being fallen onto pred & person falling prey
				pred.feed_grabbed_to_self_falling_nom(prey,pred) //oh, how the tables have turned.
			else
				prey.Weaken(8) //Just fall onto them if neither of the above apply.

/mob/proc/CanZPass(atom/A, direction)
	if(z == A.z) //moving FROM this turf
		return direction == UP //can't go below
	else
		if(direction == UP) //on a turf below, trying to enter
			return 0
		if(direction == DOWN) //on a turf above, trying to enter
			return 1