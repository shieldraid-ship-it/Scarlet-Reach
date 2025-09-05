SUBSYSTEM_DEF(adjacent_air)
	name = "Atmos Adjacency"
	flags = SS_BACKGROUND
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 10
	priority = FIRE_PRIORITY_ATMOS_ADJACENCY
	var/list/queue = list()

/datum/controller/subsystem/adjacent_air/stat_entry()
	#ifdef TESTING
	..("P:[length(queue)], S:[GLOB.atmos_adjacent_savings[1]], T:[GLOB.atmos_adjacent_savings[2]]")
	#else
	..("P:[length(queue)]")
	#endif

/datum/controller/subsystem/adjacent_air/Initialize()
	while(length(queue))
		fire(mc_check = FALSE)
	return ..()

/datum/controller/subsystem/adjacent_air/fire(resumed = FALSE, mc_check = TRUE)

	var/list/queue = src.queue

	while (length(queue))
		var/turf/currT = queue[1]
		queue.Cut(1,2)

		currT.ImmediateCalculateAdjacentTurfs()

		if(mc_check)
			if(MC_TICK_CHECK)
				break
		else
			CHECK_TICK

/atom/var/CanAtmosPass = ATMOS_PASS_YES
/atom/var/CanAtmosPassVertical = ATMOS_PASS_YES
/atom/proc/CanAtmosPass(turf/T)
	switch (CanAtmosPass)
		if (ATMOS_PASS_PROC)
			return ATMOS_PASS_YES
		if (ATMOS_PASS_DENSITY)
			return !density
		else
			return CanAtmosPass
/turf
	//list of open turfs adjacent to us
	var/list/atmos_adjacent_turfs
	///the chance this turf has to spread, basically 3% by default
	var/spread_chance = 0
	///means fires last at base 15 seconds
	var/burn_power = 0
	var/obj/effect/abstract/liquid_turf/liquids
	var/liquid_height = 0
	var/turf_height = 0
	var/path_weight = 0

/turf/open
	var/obj/effect/hotspot/active_hotspot
/turf/CanAtmosPass = ATMOS_PASS_NO
/turf/CanAtmosPassVertical = ATMOS_PASS_NO
/turf/open/CanAtmosPass = ATMOS_PASS_PROC
/turf/open/CanAtmosPassVertical = ATMOS_PASS_PROC
/turf/open/CanAtmosPass(turf/T, vertical = FALSE)
	var/dir = vertical? get_dir_multiz(src, T) : get_dir(src, T)
	var/R = FALSE
	if(vertical && !(zAirOut(dir, T) && T.zAirIn(dir, src)))
		R = TRUE
	if(blocks_air || T.blocks_air)
		R = TRUE
	if (T == src)
		return !R
	for(var/obj/O in contents+T.contents)
		var/turf/other = (O.loc == src ? T : src)
		if(!(vertical? (CANVERTICALATMOSPASS(O, other)) : (CANATMOSPASS(O, other))))
			R = TRUE
	return !R
/turf/proc/ImmediateCalculateAdjacentTurfs()
	var/canpass = CANATMOSPASS(src, src)
	var/canvpass = CANVERTICALATMOSPASS(src, src)
	for(var/direction in GLOB.cardinals_multiz)
		var/turf/T = get_step_multiz(src, direction)
		if(!isopenturf(T))
			continue
		if(!(blocks_air || T.blocks_air) && ((direction & (UP|DOWN))? (canvpass && CANVERTICALATMOSPASS(T, src)) : (canpass && CANATMOSPASS(T, src))) )
			LAZYINITLIST(atmos_adjacent_turfs)
			LAZYINITLIST(T.atmos_adjacent_turfs)
			atmos_adjacent_turfs[T] = TRUE
			T.atmos_adjacent_turfs[src] = TRUE
		else
			if (atmos_adjacent_turfs)
				atmos_adjacent_turfs -= T
			if (T.atmos_adjacent_turfs)
				T.atmos_adjacent_turfs -= src
			UNSETEMPTY(T.atmos_adjacent_turfs)
	UNSETEMPTY(atmos_adjacent_turfs)
	src.atmos_adjacent_turfs = atmos_adjacent_turfs
