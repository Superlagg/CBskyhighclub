//Ratvarian spear: A relatively fragile spear from the Celestial Derelict. Deals extreme damage to silicons and enemy cultists, but doesn't last long when summoned.
/obj/item/clockwork/weapon/ratvarian_spear
	name = "ratvarian spear"
	desc = "A razor-sharp spear made of brass. It thrums with barely-contained energy."
	clockwork_desc = "A powerful spear of Ratvarian making. It's more effective against enemy cultists and silicons."
	icon_state = "ratvarian_spear"
	inhand_icon_state = "ratvarian_spear"
	force = 15 //Extra damage is dealt to targets in attack()
	throwforce = 25
	sharpness = SHARP_POINTY
	attack_verb = list("stabbed", "poked", "slashed")
	hitsound = 'sound/weapons/bladeslice.ogg'
	w_class = WEIGHT_CLASS_BULKY
	block_parry_data = /datum/block_parry_data/ratvarian_spear
	item_flags = ITEM_CAN_PARRY
	var/bonus_burn = 5

/obj/item/clockwork/weapon/ratvarian_spear/ratvar_act()
	if(GLOB.ratvar_awakens) //If Ratvar is alive, the spear is extremely powerful
		force = 20
		bonus_burn = 10
		throwforce = 40
	else
		force = initial(force)
		bonus_burn = initial(bonus_burn)
		throwforce = initial(throwforce)

/obj/item/clockwork/weapon/ratvarian_spear/examine(mob/user)
	. = ..()
	if(is_servant_of_ratvar(user) || isobserver(user))
		. += "<span class='inathneq_small'>Attacks on living non-Servants will generate <b>[bonus_burn]</b> units of vitality.</span>"
		if(!iscyborg(user))
			. += span_brass("Throwing the spear will do massive damage, break the spear, and knock down the target.")

/obj/item/clockwork/weapon/ratvarian_spear/attack(mob/living/target, mob/living/carbon/human/user)
	. = ..()
	if(!QDELETED(target) && target.stat != DEAD && !target.anti_magic_check(chargecost = 0) && !is_servant_of_ratvar(target)) //we do bonus damage on attacks unless they're a servant, have a null rod, or are dead
		var/bonus_damage = bonus_burn //normally a total of 20 damage, 30 with ratvar
		if(issilicon(target))
			target.visible_message(span_warning("[target] shudders violently at [src]'s touch!"), span_userdanger("ERROR: Temperature rising!"))
			bonus_damage *= 5 //total 40 damage on borgs, 70 with ratvar
		else if(iscultist(target) || isconstruct(target))
			to_chat(target, span_userdanger("My body flares with agony at [src]'s presence!"))
			bonus_damage *= 3 //total 30 damage on cultists, 50 with ratvar
		GLOB.clockwork_vitality += max(0, target.adjustFireLoss(bonus_damage)) //adds the damage done to existing vitality

/obj/item/clockwork/weapon/ratvarian_spear/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	var/turf/T = get_turf(hit_atom)
	if(isliving(hit_atom))
		var/mob/living/L = hit_atom
		if(is_servant_of_ratvar(L))
			if(L.put_in_active_hand(src))
				L.visible_message(span_warning("[L] catches [src] out of the air!"))
			else
				L.visible_message(span_warning("[src] bounces off of [L], as if repelled by an unseen force!"))
		else if(!..())
			if(!L.anti_magic_check())
				if(issilicon(L))
					L.DefaultCombatKnockdown(100)
				else if(iscultist(L))
					L.confused += clamp(10 - L.confused, 0, 5) // Spearthrow now confuses enemy cultists + just deals extra damage / sets on fire instead of hardstunning + damage
					to_chat(L, "<span class ='userdanger'>[src] crashes into you with burning force, sending you reeling!</span>")
					L.adjust_fire_stacks(2)
					L.DefaultCombatKnockdown(1)
					L.IgniteMob()
				else
					L.DefaultCombatKnockdown(40)
				GLOB.clockwork_vitality += L.adjustFireLoss(bonus_burn * 3) //normally a total of 40 damage, 70 with ratvar
			break_spear(T)
	else
		..()

/obj/item/clockwork/weapon/ratvarian_spear/proc/break_spear(turf/T)
	if(src)
		if(!T)
			T = get_turf(src)
		if(T) //make sure we're not in null or something
			T.visible_message(span_warning("[src] [pick("cracks in two and fades away", "snaps in two and dematerializes")]!"))
			new /obj/effect/temp_visual/ratvar/spearbreak(T)
		action.weapon_reset(RATVARIAN_WEAPON_COOLDOWN)

//A very short, very effective parry that counts on you predicting when the enemy will attack.
/datum/block_parry_data/ratvarian_spear
	parry_time_windup = 0 //Very good for predicting
	parry_time_active = 3 //Very short
	parry_time_spindown = 1
	parry_time_perfect = 2
	parry_efficiency_perfect = 110 //Very low leeway for counterattacks...
	parry_efficiency_considered_successful = 0.8
	parry_efficiency_to_counterattack = 1
	parry_cooldown = 15 //But also very low cooldown..
	parry_failed_stagger_duration = 2 SECONDS //And relatively small penalties for failing.
	parry_failed_clickcd_duration = 1 SECONDS
