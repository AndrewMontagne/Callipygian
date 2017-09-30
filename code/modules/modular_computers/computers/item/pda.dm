/obj/item/device/modular_computer/pda  //Its called tablet for theme of 90ies but actually its a "big smartphone" sized
	name = "\improper PDA"
	desc = "A portable microcomputer by Thinktronic Systems, LTD. Functionality determined by a preprogrammed ROM cartridge."
	icon = 'icons/obj/pda.dmi'
	icon_state_unpowered = "pda"
	icon_state_powered = "power_light"
	icon_state_light = "light_overlay"
	icon_state_sdd = "insert_overlay"
	hardware_flag = PROGRAM_TABLET
	max_hardware_size = 1
	w_class = WEIGHT_CLASS_SMALL
	steel_sheet_cost = 1
	slot_flags = SLOT_ID | SLOT_BELT | SLOT_PDA
	has_light = TRUE //LED flashlight!
	comp_light_luminosity = 2.3 //Same as the PDA
	base_active_power_usage = 10
	base_idle_power_usage = 0 // Low power usage

	var/list/contained_item = list(/obj/item/pen, /obj/item/toy/crayon, /obj/item/lipstick, /obj/item/device/flashlight/pen, /obj/item/clothing/mask/cigarette)
	var/obj/item/inserted_item //Used for pen, crayon, and lipstick insertion or removal. Same as above.

/obj/item/device/modular_computer/pda/New()
	. = ..()
	install_component(new /obj/item/computer_hardware/processor_unit/small)
	install_component(new /obj/item/computer_hardware/battery(src, /obj/item/stock_parts/cell/computer))
	install_component(new /obj/item/computer_hardware/hard_drive/small)
	install_component(new /obj/item/computer_hardware/network_card)
	install_component(new /obj/item/computer_hardware/card_slot)
	install_cartridge()
	inserted_item = new /obj/item/pen

/obj/item/device/modular_computer/pda/proc/install_cartridge()
	var/obj/item/computer_hardware/hard_drive/cartridge = new /obj/item/computer_hardware/hard_drive/portable/cartridge
	cartridge.readonly = FALSE
	cartridge.store_file(new/datum/computer_file/program/chatclient())
	cartridge.store_file(new/datum/computer_file/program/nttransfer())
	cartridge.readonly = TRUE
	install_component(cartridge)

/obj/item/device/modular_computer/pda/verb/verb_remove_pen()
	set category = "Object"
	set name = "Remove Pen"
	set src in usr

	if(issilicon(usr))
		return

	if (usr.canUseTopic(src))
		remove_pen()

/obj/item/device/modular_computer/pda/proc/remove_pen()
	if(inserted_item)
		if(ismob(loc))
			var/mob/M = loc
			M.put_in_hands(inserted_item)
		else
			inserted_item.forceMove(get_turf(src))
		to_chat(usr, "<span class='notice'>You remove \the [inserted_item] from \the [src].</span>")
		inserted_item = null
		update_icon()
	else
		to_chat(usr, "<span class='warning'>This PDA does not have a pen in it!</span>")

/obj/item/device/modular_computer/pda/attackby(obj/item/C, mob/user, params)
	if(is_type_in_list(C, contained_item)) //Checks if there is a pen
		if(inserted_item)
			to_chat(user, "<span class='warning'>There is already \a [inserted_item] in \the [src]!</span>")
		else
			if(!user.transferItemToLoc(C, src))
				return
			to_chat(user, "<span class='notice'>You slide \the [C] into \the [src].</span>")
			inserted_item = C
			update_icon()
	return ..()

/obj/item/computer_hardware/hard_drive/portable/cartridge
	name = "\improper cartridge"
	desc = "A read-only data cartridge for portable microcomputers."
	power_usage = 0
	icon = 'icons/obj/pda.dmi'
	icon_state = "cart"
	critical = 0
	max_capacity = 16
	readonly = TRUE