//returns a list of adjacent turfs that can share air with this one.
//alldir includes adjacent diagonal tiles that can share
//	air with both of the related adjacent cardinal tiles
/turf/proc/GetAtmosAdjacentTurfs(alldir = 0)
	var/adjacent_turfs
	air_update_turf(TRUE) // since no atmos subsystem, we need to generate turf atmos adjacency manually
	if(length(atmos_adjacent_turfs))
		adjacent_turfs = atmos_adjacent_turfs.Copy()
	else
		return null
	if (!alldir)
		return adjacent_turfs
	var/turf/curloc = src
	for (var/direction in GLOB.diagonals_multiz)
		var/matchingDirections = 0
		var/turf/S = get_step_multiz(curloc, direction)
		if(!S)
			continue
		for (var/checkDirection in GLOB.cardinals_multiz)
			var/turf/checkTurf = get_step(S, checkDirection)
			if(!S.atmos_adjacent_turfs || !S.atmos_adjacent_turfs[checkTurf])
				continue
			if (adjacent_turfs[checkTurf])
				matchingDirections++
			if (matchingDirections >= 2)
				adjacent_turfs += S
				break
	return adjacent_turfs
/atom/proc/air_update_turf(command = 0)
	if(!isturf(loc) && command)
		return
	var/turf/T = get_turf(loc)
	T.air_update_turf(command)
/turf/air_update_turf(command = 0)
	if(command)
		ImmediateCalculateAdjacentTurfs()
/atom/movable/proc/move_update_air(turf/T)
	if(isturf(T))
		T.air_update_turf(1)
	air_update_turf(1)

///////////////////////////////////////////
///STATUS EFFECT FLYING BASED CLIMBING///
////////////////////////////////////////

/*
/turf/proc/randysandy_climb(mob/user, turf/climb_target) // lfwb
	var/mob/living/carbon/human/climber = user
	if(istype(climb_target, /turf/open/transparent/openspace))
		climber.apply_status_effect(/datum/status_effect/debuff/active_climbing)
	else
		climber.remove_status_effect(/datum/status_effect/debuff/active_climbing)

/turf/open/transparent/openspace/Entered(atom/movable/AM)
	. = ..()
	if(isliving(AM) && !AM.throwing)
		if(ishuman(AM))
			var/mob/living/carbon/human/climber = AM
			var/list/valid_climbs = list()
			for(var/turf/closed/valid_climb_target in range(1, climber.loc))
				if(valid_climb_target.wallclimb)
					valid_climbs += valid_climb_target
			if(!valid_climbs.len)
				to_chat(climber, span_warningbig("YOU FELL OFF!"))
				climber.remove_status_effect(/datum/status_effect/debuff/active_climbing)
				zFall(climber)
				climber.apply_damage(5, BURN, BODY_ZONE_CHEST, forced = TRUE)
				to_chat(climber, span_warningbig("The water seeps into my pores. I am crumbling!"))
*/

/////////////////////////////////////////////////////////////////////////////////
///LIFEWEB-LIKE CLIMBING, DRAG AND DROP URSELF ONTO AN OPENSPACE TURF CHUDDIE///
///////////////////////////////////////////////////////////////////////////////

/turf/open/transparent/openspace/MouseDrop_T(atom/movable/O, mob/user)
	. = ..()
	if(user == O && isliving(O))
		var/mob/living/L = O
		if(isanimal(L))
			var/mob/living/simple_animal/A = L
			if (!A.dextrous)
				return
		if(L.mobility_flags & MOBILITY_MOVE)
			wallpress(L)
			return

