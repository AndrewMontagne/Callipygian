/obj/item/tank/internals/rebreather
	name = "oxygen rebreather"
	desc = "An advanced filtering device which draws oxygen from the surrounding atmosphere."
	icon_state = "emergency"
	distribute_pressure = TANK_DEFAULT_RELEASE_PRESSURE
	force = 10
	volume = 0.25
	var/target_pressure = 250
	var/transfer_amount = 0.002
	var/gas_to_scrub = "o2"
	flags_1 = CONDUCT_1
	slot_flags = SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	force = 4

/obj/item/tank/internals/rebreather/nitrogen
  name = "nitrogen rebreather"
  desc = "An advanced filtering device which draws nitrogen from the surrounding atmosphere."
  gas_to_scrub = "n2"

/obj/item/tank/internals/rebreather/New()
  ..()
  air_contents.assert_gas(gas_to_scrub)
  air_contents.gases[gas_to_scrub][MOLES] = (target_pressure) * volume / (R_IDEAL_GAS_EQUATION * T20C)
  return

/obj/item/tank/internals/rebreather/process()
  . = ..()

  if(air_contents.return_pressure() < target_pressure)
    var/turf/open/location = get_turf(src)
    if(!istype(location))
      return

    var/datum/gas_mixture/environment = location.air
    var/available_oxygen = environment.gases[gas_to_scrub] ? environment.gases[gas_to_scrub][MOLES] : 0

    if(available_oxygen > transfer_amount)
      environment.gases[gas_to_scrub][MOLES] -= transfer_amount
      location.air_update_turf()

      air_contents.assert_gas(gas_to_scrub)
      air_contents.gases[gas_to_scrub][MOLES] += transfer_amount
