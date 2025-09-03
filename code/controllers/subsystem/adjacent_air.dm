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
	var/mob/living/carbon/human/climber = user
	var/wall2wall_dir
	var/list/adjacent_wall_list = get_adjacent_turfs(climb_target) // get and add to the list turfs centered around climb_target (turf we drag mob to) in CARDINAL (NORTH, SOUTH, WEST, EAST) directions
	var/list/adjacent_wall_list_final = list()
	var/turf/wall_for_message
	for(var/turf/closed/adjacent_wall in adjacent_wall_list) // we add any turf that is a wall, aka /turf/closed/...
		if(adjacent_wall.wallclimb) // if the wall has a climbable var TRUE, then we do the following shit
			adjacent_wall_list_final += adjacent_wall
			wall_for_message = pick(adjacent_wall_list_final) // if we are shimmying between 2 climbable walls, then we just pick one along which our sprite and message will be adjusted
			wall2wall_dir = get_dir(climb_target, wall_for_message)
	if(!adjacent_wall_list_final.len) // if there are no /turf/closed WALLS or none of the WALLS have wallclimb set to TRUE, then the list will be empty so we can't climb there
		to_chat(climber, span_warningbig("I can't climb there!"))
	else
		climber.visible_message(span_info("[climber] climbs along [wall_for_message]..."))
		climber.movement_type = FLYING // the way this works is that we only really ever fall if we enter the open space turf with GROUND move type, otherwise we can just hover over indefinetely
		climber.stamina_add(10) // eat some of climber's stamina when we move onto the next wall
		climber.apply_status_effect(/datum/status_effect/debuff/climbing_lfwb) // continious drain of STAMINA and checks to remove the status effect if we are on solid stuff
		climber.forceMove(climb_target) // while our MOVEMENT TYPE is FLYING, we move onto next tile and can't fall cos of the flying
		climber.movement_type = GROUND // if we move and it's an empty space tile, we fall. otherwise we either just walk into a wall along which we climb and don't fall, or walk onto a solid turf, like... floor or water