/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // only cardinals, correct chat
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user // https://discord.com/channels/1389349752700928050/1389452066493169765/1413195734441922580
	if(!(climber.stat != CONSCIOUS))
		if(!(climber.movement_type == FLYING)) // if you fly then fuck off
			var/pulling = climber.pulling
			if(ismob(pulling)) // if you are grabbing someone then fuck off, could forceMove() both grabber and the grabee for fun doe
				climber.visible_message(span_info("I can't get a good grip while dragging someone."))
				return
			if(!(climber.mobility_flags & MOBILITY_STAND))
				climber.visible_message(span_info("I can't get a good grip while prone."))
				return
			var/wall2wall_dir
			var/list/adjacent_wall_list = get_adjacent_turfs(climb_target) // get and add to the list turfs centered around climb_target (turf we drag mob to) in CARDINAL (NORTH, SOUTH, WEST, EAST) directions
			var/list/adjacent_wall_list_final = list()
			var/turf/wall_for_message
			var/climbing_skill = max(climber.get_skill_level(/datum/skill/misc/climbing), SKILL_LEVEL_NOVICE)
			var/adjacent_wall_diff
			var/climber_armor_class
			var/baseline_stamina_cost = 15
			var/climb_gear_bonus = 1
			for(var/turf/closed/adjacent_wall in adjacent_wall_list) // we add any turf that is a wall, aka /turf/closed/...
				adjacent_wall_diff = adjacent_wall.climbdiff
				if(!(climbing_skill == 6))
					adjacent_wall_diff += 1
				if((adjacent_wall.wallclimb) && (climbing_skill >= adjacent_wall_diff)) // if the wall has a climbable var TRUE and we got the skill, then we do the following shit
					adjacent_wall_list_final += adjacent_wall
					wall_for_message = pick(adjacent_wall_list_final) // if we are shimmying between 2 climbable walls, then we just pick one along which our sprite and message will be adjusted
					wall2wall_dir = get_dir(climb_target, wall_for_message)
			if(!adjacent_wall_list_final.len) // if there are no /turf/closed WALLS or none of the WALLS have wallclimb set to TRUE, then the list will be empty so we can't climb there
				to_chat(climber, span_warningbig("I can't climb there!"))
			else
				climber.visible_message(span_info("[climber] climbs along [wall_for_message]..."))
				climber_armor_class = climber.highest_ac_worn()
				if(!(climber_armor_class <= ARMOR_CLASS_LIGHT))
					climber.visible_message(span_danger("The armor weighs me down!"))
				else
					climber.movement_type = FLYING // the way this works is that we only really ever fall if we enter the open space turf with GROUND move type, otherwise we can just hover over indefinetely
				if((istype(climber.backr, /obj/item/clothing/climbing_gear)) || (istype(climber.backl, /obj/item/clothing/climbing_gear)))
					climb_gear_bonus = 2
				var/stamina_cost_final = round(((baseline_stamina_cost / climbing_skill) / climb_gear_bonus), 1)
				climber.stamina_add(stamina_cost_final) // eat some of climber's stamina when we move onto the next tile
				climber.apply_status_effect(/datum/status_effect/debuff/climbing_lfwb) // continious drain of STAMINA and checks to remove the status effect if we are on solid stuff or branches
				climber.forceMove(climb_target) // while our MOVEMENT TYPE is FLYING, we move onto next tile and can't fall cos of the flying
				climber.movement_type = GROUND // if we move and it's an empty space tile, we fall. otherwise we either just walk into a wall along which we climb and don't fall, or walk onto a solid turf, like... floor or water
				climber.update_wallpress_slowdown()
				climber.wallpressed = wall2wall_dir // we set our wallpressed flag to TRUE and regain blue bar somewhat, might wanna remove dat idk
				switch(wall2wall_dir)// we are pressed against the wall after all that shit and are facing it, also hugging it too bcoz sou
					if(NORTH)
						climber.setDir(NORTH)
						climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
					if(SOUTH)
						climber.setDir(SOUTH)
						climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
//						climber.visible_message(span_info("SOUTH")) // debug msg
					if(EAST)
						climber.setDir(EAST)
						climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
					if(WEST)
						climber.setDir(WEST)
						climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
