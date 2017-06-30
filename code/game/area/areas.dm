// Areas.dm



// ===
/area
	var/global/global_uid = 0
	var/uid
	var/holomap_color	// Color of this area on the holomap. Must be a hex color (as string) or null.
	var/no_roof

/area/Initialize(mapload)
	icon_state = "white"
	layer = 10
	uid = ++global_uid
	blend_mode = BLEND_MULTIPLY

	if(!requires_power)
		power_light = 0
		power_equip = 0
		power_environ = 0

	if(dynamic_lighting)
		luminosity = 0
	else
		luminosity = 1
	if(centcomm_area)
		centcom_areas |= src
	if(station_area)
		the_station_areas |= src


	if(!requires_power || !apc)
		power_light = 0
		power_equip = 0
		power_environ = 0

	if (!mapload)
		power_change()		// all machines set to current power level, also updates lighting icon

	blend_mode = BLEND_MULTIPLY

	. = ..()

/area/proc/get_contents()
	return contents

/area/proc/get_cameras()
	. = list()
	for (var/thing in SSmachinery.all_cameras)
		var/obj/machinery/camera/C = thing
		if (!isturf(C.loc))
			continue

		if (C.loc.loc == src)
			. += C

/area/proc/atmosalert(danger_level, var/alarm_source)
	if (danger_level == 0)
		atmosphere_alarm.clearAlarm(src, alarm_source)
	else
		atmosphere_alarm.triggerAlarm(src, alarm_source, severity = danger_level)

	//Check all the alarms before lowering atmosalm. Raising is perfectly fine.
	for (var/obj/machinery/alarm/AA in src)
		if (!(AA.stat & (NOPOWER|BROKEN)) && !AA.shorted && AA.report_danger_level)
			danger_level = max(danger_level, AA.danger_level)

	if(danger_level != atmosalm)
		if (danger_level < 1 && atmosalm >= 1)
			//closing the doors on red and opening on green provides a bit of hysteresis that will hopefully prevent fire doors from opening and closing repeatedly due to noise
			air_doors_open()
		else if (danger_level >= 2 && atmosalm < 2)
			air_doors_close()

		atmosalm = danger_level
		for (var/obj/machinery/alarm/AA in src)
			AA.update_icon()

		return 1
	return 0

/area/proc/air_doors_close()
	if(!air_doors_activated)
		air_doors_activated = 1
		for(var/obj/machinery/door/firedoor/E in all_doors)
			if(!E.blocked)
				if(E.operating)
					E.nextstate = FIREDOOR_CLOSED
				else if(!E.density)
					spawn(0)
						E.close()

/area/proc/air_doors_open()
	if(air_doors_activated)
		air_doors_activated = 0
		for(var/obj/machinery/door/firedoor/E in all_doors)
			if(!E.blocked)
				if(E.operating)
					E.nextstate = FIREDOOR_OPEN
				else if(E.density)
					spawn(0)
						E.open()


/area/proc/fire_alert()
	if(!fire)
		fire = 1	//used for firedoor checks
		updateicon()
		mouse_opacity = 0
		for(var/obj/machinery/door/firedoor/D in all_doors)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = FIREDOOR_CLOSED
				else if(!D.density)
					spawn()
						D.close()

/area/proc/fire_reset()
	if (fire)
		fire = 0	//used for firedoor checks
		updateicon()
		mouse_opacity = 0
		for(var/obj/machinery/door/firedoor/D in all_doors)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = FIREDOOR_OPEN
				else if(D.density)
					spawn(0)
					D.open()

/area/proc/readyalert()
	if(!eject)
		eject = 1
		updateicon()
	return

/area/proc/readyreset()
	if(eject)
		eject = 0
		updateicon()
	return

/area/proc/partyalert()
	if (!( party ))
		party = 1
		updateicon()
		mouse_opacity = 0
	return

