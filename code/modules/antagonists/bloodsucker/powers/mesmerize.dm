
//	* MEZMERIZE
//		LOVE:		Target falls in love with you. Being harmed directly causes them harm if they see it?
//		STAY:		Target will do everything they can to stand in the same place.
//		FOLLOW:		Target follows you, spouting random phrases from their history (or maybe Poly's or NPC's vocab?)
//		ATTACK:		Target finds a nearby non-Bloodsucker victim to attack.

/datum/action/bloodsucker/targeted/mesmerize
	name = "Mesmerize"
	desc = "Dominate the mind of a mortal who can see your eyes."
	button_icon_state = "power_mez"
	bloodcost = 30
	cooldown = 300
	target_range = 2
	power_activates_immediately = TRUE
	message_Trigger = "Whom will you subvert to your will?"
	must_be_capacitated = TRUE
	bloodsucker_can_buy = TRUE
	var/success

/datum/action/bloodsucker/targeted/mesmerize/CheckCanUse(display_error)
	. = ..()
	if(!.)
		return
	if(!owner.getorganslot(ORGAN_SLOT_EYES))
		if (display_error)
			to_chat(owner, span_warning("I have no eyes with which to mesmerize."))
		return FALSE
	// Check: Eyes covered?
	var/mob/living/L = owner
	if(istype(L) && L.is_eyes_covered() || !isturf(owner.loc))
		if(display_error)
			to_chat(owner, span_warning("My eyes are concealed from sight."))
		return FALSE
	return TRUE

/datum/action/bloodsucker/targeted/mesmerize/CheckValidTarget(atom/A)
	return iscarbon(A)

/datum/action/bloodsucker/targeted/mesmerize/CheckCanTarget(atom/A,display_error)
	// Check: Self
	if(A == owner)
		return FALSE
	var/mob/living/carbon/target = A // We already know it's carbon due to CheckValidTarget()

	// Bloodsucker
	if(target.mind && target.mind.has_antag_datum(ANTAG_DATUM_BLOODSUCKER))
		if (display_error)
			to_chat(owner, span_warning("Bloodsuckers are immune to [src]."))
		return FALSE
	// Dead/Unconscious
	if(target.stat > CONSCIOUS)
		if (display_error)
			to_chat(owner, span_warning("My victim is not [(target.stat == DEAD || HAS_TRAIT(target, TRAIT_FAKEDEATH))?"alive":"conscious"]."))
		return FALSE
	// Check: Target has eyes?
	if(!target.getorganslot(ORGAN_SLOT_EYES))
		if (display_error)
			to_chat(owner, span_warning("They have no eyes!"))
		return FALSE
	// Check: Target blind?
	if(target.eye_blind > 0)
		if (display_error)
			to_chat(owner, span_warning("My victim's eyes are glazed over. They cannot perceive you."))
		return FALSE
	// Check: Target See Me? (behind wall)
	if(!(owner in target.fov_view()))
		// Sub-Check: GET CLOSER
		//if (!(owner in range(target_range, get_turf(target)))
		//	if (display_error)
		//		to_chat(owner, span_warning("You're too far from your victim."))
		if(display_error)
			to_chat(owner, span_warning("You're too far outside your victim's view."))
		return FALSE

	if(target.has_status_effect(STATUS_EFFECT_MESMERIZE)) // ignores facing once the windup has started
		return TRUE

	// Check: Facing target?
	if(!is_A_facing_B(owner,target))	// in unsorted.dm
		if (display_error)
			to_chat(owner, span_warning("I must be facing your victim."))
		return FALSE
	// Check: Target facing me?
	if (CHECK_MOBILITY(target, MOBILITY_STAND) && !is_A_facing_B(target,owner))
		if(display_error)
			to_chat(owner, span_warning("My victim must be facing you to see into your eyes."))
		return FALSE
	return TRUE

/datum/action/bloodsucker/targeted/mesmerize/proc/ContinueTarget(atom/A)
	var/mob/living/carbon/target = A
	var/mob/living/L = owner

	var/cancontinue = CheckCanTarget(target)
	if(!cancontinue)
		success = FALSE
		target.remove_status_effect(STATUS_EFFECT_MESMERIZE)
		L.remove_status_effect(STATUS_EFFECT_MESMERIZE)
		DeactivatePower()
		DeactivateRangedAbility()
		StartCooldown()
		to_chat(L, span_warning("[target] has escaped your gaze!"))
		UnregisterSignal(target, COMSIG_MOVABLE_MOVED)

/datum/action/bloodsucker/targeted/mesmerize/FireTargetedPower(atom/A)
	// set waitfor = FALSE   <---- DONT DO THIS!We WANT this power to hold up ClickWithPower(), so that we can unlock the power when it's done.
	var/mob/living/carbon/target = A
	var/mob/living/L = owner
	L.face_atom(A)
	if(!istype(target))
		return
	success = TRUE
	var/power_time = 138 + level_current * 12
	target.apply_status_effect(STATUS_EFFECT_MESMERIZE, 30)
	L.apply_status_effect(STATUS_EFFECT_MESMERIZE, 30)
	RegisterSignal(target, COMSIG_MOVABLE_MOVED,PROC_REF(ContinueTarget))
	// 5 second windup
	addtimer(CALLBACK(src,PROC_REF(apply_effects), L, target, power_time), 6 SECONDS)

/datum/action/bloodsucker/targeted/mesmerize/proc/apply_effects(aggressor, victim, power_time)
	var/mob/living/carbon/target = victim
	var/mob/living/L = aggressor
	if(!success)
		return
	PowerActivatedSuccessfully() // blood & cooldown only altered if power activated successfully - less "fuck you"-y
	target.apply_status_effect(STATUS_EFFECT_MESMERIZE, power_time)
	target.face_atom(L)
	target.Stun(power_time)
	to_chat(L, span_notice("[target] is fixed in place by your hypnotic gaze."))
	target.DelayNextAction(power_time)
	spawn(power_time)
	if(istype(target) && success)
		if(istype(L) && target.stat == CONSCIOUS && (target in L.fov_view(10))) // They Woke Up! (Notice if within view)
			to_chat(L, span_warning("[target] has snapped out of their trance."))


/datum/action/bloodsucker/targeted/mesmerize/ContinueActive(mob/living/user, mob/living/target)
	return ..() && CheckCanUse() && CheckCanTarget(target)
