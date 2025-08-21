/datum/sex_action/masturbate_penis_over
	name = "Jerk over them"
	check_same_tile = FALSE

/datum/sex_action/masturbate_penis_over/shows_on_menu(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	return TRUE

/datum/sex_action/masturbate_penis_over/can_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user == target)
		return FALSE
	if(!check_location_accessible(user, user, BODY_ZONE_PRECISE_GROIN, TRUE))
		return FALSE
	if(!user.getorganslot(ORGAN_SLOT_PENIS))
		return FALSE
	if(!user.sexcon.can_use_penis())
		return
	return TRUE

/datum/sex_action/masturbate_penis_over/on_start(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] starts jerking over [target]..."))

/datum/sex_action/masturbate_penis_over/on_perform(mob/living/carbon/human/user, mob/living/carbon/human/target)
	var/chosen_verb = pick(list("jerks [user.p_their()] cock", "strokes [user.p_their()] cock", "masturbates", "jerks off"))
	user.visible_message(user.sexcon.spanify_force("[user] [user.sexcon.get_generic_force_adjective()] [chosen_verb] over [target]"))
	playsound(user, 'sound/misc/mat/fingering.ogg', 30, TRUE, -2, ignore_walls = FALSE)

	user.sexcon.perform_sex_action(user, 2, 4, TRUE)

	if(user.sexcon.check_active_ejaculation())
		user.visible_message(span_love("[user] cums over [target]'s body!"))
		user.sexcon.cum_onto()
		target.apply_status_effect(/datum/status_effect/facial)

/datum/sex_action/masturbate_penis_over/on_finish(mob/living/carbon/human/user, mob/living/carbon/human/target)
	user.visible_message(span_warning("[user] stops jerking off."))

/datum/sex_action/masturbate_penis_over/is_finished(mob/living/carbon/human/user, mob/living/carbon/human/target)
	if(user.sexcon.finished_check())
		return TRUE
	return FALSE

/datum/status_effect/facial
	id = "facial"
	alert_type = null // don't show an alert on screen
	duration = 10 MINUTES // wear off eventually or until character washes themselves

/datum/status_effect/facial/on_apply()
	RegisterSignal(owner, list(COMSIG_COMPONENT_CLEAN_ACT, COMSIG_COMPONENT_CLEAN_FACE_ACT),PROC_REF(clean_up))
	return ..()

/datum/status_effect/facial/on_remove()
	UnregisterSignal(owner, list(COMSIG_COMPONENT_CLEAN_ACT, COMSIG_COMPONENT_CLEAN_FACE_ACT))
	return ..()

///Callback to remove pearl necklace
/datum/status_effect/facial/proc/clean_up(datum/source, strength)
	if(strength >= CLEAN_WEAK)
		to_chat(owner, span_notice("I feel much cleaner now!"))
		owner.remove_status_effect(/datum/status_effect/facial)