//		climber.update_wallpress_slowdown()
		climber.wallpressed = wall2wall_dir // we set our wallpressed flag to TRUE and regain blue bar somewhat, might wanna remove dat idk
		switch(wall2wall_dir)// we are pressed against the wall after all that shit and are facing it, also hugging it too bcoz sou
			if(NORTH)
				climber.setDir(NORTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
				climber.visible_message(span_info("NORTH"))
			if(SOUTH)
				climber.setDir(SOUTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
				climber.visible_message(span_info("SOUTH"))
			if(EAST)
				climber.setDir(EAST)
				climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
				climber.visible_message(span_info("EAST"))
			if(WEST)
				climber.setDir(WEST)
				climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
				climber.visible_message(span_info("WEST"))
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // cardinals working wrong chat
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user
	var/dir2wall
	var/turf/swag
	for(var/turf/closed/adjacent_wall in range(1, climb_target))
		dir2wall = get_dir(climb_target, adjacent_wall)
		if(!((adjacent_wall.wallclimb) && (dir2wall in GLOB.cardinals)))
			to_chat(climber, span_warningbig("I can't climb there!"))
		else
			swag = pick(valid_climb_target)
			adjacent_wall = adjacent_wall.wallclimb
			dir2wall = get_dir(climb_target, adjacent_wall)
			climber.visible_message(span_info("[climber] climbs along [adjacent_wall]..."))
			climber.movement_type = FLYING
			climber.forceMove(climb_target)
			climber.movement_type = GROUND
			climber.update_wallpress_slowdown()
			climber.wallpressed = dir2wall
			switch(dir2wall)
				if(NORTH)
					climber.setDir(NORTH)
					climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
					climber.visible_message(span_info("NORTH"))
				if(SOUTH)
					climber.setDir(SOUTH)
					climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
					climber.visible_message(span_info("SOUTH"))
				if(EAST)
					climber.setDir(EAST)
					climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
					climber.visible_message(span_info("EAST"))
				if(WEST)
					climber.setDir(WEST)
					climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
					climber.visible_message(span_info("WEST"))
*/
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // CARDINAL
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user
	var/turf/closed/adjacent_wall
	var/dir2wall
	var/list/adjacent_wall_list = list()
	var/turf/message_shit
	for(adjacent_wall in range(1, climb_target))
		dir2wall = get_dir(climb_target, adjacent_wall)
		if((adjacent_wall.wallclimb) && (dir2wall in GLOB.cardinals))
			dir2wall = get_dir(climb_target, adjacent_wall)
			adjacent_wall_list += adjacent_wall.wallclimb
			message_shit = pick(adjacent_wall_list)
	if(!adjacent_wall_list.len)
		to_chat(climber, span_warningbig("I can't climb there!"))
	else
		climber.visible_message(span_info("[climber] climbs along [message_shit]..."))
		climber.movement_type = FLYING
		climber.forceMove(climb_target)
		climber.movement_type = GROUND
		climber.update_wallpress_slowdown()
		climber.wallpressed = dir2wall
		switch(dir2wall)
			if(NORTH)
				climber.setDir(NORTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
				climber.visible_message(span_info("NORTH"))
			if(SOUTH)
				climber.setDir(SOUTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
				climber.visible_message(span_info("SOUTH"))
			if(EAST)
				climber.setDir(EAST)
				climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
				climber.visible_message(span_info("EAST"))
			if(WEST)
				climber.setDir(WEST)
				climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
				climber.visible_message(span_info("WEST"))
*/
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // current
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user
	var/turf/closed/adjacent_wall
	var/dir2wall
	var/list/adjacent_wall_list = list()
	for(adjacent_wall in range(1, climb_target))
		if(adjacent_wall.wallclimb)
			adjacent_wall_list += adjacent_wall
	if(!adjacent_wall_list.len)
		to_chat(climber, span_warningbig("I can't climb there!"))
	else
		var/turf/message_shit = pick(adjacent_wall_list)
		climber.visible_message(span_info("[climber] climbs along [message_shit]..."))
		climber.movement_type = FLYING
		climber.forceMove(climb_target)
		climber.movement_type = GROUND
		dir2wall = get_dir(climber, adjacent_wall)
		climber.wallpressed = dir2wall
		switch(dir2wall)
			if(NORTH)
				climber.setDir(NORTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
				climber.visible_message(span_info("NORTH"))
			if(SOUTH)
				climber.setDir(SOUTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
				climber.visible_message(span_info("SOUTH"))
			if(EAST)
				climber.setDir(EAST)
				climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
				climber.visible_message(span_info("EAST"))
			if(WEST)
				climber.setDir(WEST)
				climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
				climber.visible_message(span_info("WEST"))
*/
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // shift user on climb
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user
	var/turf/valid_climbs
	var/turf/closed/adjacent_wall
	var/dir2wall
	for(adjacent_wall in range(1, climb_target))
		dir2wall = get_dir(climb_target, adjacent_wall)
		if(adjacent_wall.wallclimb)
			valid_climbs = adjacent_wall
			if((adjacent_wall.wallclimb) && (dir2wall in GLOB.cardinals))
				dir2wall = get_dir(climb_target, adjacent_wall)
	if(!valid_climbs)
		to_chat(climber, span_warningbig("I can't climb there!"))
	else
		climber.visible_message(span_info("[climber] climbs along [valid_climbs]..."))
		climber.movement_type = FLYING
		climber.forceMove(climb_target)
		climber.movement_type = GROUND
		climber.update_wallpress_slowdown()
		climber.wallpressed = dir2wall
		switch(dir2wall)
			if(NORTH)
				climber.setDir(NORTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
				climber.visible_message(span_info("NORTH"))
			if(SOUTH)
				climber.setDir(SOUTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
				climber.visible_message(span_info("SOUTH"))
			if(EAST)
				climber.setDir(EAST)
				climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
				climber.visible_message(span_info("EAST"))
			if(WEST)
				climber.setDir(WEST)
				climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
				climber.visible_message(span_info("WEST"))
*/
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // cardinals workingwrong chat
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user
	var/list/valid_climbs = list()
	var/turf/closed/message_shit
	var/dir2wall
	var/turf/swag
	for(var/turf/closed/valid_climb_target in range(1, climb_target))
		dir2wall = get_dir(climb_target, valid_climb_target)
		if((valid_climb_target.wallclimb) && (dir2wall in GLOB.cardinals))
			swag = pick(valid_climb_target)
		if(swag)
			dir2wall = get_dir(climb_target, valid_climb_target)
			climber.visible_message(span_info("[climber] climbs along [swag]..."))
			climber.movement_type = FLYING
			climber.forceMove(climb_target)
			climber.movement_type = GROUND
			climber.update_wallpress_slowdown()
			climber.wallpressed = dir2wall
			switch(dir2wall)
				if(NORTH)
					climber.setDir(NORTH)
					climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
				if(SOUTH)
					climber.setDir(SOUTH)
					climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
				if(EAST)
					climber.setDir(EAST)
					climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
				if(WEST)
					climber.setDir(WEST)
					climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
			climber.visible_message(span_info("[dir2wall]..."))
		else
			to_chat(climber, span_warningbig("I can't climb there!"))
*/
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // shift user on climb
	var/turf/climb_target = src
	var/mob/living/carbon/human/climber = user
	var/turf/valid_climbs
	var/turf/closed/adjacent_wall
	var/dir2wall
	for(adjacent_wall in range(1, climb_target))
		dir2wall = get_dir(climb_target, adjacent_wall)
		if(adjacent_wall.wallclimb)
			valid_climbs = adjacent_wall
			dir2wall = get_dir(climb_target, adjacent_wall)
	if(!valid_climbs)
		to_chat(climber, span_warningbig("I can't climb there!"))
	else
		climber.visible_message(span_info("[climber] climbs along [valid_climbs]..."))
		climber.movement_type = FLYING
		climber.forceMove(climb_target)
		climber.movement_type = GROUND
		climber.update_wallpress_slowdown()
		climber.wallpressed = dir2wall
		switch(dir2wall)
			if(NORTH || NORTHWEST || NORTHEAST)
				climber.setDir(NORTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
			if(SOUTH || SOUTHEAST || SOUTHWEST)
				climber.setDir(SOUTH)
				climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
			if(EAST)
				climber.setDir(EAST)
				climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
			if(WEST)
				climber.setDir(WEST)
				climber.set_mob_offsets("wall_press", _x = -12, _y = 0)
		climber.visible_message(span_info("[dir2wall]..."))
*/
/*
/turf/open/transparent/openspace/proc/wallpress(mob/living/user) // shift user on climb
	var/mob/living/carbon/human/climber = user
	var/turf/climb_target = src
	if(!(climber.mobility_flags & MOBILITY_STAND))
		return
	var/dir2wall = get_dir(climber,src)
	if(!(dir2wall in GLOB.cardinals))
		return
	climber.wallpressed = dir2wall
	climber.update_wallpress_slowdown()
	climber.visible_message(span_info("[climber] climbs along [climb_target]..."))

	switch(dir2wall)
		if(NORTH)
			climber.setDir(NORTH)
			climber.set_mob_offsets("wall_press", _x = 0, _y = 20)
		if(SOUTH)
			climber.setDir(SOUTH)
			climber.set_mob_offsets("wall_press", _x = 0, _y = -10)
		if(EAST)
			climber.setDir(EAST)
			climber.set_mob_offsets("wall_press", _x = 12, _y = 0)
		if(WEST)
			climber.setDir(WEST)
			climber.set_mob_offsets("wall_press", _x = -12, _y = 0)

	climber.movement_type = FLYING
	climber.forceMove(climb_target)
	climber.movement_type = GROUND
	var/list/valid_climbs = list()
	for(var/turf/closed/valid_climb_target in range(1, climb_target.loc))
		if(valid_climb_target.wallclimb)
			valid_climbs += valid_climb_target
		if(!valid_climbs.len)
			to_chat(climber, span_warningbig("YOU FELL OFF!"))
			zFall(climber)
			climber.apply_damage(5, BURN, BODY_ZONE_CHEST, forced = TRUE)
			to_chat(climber, span_warningbig("The water seeps into my pores. I am crumbling!"))
//	if(!climber.has_status_effect(/datum/status_effect/debuff/active_climbing))
//		climber.apply_status_effect(/datum/status_effect/debuff/active_climbing)
*/
