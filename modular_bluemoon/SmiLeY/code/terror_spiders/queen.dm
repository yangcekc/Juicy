
// --------------------------------------------------------------------------------
// ----------------- TERROR SPIDERS: T4 QUEEN OF TERROR ---------------------------
// --------------------------------------------------------------------------------
// -------------: ROLE: gamma-level threat to the whole station, like a blob
// -------------: AI: builds a nest, lays many eggs, attempts to take over the station
// -------------: SPECIAL: spins webs, breaks lights, breaks cameras, webs objects, lays eggs, commands other spiders...
// -------------: TO FIGHT IT: bring an army, and take no prisoners. Mechs are a very good idea.
// -------------: SPRITES FROM: IK3I

/mob/living/simple_animal/hostile/poison/terror_spider/queen
	name = "Queen of Terror spider"
	desc = "An enormous, terrifying spider. Its egg sac is almost as big as its body, and teeming with spider eggs!"
	ai_target_method = TS_DAMAGE_SIMPLE
	icon_state = "terror_queen"
	icon_living = "terror_queen"
	icon_dead = "terror_queen_dead"
	maxHealth = 340
	health = 340
	damage_coeff = list(BRUTE = 0.7, BURN = 1.1, TOX = 1, CLONE = 0, STAMINA = 0, OXY = 0.2)
	regeneration = 3
	deathmessage = "Emits a  piercing screech that echoes through the hallways, chilling the hearts of those around, as the spider lifelessly falls to the ground."
	death_sound = 'sound/creatures/terrorspiders/queen_death.ogg'
	melee_damage_lower = 25
	melee_damage_upper = 30
	armour_penetration = 20
	obj_damage = 100
	environment_smash = ENVIRONMENT_SMASH_WALLS
	ventcrawler = 1
	ai_break_lights = FALSE
	ai_spins_webs = FALSE
	ai_ventcrawls = FALSE
	idle_ventcrawl_chance = 0
	move_resist = MOVE_FORCE_STRONG // no more pushing a several hundred if not thousand pound spider
	force_threshold = 18 // outright immune to anything of force under 18, this means welders can't hurt it, only guns can
	ranged = 1
	retreat_distance = 5
	minimum_distance = 5
	projectilesound = 'sound/creatures/terrorspiders/spit2.ogg'
	projectiletype = /obj/item/projectile/terrorspider/queen
	ranged_cooldown_time = 20
	spider_tier = TS_TIER_4
	spider_opens_doors = 2
	web_type = /obj/structure/spider/terrorweb/queen
	delay_web = 15
	special_abillity = list(/obj/effect/proc_holder/spell/aoe_turf/terror_shriek_queen)
	can_wrap = FALSE
	spider_intro_text = "Будучи Королевой Ужаса, ваша цель - управление выводком и откладывание яиц. Вы крайне сильны, и со временем будете откладывать всё больше яиц, однако, ваша смерть будет означать поражение, ведь все пауки погибнут."
	var/spider_spawnfrequency = 1600 // 160 seconds. Default for player queens and NPC queens on station. Awaymission queens have this changed in New()
	var/spider_spawnfrequency_stable = 3600 // 360 seconds. Spawnfrequency is set to this on awaymission spiders once nest setup is complete.
	var/spider_lastspawn = 0
	var/nestfrequency = 300 // 30 seconds
	var/lastnestsetup = 0
	var/neststep = 0
	var/hasnested = FALSE
	var/spider_max_per_nest = 35 // above this, AI queens become stable
	var/canlay = 5 // main counter for egg-laying ability! # = num uses, incremented at intervals
	var/eggslaid = 0
	var/list/spider_types_standard = list(/mob/living/simple_animal/hostile/poison/terror_spider/knight, /mob/living/simple_animal/hostile/poison/terror_spider/lurker, /mob/living/simple_animal/hostile/poison/terror_spider/healer, /mob/living/simple_animal/hostile/poison/terror_spider/widow)
	var/datum/action/innate/terrorspider/queen/queennest/queennest_action
	var/datum/action/innate/terrorspider/queen/queensense/queensense_action
	var/datum/action/innate/terrorspider/queen/queeneggs/queeneggs_action
	var/datum/action/innate/terrorspider/ventsmash/ventsmash_action
	var/datum/action/innate/terrorspider/remoteview/remoteview_action

/mob/living/simple_animal/hostile/poison/terror_spider/queen/New()
	..()
	ventsmash_action = new()
	ventsmash_action.Grant(src)
	remoteview_action = new()
	remoteview_action.Grant(src)
	grant_queen_subtype_abilities()
	spider_myqueen = src
	if(spider_awaymission)
		spider_growinstantly = TRUE
		spider_spawnfrequency = 150


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/grant_queen_subtype_abilities()
	queennest_action = new()
	queennest_action.Grant(src)

