
/////BURN FIXING SURGERIES//////

///// Debride burnt flesh
/datum/surgery/debride
	name = "Debride infected flesh"
	steps = list(/datum/surgery_step/debride, /datum/surgery_step/dress)
	target_mobtypes = list(/mob/living/carbon/human)
	possible_locs = list(BODY_ZONE_R_ARM,BODY_ZONE_L_ARM,BODY_ZONE_R_LEG,BODY_ZONE_L_LEG,BODY_ZONE_CHEST,BODY_ZONE_HEAD)
	requires_real_bodypart = TRUE
	targetable_wound = /datum/wound/burn
	requires_trait = 1

/datum/surgery/debride/can_start(mob/living/user, mob/living/carbon/target)
	if(..())
		var/obj/item/bodypart/targeted_bodypart = target.get_bodypart(user.zone_selected)
		var/datum/wound/burn/burn_wound = targeted_bodypart.get_wound_type(targetable_wound)
		return(burn_wound && burn_wound.infestation > 0)

//SURGERY STEPS

///// Debride
/datum/surgery_step/debride
	name = "excise infection"
	implements = list(TOOL_HEMOSTAT = 100, TOOL_SCALPEL = 100, TOOL_SAW = 80, TOOL_WIRECUTTER = 60)
	time = 30
	repeatable = TRUE

/datum/surgery_step/debride/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(surgery.operated_wound)
		var/datum/wound/burn/burn_wound = surgery.operated_wound
		if(burn_wound.infestation <= 0)
			to_chat(user, span_notice("[target]'s [parse_zone(user.zone_selected)] has no infected flesh to remove!"))
			surgery.status++
			repeatable = FALSE
			return
		display_results(user, target, span_notice("I begin to excise infected flesh from [target]'s [parse_zone(user.zone_selected)]..."),
			span_notice("[user] begins to excise infected flesh from [target]'s [parse_zone(user.zone_selected)] with [tool]."),
			span_notice("[user] begins to excise infected flesh from [target]'s [parse_zone(user.zone_selected)]."))
	else
		user.visible_message(span_notice("[user] looks for [target]'s [parse_zone(user.zone_selected)]."), span_notice("I look for [target]'s [parse_zone(user.zone_selected)]..."))

/datum/surgery_step/debride/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	var/datum/wound/burn/burn_wound = surgery.operated_wound
	if(burn_wound)
		display_results(user, target, span_notice("I successfully excise some of the infected flesh from [target]'s [parse_zone(target_zone)]."),
			span_notice("[user] successfully excises some of the infected flesh from [target]'s [parse_zone(target_zone)] with [tool]!"),
			span_notice("[user] successfully excises some of the infected flesh from  [target]'s [parse_zone(target_zone)]!"))
		log_combat(user, target, "excised infected flesh in", addition="INTENT: [uppertext(user.a_intent)]")
		surgery.operated_bodypart.receive_damage(brute=3, wound_bonus=CANT_WOUND)
		burn_wound.infestation -= 4
		burn_wound.sanitization += 0.75
		if(burn_wound.infestation <= 0)
			repeatable = FALSE
	else
		to_chat(user, span_warning("[target] has no infected flesh there!"))
	return ..()

/datum/surgery_step/debride/failure(mob/user, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery, fail_prob = 0)
	..()
	display_results(user, target, span_notice("I carve away some of the healthy flesh from [target]'s [parse_zone(target_zone)]."),
		span_notice("[user] carves away some of the healthy flesh from [target]'s [parse_zone(target_zone)] with [tool]!"),
		span_notice("[user] carves away some of the healthy flesh from  [target]'s [parse_zone(target_zone)]!"))
	surgery.operated_bodypart.receive_damage(brute=rand(4,8), sharpness=TRUE)

/datum/surgery_step/debride/initiate(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, try_to_fail = FALSE)
	if(!..())
		return
	var/datum/wound/burn/burn_wound = surgery.operated_wound
	while(burn_wound && burn_wound.infestation > 0.25)
		if(!..())
			break

///// Dressing burns
/datum/surgery_step/dress
	name = "bandage burns"
	implements = list(/obj/item/stack/medical/gauze = 100, /obj/item/stack/sticky_tape/surgical = 100)
	time = 40

/datum/surgery_step/dress/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/datum/wound/burn/burn_wound = surgery.operated_wound
	if(burn_wound)
		display_results(user, target, span_notice("I begin to dress the burns on [target]'s [parse_zone(user.zone_selected)]..."),
			span_notice("[user] begins to dress the burns on [target]'s [parse_zone(user.zone_selected)] with [tool]."),
			span_notice("[user] begins to dress the burns on [target]'s [parse_zone(user.zone_selected)]."))
	else
		user.visible_message(span_notice("[user] looks for [target]'s [parse_zone(user.zone_selected)]."), span_notice("I look for [target]'s [parse_zone(user.zone_selected)]..."))

/datum/surgery_step/dress/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	var/datum/wound/burn/burn_wound = surgery.operated_wound
	if(burn_wound)
		display_results(user, target, span_notice("I successfully wrap [target]'s [parse_zone(target_zone)] with [tool]."),
			span_notice("[user] successfully wraps [target]'s [parse_zone(target_zone)] with [tool]!"),
			span_notice("[user] successfully wraps [target]'s [parse_zone(target_zone)]!"))
		log_combat(user, target, "dressed burns in", addition="INTENT: [uppertext(user.a_intent)]")
		burn_wound.sanitization += 3
		burn_wound.flesh_healing += 5
		var/obj/item/bodypart/the_part = target.get_bodypart(target_zone)
		the_part.apply_gauze(tool)
		tool.use(1)
	else
		to_chat(user, span_warning("[target] has no burns there!"))
	return ..()

/datum/surgery_step/dress/failure(mob/user, mob/living/target, target_zone, obj/item/tool, datum/surgery/surgery, fail_prob = 0)
	..()
	if(istype(tool, /obj/item/stack))
		var/obj/item/stack/used_stack = tool
		used_stack.use(1)
