GLOBAL_VAR_INIT(singularity_counter, 0)

#define METEOR_DISASTER_MODIFIER 0.5

////////////////////////////////////////
//Singularity beacon
////////////////////////////////////////
/obj/machinery/power/singularity_beacon
	name = "ominous beacon"
	desc = "This looks suspicious..."
	icon = 'icons/obj/singularity.dmi'
	icon_state = "beacon0"

	anchored = FALSE
	density = TRUE
	layer = BELOW_MOB_LAYER //so people can't hide it and it's REALLY OBVIOUS
	stat = 0
	verb_say = "states"
	var/cooldown = 0
	var/active = FALSE
	var/meteor_buff = FALSE
	var/icontype = "beacon"

/obj/machinery/power/singularity_beacon/proc/Activate(mob/user = null)
	if(active)
		return FALSE
	if(surplus() < 1500)
		if(user)
			to_chat(user, span_notice("The connected wire doesn't have enough current."))
		return FALSE
	if(is_station_level(z))
		increment_meteor_waves()
	for(var/obj/singularity/singulo in GLOB.singularities)
		if(singulo.z == z)
			singulo.target = src
	icon_state = "[icontype]1"
	active = TRUE
	if(user)
		to_chat(user, span_notice("I activate the beacon."))
	return TRUE

/obj/machinery/power/singularity_beacon/proc/Deactivate(mob/user)
	if(!active)
		return FALSE
	for(var/obj/singularity/singulo in GLOB.singularities)
		if(singulo.target == src)
			singulo.target = null
	icon_state = "[icontype]0"
	active = FALSE
	if(user)
		to_chat(user, span_notice("I deactivate the beacon."))
	if(meteor_buff)
		decrement_meteor_waves()
	return TRUE

/obj/machinery/power/singularity_beacon/proc/increment_meteor_waves()
	meteor_buff = TRUE
	GLOB.singularity_counter++
	for(var/datum/round_event_control/meteor_wave/W in SSevents.control)
		W.weight += round(initial(W.weight) * METEOR_DISASTER_MODIFIER)

/obj/machinery/power/singularity_beacon/proc/decrement_meteor_waves()
	meteor_buff = FALSE
	GLOB.singularity_counter--
	for(var/datum/round_event_control/meteor_wave/W in SSevents.control)
		W.weight -= round(initial(W.weight) * METEOR_DISASTER_MODIFIER)

/obj/machinery/power/singularity_beacon/attack_ai(mob/user)
	return

/obj/machinery/power/singularity_beacon/on_attack_hand(mob/user, act_intent = user.a_intent, unarmed_attack_flags)
	if(anchored)
		return active ? Deactivate(user) : Activate(user)
	else
		to_chat(user, span_warning("I need to screw the beacon to the floor first!"))

/obj/machinery/power/singularity_beacon/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/screwdriver))
		if(active)
			to_chat(user, span_warning("I need to deactivate the beacon first!"))
			return

		if(anchored)
			setAnchored(FALSE)
			to_chat(user, span_notice("I unscrew the beacon from the floor."))
			disconnect_from_network()
			return
		else
			if(!connect_to_network())
				to_chat(user, span_warning("This device must be placed over an exposed, powered cable node!"))
				return
			setAnchored(TRUE)
			to_chat(user, span_notice("I screw the beacon to the floor and attach the cable."))
			return
	else
		return ..()

/obj/machinery/power/singularity_beacon/Destroy()
	if(active)
		Deactivate()
	return ..()

//stealth direct power usage
/obj/machinery/power/singularity_beacon/process()
	if(!active)
		return

	var/is_on_station = is_station_level(z)
	if(meteor_buff && !is_on_station)
		decrement_meteor_waves()
	else if(!meteor_buff && is_on_station)
		increment_meteor_waves()

	if(surplus() >= 1500)
		add_load(1500)
		if(cooldown <= world.time)
			cooldown = world.time + 80
			for(var/obj/singularity/singulo in GLOB.singularities)
				if(singulo.z == z)
					say("[singulo] is now [get_dist(src,singulo)] standard lengths away to the [dir2text(get_dir(src,singulo))]")
	else
		Deactivate()
		say("Insufficient charge detected - powering down")


/obj/machinery/power/singularity_beacon/syndicate
	icontype = "beaconsynd"
	icon_state = "beaconsynd0"

// SINGULO BEACON SPAWNER
/obj/item/sbeacondrop
	name = "suspicious beacon"
	icon = 'icons/obj/device.dmi'
	icon_state = "beacon"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	desc = "A label on it reads: <i>Warning: Activating this device will send a special beacon to your location</i>."
	w_class = WEIGHT_CLASS_SMALL
	var/droptype = /obj/machinery/power/singularity_beacon/syndicate


/obj/item/sbeacondrop/attack_self(mob/user)
	if(user)
		to_chat(user, span_notice("Locked In."))
		new droptype( user.loc )
		playsound(src, 'sound/effects/pop.ogg', 100, 1, 1)
		qdel(src)
	return

/obj/item/sbeacondrop/bomb
	desc = "A label on it reads: <i>Warning: Activating this device will send a high-ordinance explosive to your location</i>."
	droptype = /obj/machinery/syndicatebomb

/obj/item/sbeacondrop/powersink
	desc = "A label on it reads: <i>Warning: Activating this device will send a power draining device to your location</i>."
	droptype = /obj/item/powersink

#undef METEOR_DISASTER_MODIFIER