/mob/living/simple_animal/hostile/poison/terror_spider/queen/Life(seconds, times_fired)
	. = ..()
	if(stat != DEAD) // Can't use if(.) for this due to the fact it can sometimes return FALSE even when mob is alive.
		if(ckey && hasnested)
			if(world.time > (spider_lastspawn + spider_spawnfrequency))
				grant_eggs()


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/grant_eggs()
	spider_lastspawn = world.time
	canlay += getSpiderLevel()
	if(canlay == 1)
		to_chat(src, "<span class='notice'>You have an egg available to lay.</span>")
		SEND_SOUND(src, sound('sound/effects/ping.ogg'))
	else if(canlay > 1)
		to_chat(src, "<span class='notice'>You have [canlay] eggs available to lay.</span>")
		SEND_SOUND(src, sound('sound/effects/ping.ogg'))

/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/getSpiderLevel()
	return 1 + round(MinutesAlive() / 10)


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/MinutesAlive()
	return round((world.time - spider_creation_time) / 600)


/mob/living/simple_animal/hostile/poison/terror_spider/queen/death(gibbed)
	if(can_die() && !hasdied)
		if(spider_uo71)
			UnlockBlastDoors("UO71_Caves")
		// When a queen (or subtype!) dies, so do all of her spiderlings, and half of all her fully grown offspring
		// This feature is intended to provide a way for crew to still win even if the queen has overwhelming numbers - by sniping the queen.
		for(var/thing in GLOB.ts_spiderlist)
			var/mob/living/simple_animal/hostile/poison/terror_spider/T = thing
			if(!T.spider_myqueen)
				continue
			if(T == src)
				continue
			if(T.spider_myqueen != src)
				continue
			if(T.spider_tier < spider_tier)
				T.visible_message("<span class='danger'>[T] writhes in pain!</span>")
				to_chat(T, "<span class='userdanger'>\The psychic backlash from the death of [src] overwhelms you! You feel the life start to drain out of you...</span>")
				T.degenerate = TRUE
		for(var/thing in GLOB.ts_spiderling_list)
			var/obj/structure/spider/spiderling/terror_spiderling/T = thing
			if(T.spider_myqueen && T.spider_myqueen == src)
				qdel(T)
	return ..()


/mob/living/simple_animal/hostile/poison/terror_spider/queen/Retaliate()
	..()
	for(var/thing in GLOB.ts_spiderlist)
		var/mob/living/simple_animal/hostile/poison/terror_spider/T = thing
		T.enemies |= enemies


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/ai_nest_is_full()
	var/numspiders = CountSpiders()
	if(numspiders >= spider_max_per_nest)
		return TRUE
	return FALSE


