////////////////////////////////////////////
// POWERNET DATUM
// each contiguous network of cables & nodes
/////////////////////////////////////
/datum/powernet
	var/number					// unique id
	var/list/cables = list()	// all cables & junctions
	var/list/nodes = list()		// all connected machines
	var/list/providers = list() // all connected machines supplying power

	var/load = 0				  // the current load on the powernet, increased by each machine at processing
	var/avail = 0				  //...the current available power in the powernet
	var/viewavail = 0			// the available power as it appears on the power console (gradually updated)
	var/viewload = 0			// the load as it appears on the power console (gradually updated)
	var/lastupdated = 0   // Last time we were updated, in ticks

/datum/powernet/New()
	SSmachines.powernets += src
	lastupdated = world.time

/datum/powernet/Destroy()
	//Go away references, you suck!
	for(var/obj/structure/cable/C in cables)
		cables -= C
		C.powernet = null
	for(var/obj/machinery/power/M in nodes)
		nodes -= M
		M.powernet = null

	SSmachines.powernets -= src
	return ..()

/datum/powernet/proc/is_empty()
	return !cables.len && !nodes.len

//remove a cable from the current powernet
//if the powernet is then empty, delete it
//Warning : this proc DON'T check if the cable exists
/datum/powernet/proc/remove_cable(obj/structure/cable/C)
	cables -= C
	C.powernet = null
	if(is_empty())//the powernet is now empty...
		qdel(src)///... delete it
	else
		reload_providers()

//add a cable to the current powernet
//Warning : this proc DON'T check if the cable exists
/datum/powernet/proc/add_cable(obj/structure/cable/C)
	if(C.powernet)// if C already has a powernet...
		if(C.powernet == src)
			return
		else
			C.powernet.remove_cable(C) //..remove it
	C.powernet = src
	cables +=C

//remove a power machine from the current powernet
//if the powernet is then empty, delete it
//Warning : this proc DON'T check if the machine exists
/datum/powernet/proc/remove_machine(obj/machinery/power/M)
	nodes -=M
	M.powernet = null
	if(is_empty())//the powernet is now empty...
		qdel(src)///... delete it
	else
		reload_providers()


//add a power machine to the current powernet
//Warning : this proc DON'T check if the machine exists
/datum/powernet/proc/add_machine(obj/machinery/power/M)
	if(M.powernet)// if M already has a powernet...
		if(M.powernet == src)
			return
		else
			M.disconnect_from_network()//..remove it
	M.powernet = src
	nodes[M] = M

/datum/powernet/proc/reload_providers()
	avail = 0
	providers.Cut()
	for(var/obj/machinery/power/M in nodes)
		if(M.joule_buffer > 0)
			avail += M.joule_buffer
			providers |= M

//handles the power changes in the powernet
//called every ticks by the powernet controller
/datum/powernet/proc/reset()
	var/deltaT = (world.time - lastupdated) / 10 //Time change in seconds
	lastupdated = world.time

	// update power consoles. joules / seconds = watts
	viewavail = round((avail + load) / deltaT)
	viewload = round(load / deltaT)

	// reset the powernet
	load = 0

/datum/powernet/proc/provide_joules(var/obj/machinery/power/P, var/joules)
	providers |= P //Add it to providers if it isn't there already
	avail += joules

// Handles the consumption of power from the power net
// Returns the number of joules consumed
/datum/powernet/proc/draw_joules(var/joules, var/draw_partial = FALSE)
	if(providers.len == 0)
		return 0
	if(!draw_partial && (joules > avail)) //Don't bother trying if there isn't enough juice
		return 0 // No power has been consumed

	var/joules_consumed = 0

	//Picks a power provider at random until satisfied. For loop stops any infinite loops.
	for(var/i = providers.len; i > 0; i--)
		var/obj/machinery/power/P = pick(providers)
		var/required_power = joules - joules_consumed

		if(required_power > P.joule_buffer)
			joules_consumed += P.joule_buffer
			P.joule_buffer = 0
			providers -= P
		else
			P.joule_buffer -= required_power
			joules_consumed += required_power

	avail -= joules_consumed
	load += joules_consumed
	return joules_consumed

/datum/powernet/proc/get_electrocute_damage()
	if(avail >= 1000)
		return Clamp(round(avail/10000), 10, 90) + rand(-5,5)
	else
		return 0
