/*!
	This component essentially encapsulates frying and utilizes the edible component
	This means fried items can work like regular ones, and generally the code is far less messy
*/
/datum/component/fried
	var/fry_power //how powerfully was this item fried
	var/atom/owner //the atom it is owned by
	var/stored_name //name of the owner when the component was first added
	var/frying_examine_text = "the coders messed frying code up, report this!"

/datum/component/fried/Initialize(frying_power)
	if(!isatom(parent))
		return COMPONENT_INCOMPATIBLE

	RegisterSignal(parent, COMSIG_PARENT_EXAMINE, .proc/examine)

	fry_power = frying_power
	owner = parent
	stored_name = owner.name

	setup_fried_item()

//some stuff to do with the contents of fried junk
GLOBAL_VAR_INIT(frying_hardmode, TRUE)
GLOBAL_VAR_INIT(frying_bad_chem_add_volume, TRUE)
GLOBAL_LIST_INIT(frying_bad_chems, list(
/datum/reagent/toxin/bad_food = 1,
/datum/reagent/toxin = 1,
/datum/reagent/lithium = 1,
/datum/reagent/mercury = 1,
))

/datum/component/fried/proc/examine(datum/source, mob/user, list/examine_list)
	examine_list += "The [parent] has been [frying_examine_text]"

/datum/component/fried/proc/setup_fried_item() //sets the name, colour and examine text and edibility up
	switch(fry_power)
		if(0 to 15)
			owner.name = "lightly fried [owner.name]"
			owner.add_atom_colour(rgb(166,103,54), FIXED_COLOUR_PRIORITY)
			frying_examine_text = "lightly fried"
		if(16 to 49)
			owner.name = "fried [owner.name]"
			owner.add_atom_colour(rgb(103,63,24), FIXED_COLOUR_PRIORITY)
			frying_examine_text = "moderately fried"
		if(50 to 59)
			owner.name = "deep fried [owner.name]"
			owner.add_atom_colour(rgb(63,23,4), FIXED_COLOUR_PRIORITY)
			frying_examine_text = "deeply fried"
		else
			owner.name = "the physical manifestation of fried foods"
			owner.add_atom_colour(rgb(33,19,9), FIXED_COLOUR_PRIORITY)
			frying_examine_text = "incomprehensibly fried to a crisp"

	var/list/fried_tastes = list("crispy")
	var/fried_foodtypes = FRIED
	var/fried_junk = FALSE

	if(!isfood(owner) && GLOB.frying_hardmode && GLOB.frying_bad_chems.len && !owner.reagents) //you fried some junk, it's not gonna taste great
		fried_junk = TRUE
		fried_foodtypes |= TOXIC // junk tastes toxic too
	else
		if(isfood(owner))
			var/obj/item/reagent_containers/food/snacks/food_item = owner
			fried_tastes += food_item.tastes
			fried_foodtypes |= food_item.foodtype

	owner.AddComponent(/datum/component/edible, foodtypes = fried_tastes, tastes = fried_tastes)

	//adding the edible component gives it reagents meaning we can now add the bad frying reagents if it's junk
	if(fried_junk && owner.reagents) //check again just incase
		var/R = rand(1, GLOB.frying_bad_chems.len)
		var/bad_chem = GLOB.frying_bad_chems[R]
		var/bad_chem_amount = max(4,GLOB.frying_bad_chems[bad_chem] * (fry_power/12.5)) //4u of bad chem reached when deeply fried
		owner.reagents.add_reagent(bad_chem, bad_chem_amount)

/datum/component/fried/proc/restore_name() //restore somethings name
	//we do string manipulation and not restoring their name to real_name because some things hide your real_name and we want to maintain that
	if(copytext(owner.name,1,14) == "lightly fried ")
		owner.name = copytext(owner.name,15)
	else
		if(copytext(owner.name,1,6) == "fried ")
			owner.name = copytext(owner.name,7)
		else
			if(copytext(owner.name,1,11) == "deep fried ")
				owner.name = copytext(owner.name, 12)
			else
				if(owner.name == "the physical manifestation of fried foods") //if the name is still this, their name hasn't changed, so we can safely restore their stored name
					owner.name = stored_name