/area/proc/partyreset()
	if (party)
		party = 0
		mouse_opacity = 0
		updateicon()
		for(var/obj/machinery/door/firedoor/D in src)
			if(!D.blocked)
				if(D.operating)
					D.nextstate = FIREDOOR_OPEN
				else if(D.density)
					spawn(0)
					D.open()
	return

#define DO_PARTY(COLOR) animate(color = COLOR, time = 0.5 SECONDS, easing = QUAD_EASING)

/area/proc/updateicon()
	if ((fire || eject || party) && (!requires_power||power_environ) && !istype(src, /area/space))//If it doesn't require power, can still activate this proc.
		if(fire && !eject && !party)		// FIRE
			color = "#ff9292"
			animate(src)	// stop any current animations.
			animate(src, color = "#ffa5b2", time = 1 SECOND, loop = -1, easing = SINE_EASING)
			animate(color = "#ff9292", time = 1 SECOND, easing = SINE_EASING)
		else if(!fire && eject && !party)		// EJECT
			color = "#ff9292"
			animate(src)
			animate(src, color = "#bc8a81", time = 1 SECOND, loop = -1, easing = EASE_IN|CUBIC_EASING)
			animate(color = "#ff9292", time = 0.5 SECOND, easing = EASE_OUT|CUBIC_EASING)
		else if(party && !fire && !eject)		// PARTY
			color = "#ff728e"
			animate(src)
			animate(src, color = "#7272ff", time = 0.5 SECONDS, loop = -1, easing = QUAD_EASING)
			DO_PARTY("#72aaff")
			DO_PARTY("#ffc68e")
			DO_PARTY("#72c6ff")
			DO_PARTY("#ff72e2")
			DO_PARTY("#72ff8e")
			DO_PARTY("#ffff8e")
			DO_PARTY("#ff728e")
		else
			color = "#ffb2b2"
			animate(src)
			animate(src, color = "#B3DFFF", time = 0.5 SECOND, loop = -1, easing = SINE_EASING)
			animate(color = "#ffb2b2", time = 0.5 SECOND, loop = -1, easing = SINE_EASING)
	else
		animate(src, color = "#FFFFFF", time = 0.5 SECONDS, easing = QUAD_EASING)	// Stop the animation.

#undef DO_PARTY


/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(var/chan)		// return true if the area has power to given channel

	if(!requires_power)
		return 1
	if(always_unpowered)
		return 0
	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ

	return 0

// called when power status changes
/area/proc/power_change()
	for(var/obj/machinery/M in src)	// for each machine in the area
		M.power_change()			// reverify power status (to update icons etc.)
	if (fire || eject || party)
		updateicon()