/mob/living/simple_animal/hostile/poison/terror_spider/queen/spider_special_action()
	if(!stat && !ckey)
		switch(neststep)
			if(0)
				// No nest. If current location is eligible for nesting, advance to step 1.
				var/ok_to_nest = TRUE
				var/area/new_area = get_area(loc)
				if(new_area)
					if(findtext(new_area.name, "hall"))
						ok_to_nest = FALSE
						// nesting in a hallway would be very stupid - crew would find and kill you almost instantly
				var/numhostiles = 0
				for(var/mob/living/H in oview(10, src))
					if(!istype(H, /mob/living/simple_animal/hostile/poison/terror_spider))
						if(H.stat != DEAD)
							numhostiles += 1
							// nesting RIGHT NEXT TO SOMEONE is even worse
				if(numhostiles > 0)
					ok_to_nest = FALSE
				var/vdistance = 99
				for(var/obj/machinery/atmospherics/components/unary/vent_pump/v in view(10, src))
					if(!v.welded)
						if(get_dist(src, v) < vdistance)
							entry_vent = v
							vdistance = get_dist(src, v)
				if(!entry_vent)
					ok_to_nest = FALSE
					// don't nest somewhere with no vent - your brood won't be able to get out!
				if(ok_to_nest && entry_vent)
					nest_vent = entry_vent
					neststep = 1
					visible_message("<span class='danger'>\The [src] settles down, starting to build a nest.</span>")
				else if(entry_vent)
					if(!path_to_vent)
						visible_message("<span class='danger'>\The [src] looks around warily - then seeks a better nesting ground.</span>")
						path_to_vent = 1
				else
					neststep = -1
					message_admins("Warning: [ADMIN_LOOKUPFLW(src)] was spawned in an area without a vent! This is likely a mapping/spawn mistake. This mob's AI has been permanently deactivated.")
			if(1)
				// No nest, and we should create one. Start NestMode(), then advance to step 2.
				if(world.time > (lastnestsetup + nestfrequency))
					lastnestsetup = world.time
					neststep = 2
					NestMode()
			if(2)
				// Create initial T2 spiders.
				if(world.time > (lastnestsetup + nestfrequency))
					lastnestsetup = world.time
					spider_lastspawn = world.time
					DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/guardian, 2)
					DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/defiler, 2)
					DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/destroyer, 2)
					neststep = 3
			if(3)
				// Create spiders (random types) until nest is full.
				if(world.time > (spider_lastspawn + spider_spawnfrequency))
					if(prob(20))
						if(ai_nest_is_full())
							if(spider_awaymission)
								spider_spawnfrequency = spider_spawnfrequency_stable
							neststep = 4
						else
							spider_lastspawn = world.time
							var/spiders_left_to_spawn = clamp( (spider_max_per_nest - CountSpiders()), 1, 10)
							DoLayTerrorEggs(pick(spider_types_standard), spiders_left_to_spawn)
			if(4)
				// Nest should be full. Otherwise, start replenishing nest (stage 5).
				if(world.time > (spider_lastspawn + spider_spawnfrequency))
					if(prob(20) && !ai_nest_is_full())
						neststep = 5
			if(5)
				// If already replenished, go idle (stage 4). Otherwise, replenish nest.
				if(world.time > (spider_lastspawn + spider_spawnfrequency))
					if(prob(20))
						if(ai_nest_is_full())
							neststep = 4
						else
							spider_lastspawn = world.time
							var/list/spider_array = CountSpidersDetailed(FALSE)
							if(spider_array[/mob/living/simple_animal/hostile/poison/terror_spider/guardian] < 4)
								DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/guardian, 2)
							else if(spider_array[/mob/living/simple_animal/hostile/poison/terror_spider/defiler] < 2)
								DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/defiler, 2)
							else if(spider_array[/mob/living/simple_animal/hostile/poison/terror_spider/destroyer] < 4)
								DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/destroyer, 4)
							else
								DoLayTerrorEggs(pick(spider_types_standard), 5)


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/NestPrompt()
	var/confirm = alert(src, "Are you sure you want to nest? You will be able to lay eggs, and smash walls, but not ventcrawl.","Nest?","Yes","No")
	if(confirm == "Yes")
		NestMode()


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/NestMode()
	queeneggs_action = new()
	queeneggs_action.Grant(src)
	queensense_action = new()
	queensense_action.Grant(src)
	queennest_action.Remove(src)
	hasnested = TRUE
	ventcrawler = 0
	speed = 0.5
	ai_ventcrawls = FALSE
	environment_smash = ENVIRONMENT_SMASH_RWALLS
	DoQueenScreech(8, 100, 8, 100)
	to_chat(src, "<span class='notice'>You have matured to your egglaying stage. You can now smash through walls, and lay eggs, but can no longer ventcrawl.</span>")


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/LayQueenEggs()
	if(stat == DEAD)
		return
	if(!hasnested)
		to_chat(src, "<span class='danger'>You must nest before doing this.</span>")
		return
	if(canlay < 1)
		show_egg_timer()
		return
	var/list/eggtypes = ListAvailableEggTypes()
	var/list/eggtypes_uncapped = list(TS_DESC_KNIGHT, TS_DESC_LURKER, TS_DESC_HEALER, TS_DESC_REAPER, TS_DESC_BUILDER)

	var/eggtype = input("What kind of eggs?") as null|anything in eggtypes
	if(canlay < 1)
		// this was checked before input() but we have to check again to prevent them spam-clicking the popup.
		to_chat(src, "<span class='danger'>Too soon to lay another egg.</span>")
		return
	if(!(eggtype in eggtypes))
		to_chat(src, "<span class='danger'>Unrecognized egg type.</span>")
		return 0

	// Multiple of eggtypes_uncapped can be laid at once. Other types must be laid one at a time (to prevent exploits)
	var/numlings = 1
	if(eggtype in eggtypes_uncapped)
		if(canlay >= 5)
			numlings = input("How many in the batch?") as null|anything in list(1, 2, 3, 4, 5)
		else if(canlay >= 3)
			numlings = input("How many in the batch?") as null|anything in list(1, 2, 3)
		else if(canlay == 2)
			numlings = input("How many in the batch?") as null|anything in list(1, 2)
	if(eggtype == null || numlings == null)
		to_chat(src, "<span class='danger'>Cancelled.</span>")
		return
	// Actually lay the eggs.
	if(canlay < numlings)
		// We have to check this again after the popups, to account for people spam-clicking the button, then doing all the popups at once.
		to_chat(src, "<span class='warning'>Too soon to do this again!</span>")
		return
	canlay -= numlings
	eggslaid += numlings
	playsound(src.loc, 'sound/creatures/terrorspiders/web.ogg', 50, 1)
	switch(eggtype)
		if(TS_DESC_KNIGHT)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/knight, numlings)
		if(TS_DESC_LURKER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/lurker, numlings)
		if(TS_DESC_HEALER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/healer, numlings)
		if(TS_DESC_REAPER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/reaper, numlings)
		if(TS_DESC_BUILDER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/builder, numlings)
		if(TS_DESC_WIDOW)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/widow, numlings)
		if(TS_DESC_GUARDIAN)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/guardian, numlings)
		if(TS_DESC_DESTROYER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/destroyer, numlings)
		if(TS_DESC_MOTHER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/mother, numlings)
		if(TS_DESC_DEFILER)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/defiler, numlings)
		if(TS_DESC_PRINCESS)
			DoLayTerrorEggs(/mob/living/simple_animal/hostile/poison/terror_spider/queen/princess, numlings)
		else
			to_chat(src, "<span class='danger'>Unrecognized egg type.</span>")

