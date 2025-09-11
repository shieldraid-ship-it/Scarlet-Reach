/datum/advclass/wretch/onimusha/bladethief
	name = "Blade Thief"
	tutorial = "Hailing from Lingyue, yours is an unique art: You seek the swords of worthy foes and add them to your collection in worship of Matthios."
	allowed_sexes = list(MALE, FEMALE)
	allowed_races = RACES_ALL_KINDS //TD?
	outfit = /datum/outfit/job/roguetown/wretch/ronin
	category_tags = list(CTAG_WRETCH)
	cmode_music = 'sound/music/combat_vaquero.ogg' //TD

	subclass_languages = list(/datum/language/kazengunese)
	traits_applied = list(TRAIT_DODGEEXPERT)
	//Bad stats for a wretch, instead they get some really good traits and skills.
	subclass_stats = list(
		STATKEY_SPD = 2,
		STATKEY_INT = 2,
		STATKEY_STR = 1
	)

	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_MASTER,
		/datum/skill/misc/athletics = SKILL_LEVEL_EXPERT,
		/datum/skill/combat/knives = SKILL_LEVEL_APPRENTICE,
		/datum/skill/combat/wrestling = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/reading = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/climbing = SKILL_LEVEL_APPRENTICE,	
	)

/datum/outfit/job/roguetown/wretch/onimusha/bladethief/pre_equip(mob/living/carbon/human/H)
	..()
	to_chat(H, span_warning("Hailing from Lingyue, yours is an unique art: You seek the swords of worthy foes and add them to your collection in worship of Matthios."))
	head = /obj/item/clothing/head/roguetown/roguehood/shalal/hijab/kazengunese
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants/eastpants2
	armor = /obj/item/clothing/suit/roguetown/armor/basiceast/crafteast
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/eastshirt1
	backl = /obj/item/storage/backpack/rogue/satchel/short
	belt = /obj/item/storage/belt/rogue/leather/cloth/bandit
	gloves = /obj/item/clothing/gloves/roguetown/eastgloves1
	shoes = /obj/item/clothing/shoes/roguetown/armor/rumaclan
	neck = /obj/item/clothing/head/roguetown/helmet/leather/armorhood/advanced
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather/heavy
	mask = /obj/item/clothing/mask/rogue/facemask/steel/hound
	beltr = /obj/item/rogueweapon/huntingknife/idagger/steel/kazengun
	backpack_contents = list(
		/obj/item/storage/belt/rogue/pouch/coins/poor = 1,
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/rope/chain = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpot = 1,	//Small health vial
		)

	var/weapons = list("Rapier","Dagger", "Whip")
	var/weapon_choice = input("Pick your steel.", "TAKE UP ARMS") as anything in weapons
	H.set_blindness(0)
	switch(weapon_choice)
		if("Rapier")
			beltl = /obj/item/rogueweapon/scabbard/sword
			l_hand = /obj/item/rogueweapon/sword/rapier
		if("Dagger")
			H.adjust_skillrank_up_to(/datum/skill/combat/knives, SKILL_LEVEL_EXPERT, TRUE)
			beltl = /obj/item/rogueweapon/scabbard/sheath
			l_hand = /obj/item/rogueweapon/huntingknife/idagger/steel/special // Why were they spawning with an elven dagger in the first place??? Please LMK.
		if ("Whip")
			H.adjust_skillrank_up_to(/datum/skill/combat/whipsflails, SKILL_LEVEL_EXPERT, TRUE)
			beltl = /obj/item/rogueweapon/whip
	wretch_select_bounty(H)