/area/proc/usage(var/chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += used_light
		if(EQUIP)
			used += used_equip
		if(ENVIRON)
			used += used_environ
		if(TOTAL)
			used += used_light + used_equip + used_environ
	return used

/area/proc/clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0

/area/proc/use_power(var/amount, var/chan)
	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount


var/list/mob/living/forced_ambiance_list = new

/area/Entered(A)
	if(!istype(A,/mob/living))	return

	var/mob/living/L = A
	if(!L.ckey)	return

	if(!L.lastarea)
		L.lastarea = get_area(L.loc)
	var/area/newarea = get_area(L.loc)
	var/area/oldarea = L.lastarea
	if((oldarea.has_gravity == 0) && (newarea.has_gravity == 1) && (L.m_intent == "run")) // Being ready when you change areas gives you a chance to avoid falling all together.
		thunk(L)
		L.update_floating( L.Check_Dense_Object() )

	L.lastarea = newarea

	// Ambience goes down here -- make sure to list each area seperately for ease of adding things in later, thanks! Note: areas adjacent to each other should have the same sounds to prevent cutoff when possible.- LastyScratch
	if(!(L && L.client && (L.client.prefs.asfx_togs & ASFX_AMBIENCE)))	return

	play_ambience(L)

/area/proc/play_ambience(var/mob/living/L)
	// Ambience goes down here -- make sure to list each area seperately for ease of adding things in later, thanks! Note: areas adjacent to each other should have the same sounds to prevent cutoff when possible.- LastyScratch
	if(!(L && L.client && (L.client.prefs.toggles & SOUND_AMBIENCE)))	return

	// If we previously were in an area with force-played ambiance, stop it.
	if(L in forced_ambiance_list)
		L << sound(null, channel = 1)
		forced_ambiance_list -= L

	if(!L.client.ambience_playing)
		L.client.ambience_playing = 1
		L << sound('sound/ambience/shipambience.ogg', repeat = 1, wait = 0, volume = 35, channel = 2)

	if(forced_ambience)
		if(forced_ambience.len)
			forced_ambiance_list |= L
			L << sound(pick(forced_ambience), repeat = 1, wait = 0, volume = 25, channel = 1)
		else
			L << sound(null, channel = 1)
	else if(src.ambience.len && prob(35))
		if((world.time >= L.client.played + 600))
			var/sound = pick(ambience)
			L << sound(sound, repeat = 0, wait = 0, volume = 25, channel = 1)
			L.client.played = world.time

/area/proc/gravitychange(var/gravitystate = 0, var/area/A)
	A.has_gravity = gravitystate

	for(var/mob/M in A)
		if(has_gravity)
			thunk(M)
		M.update_floating( M.Check_Dense_Object() )

/area/proc/thunk(mob)
	if(istype(get_turf(mob), /turf/space)) // Can't fall onto nothing.
		return

	if(istype(mob,/mob/living/carbon/human/))
		var/mob/living/carbon/human/H = mob
		if(H.Check_Shoegrip(FALSE))
			return

		if(H.m_intent == "run")
			H.AdjustStunned(2)
			H.AdjustWeakened(2)
		else
			H.AdjustStunned(1)
			H.AdjustWeakened(1)
		mob << "<span class='notice'>The sudden appearance of gravity makes you fall to the floor!</span>"

/area/proc/prison_break()
	for(var/obj/machinery/power/apc/temp_apc in src)
		temp_apc.overload_lighting(70)
	for(var/obj/machinery/door/airlock/temp_airlock in src)
		temp_airlock.prison_open()
	for(var/obj/machinery/door/window/temp_windoor in src)
		temp_windoor.open()

/area/proc/has_gravity()
	return has_gravity

/area/space/has_gravity()
	return 0

/proc/has_gravity(atom/AT, turf/T)
	if(!T)
		T = get_turf(AT)
	var/area/A = get_area(T)
	if(A && A.has_gravity())
		return 1
	return 0

//A useful proc for events.
//This returns a random area of the station which is meaningful. Ie, a room somewhere

/proc/random_station_area()
	var/list/possible = list()
	for(var/Y in the_station_areas)
		for(var/areapath in typesof(Y))
			var/area/A = locate(areapath)
			if(!A)
				continue
			if(!(A.z in config.station_levels))
				continue
			if (istype(A, /area/shuttle))
				continue
			if (istype(A, /area/solar) || findtext(A.name, "solar"))
				continue
			if (istype(A, /area/constructionsite))
				continue

			//Although hostile mobs instadying to turrets is fun
			//If there's no AI they'll just be hit with stunbeams all day and spam the attack logs.
			if (istype(A, /area/turret_protected))
				continue

			possible.Add(A)

	return pick(possible)


/area/proc/random_space()
	var/list/turfs = list()
	for(var/turf/simulated/floor/F in src.contents)
		if(turf_clear(F))
			turfs += F
	if (turfs.len)
		return pick(turfs)
	else return null


// Whether the turfs in the area should be drawn onto the "base" holomap.
/area/proc/holomapAlwaysDraw()
	return TRUE

/area/shuttle/holomapAlwaysDraw()
	return FALSE