/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/show_egg_timer()
	var/remainingtime = round(((spider_lastspawn + spider_spawnfrequency) - world.time) / 10, 1)
	if(remainingtime > 0)
		to_chat(src, "<span class='danger'>Too soon to attempt that again. Wait another [num2text(remainingtime)] seconds.</span>")
	else
		to_chat(src, "<span class='danger'>Too soon to attempt that again. Wait just a few more seconds...</span>")

/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/ListAvailableEggTypes()
	if(MinutesAlive() >= 25)
		var/list/spider_array = CountSpidersDetailed(TRUE, list(/mob/living/simple_animal/hostile/poison/terror_spider/mother, /mob/living/simple_animal/hostile/poison/terror_spider/defiler, /mob/living/simple_animal/hostile/poison/terror_spider/queen/princess))
		if(spider_array["all"] == 0)
			return list(TS_DESC_DEFILER, TS_DESC_PRINCESS, TS_DESC_MOTHER)

	var/list/valid_types = list(TS_DESC_KNIGHT, TS_DESC_LURKER, TS_DESC_HEALER, TS_DESC_REAPER, TS_DESC_BUILDER)
	var/list/spider_array = CountSpidersDetailed(FALSE, list(/mob/living/simple_animal/hostile/poison/terror_spider/destroyer, /mob/living/simple_animal/hostile/poison/terror_spider/guardian, /mob/living/simple_animal/hostile/poison/terror_spider/widow))
	if(spider_array[/mob/living/simple_animal/hostile/poison/terror_spider/destroyer] < 3)
		valid_types += TS_DESC_DESTROYER
	if(spider_array[/mob/living/simple_animal/hostile/poison/terror_spider/guardian] < 3)
		valid_types += TS_DESC_GUARDIAN
	if(spider_array[/mob/living/simple_animal/hostile/poison/terror_spider/widow] < 4)
		valid_types += TS_DESC_WIDOW
	return valid_types


/mob/living/simple_animal/hostile/poison/terror_spider/queen/proc/DoQueenScreech(light_range, light_chance, camera_range, camera_chance)
	visible_message("<span class='userdanger'>[src] emits a bone-chilling shriek!</span>")
	playsound(src.loc, 'sound/creatures/terrorspiders/queen_shriek.ogg', 100, 1)
	for(var/obj/machinery/light/L in orange(light_range, src))
		if(L.on && prob(light_chance))
			L.break_light_tube()
	for(var/obj/machinery/camera/C in orange(camera_range, src))
		if(C.status && prob(camera_chance))
			C.toggle_cam(src, 0)


/mob/living/simple_animal/hostile/poison/terror_spider/queen/examine(mob/user)
	. = ..()
	if(!key || stat == DEAD)
		return
	if(!isobserver(user) && !isterrorspider(user))
		return
	. += "<span class='notice'>[p_they(TRUE)] has laid [eggslaid] egg[eggslaid != 1 ? "s" : ""].</span>"
	. += "<span class='notice'>[p_they(TRUE)] has lived for [MinutesAlive()] minutes.</span>"


/obj/item/projectile/terrorspider/queen
	name = "queen venom"
	icon_state = "toxin3"
	damage = 40
	stamina = 40
	damage_type = BURN

/obj/structure/spider/terrorweb/queen
	name = "airtight web"
	desc = "This multi-layered web seems to be able to resist air pressure."
	max_integrity = 30


/obj/structure/spider/terrorweb/queen/Initialize(mapload)
	. = ..()
	air_update_turf(TRUE)

/obj/structure/spider/terrorweb/queen/CanAtmosPass(turf/T)
	return FALSE

/obj/structure/spider/terrorweb/queen/Destroy()
	var/turf/T = get_turf(src)
	. = ..()
	T.air_update_turf(TRUE)
