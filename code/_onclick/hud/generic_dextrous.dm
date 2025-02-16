//Used for normal mobs that have hands.
/datum/hud/dextrous/New(mob/living/owner)
	..()
	var/atom/movable/screen/using

	using = new /atom/movable/screen/drop()
	using.icon = ui_style
	using.screen_loc = ui_drone_drop
	using.hud = src
	static_inventory += using

	pull_icon = new /atom/movable/screen/pull()
	pull_icon.icon = ui_style
	pull_icon.hud = src
	pull_icon.update_icon()
	pull_icon.screen_loc = ui_drone_pull
	static_inventory += pull_icon

	build_hand_slots()

	using = new /atom/movable/screen/swap_hand()
	using.icon = ui_style
	using.icon_state = "swap_1"
	using.screen_loc = ui_swaphand_position(owner,1)
	using.hud = src
	static_inventory += using

	using = new /atom/movable/screen/swap_hand()
	using.icon = ui_style
	using.icon_state = "swap_2"
	using.screen_loc = ui_swaphand_position(owner,2)
	using.hud = src
	static_inventory += using
//Coyote Add
	//Throw/catch button
	throw_icon = new /atom/movable/screen/throw_catch()
	throw_icon.icon = ui_style
	throw_icon.screen_loc = ui_drop_throw
	throw_icon.hud = src
	hotkeybuttons += throw_icon
	//Resist button
	using = new /atom/movable/screen/resist()
	using.icon = ui_style
	using.screen_loc = ui_overridden_resist
	using.hud = src
	hotkeybuttons += using
	//questbook button
	// using = new /atom/movable/screen/questbook()
	// using.icon = ui_style
	// using.screen_loc = ui_questbook_overridden
	// using.hud = src
	// hotkeybuttons += using
	//quest scanner button
	// using = new /atom/movable/screen/scannerpls()
	// using.icon = ui_style
	// using.screen_loc = ui_questscanner
	// using.hud = src
	// hotkeybuttons += using
	//Health indicator
	healths = new /atom/movable/screen/healths()
	healths.hud = src
	infodisplay += healths
	//Wield button(buggy)
	wield_button = new /atom/movable/screen/wield
	wield_button.screen_loc = ui_wield
	wield_button.hud = src
	static_inventory += wield_button
//End Coyote Add

	if(mymob.possible_a_intents)
		if(mymob.possible_a_intents.len == 4)
			// All possible intents - full intent selector
			action_intent = new /atom/movable/screen/act_intent/segmented
		else
			action_intent = new /atom/movable/screen/act_intent
			action_intent.icon = ui_style
		action_intent.icon_state = mymob.a_intent
		action_intent.hud = src
		static_inventory += action_intent


	zone_select = new /atom/movable/screen/zone_sel()
	zone_select.icon = ui_style
	zone_select.hud = src
	zone_select.update_icon()
	static_inventory += zone_select

	using = new /atom/movable/screen/area_creator
	using.icon = ui_style
	using.hud = src
	static_inventory += using

	mymob.client.screen = list()

	for(var/atom/movable/screen/inventory/inv in (static_inventory + toggleable_inventory))
		if(inv.slot_id)
			inv.hud = src
			inv_slots[inv.slot_id] = inv
			inv.update_icon()

/datum/hud/dextrous/persistent_inventory_update()
	if(!mymob)
		return
	var/mob/living/D = mymob
	if(hud_version != HUD_STYLE_NOHUD)
		for(var/obj/item/I in D.held_items)
			I.screen_loc = ui_hand_position(D.get_held_index_of_item(I))
			D.client.screen += I
	else
		for(var/obj/item/I in D.held_items)
			I.screen_loc = null
			D.client.screen -= I


//Dextrous simple mobs can use hands!
/mob/living/simple_animal/create_mob_hud()
	if(dextrous)
		hud_type = dextrous_hud_type
	return ..()
