/* Two-handed Weapons
 * Contains:
 * 		Twohanded
 *		Fireaxe
 *		Double-Bladed Energy Swords
 */

/*##################################################################
##################### TWO HANDED WEAPONS BE HERE~ -Agouri :3 ########
####################################################################*/

//Rewrote TwoHanded weapons stuff and put it all here. Just copypasta fireaxe to make new ones ~Carn
//This rewrite means we don't have two variables for EVERY item which are used only by a few weapons.
//It also tidies stuff up elsewhere.

/*
 * Twohanded
 */
/obj/item/weapon/material/twohanded
	w_class = 4
	var/wielded = 0
	var/force_wielded = 0
	var/force_unwielded
	var/wieldsound = null
	var/unwieldsound = null
	var/base_icon
	var/base_name
	var/unwielded_force_divisor = 0.25
	action_button_name = "Wield two-handed weapon"

/obj/item/weapon/material/twohanded/proc/unwield()
	wielded = 0
	force = force_unwielded
	name = "[base_name]"
	update_icon()

/obj/item/weapon/material/twohanded/proc/wield()
	wielded = 1
	force = force_wielded
	name = "[base_name] (Wielded)"
	update_icon()

/obj/item/weapon/material/twohanded/update_force()
	base_name = name
	if(sharp || edge)
		force_wielded = material.get_edge_damage()
	else
		force_wielded = material.get_blunt_damage()
	force_wielded = round(force_wielded*force_divisor)
	force_unwielded = round(force_wielded*unwielded_force_divisor)
	force = force_unwielded
	throwforce = round(force*thrown_force_divisor)
	//world << "[src] has unwielded force [force_unwielded], wielded force [force_wielded] and throwforce [throwforce] when made from default material [material.name]"

/obj/item/weapon/material/twohanded/New()
	..()
	update_icon()

/obj/item/weapon/material/twohanded/mob_can_equip(M as mob, slot)
	//Cannot equip wielded items.
	if(wielded)
		M << "<span class='warning'>Unwield the [base_name] first!</span>"
		return 0

	return ..()

/obj/item/weapon/material/twohanded/dropped(mob/user as mob)
	//handles unwielding a twohanded weapon when dropped as well as clearing up the offhand
	if(user)
		var/obj/item/weapon/material/twohanded/O = user.get_inactive_hand()
		if(istype(O))
			O.unwield()
	return	unwield()

//Allow a small chance of parrying melee attacks when wielded - maybe generalize this to other weapons someday
/obj/item/weapon/material/twohanded/handle_shield(mob/user, var/damage, atom/damage_source = null, mob/attacker = null, var/def_zone = null, var/attack_text = "the attack")
	if(wielded && default_parry_check(user, attacker, damage_source) && prob(15))
		user.visible_message("<span class='danger'>\The [user] parries [attack_text] with \the [src]!</span>")
		playsound(user.loc, 'sound/weapons/punchmiss.ogg', 50, 1)
		return 1
	return 0

/obj/item/weapon/material/twohanded/update_icon()
	icon_state = "[base_icon][wielded]"
	item_state = icon_state

/obj/item/weapon/material/twohanded/pickup(mob/user)
	unwield()

/obj/item/weapon/material/twohanded/attack_self(mob/user as mob)

	..()

	if(istype(user, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		if(issmall(H))
			user << "<span class='warning'>It's too heavy for you to wield fully.</span>"
			return
	else
		return

	if(wielded) //Trying to unwield it
		unwield()
		user << "<span class='notice'>You are now carrying the [name] with one hand.</span>"
		if (src.unwieldsound)
			playsound(src.loc, unwieldsound, 50, 1)

		var/obj/item/weapon/material/twohanded/offhand/O = user.get_inactive_hand()
		if(O && istype(O))
			user.u_equip(O)
			O.unwield()

	else //Trying to wield it
		if(user.get_inactive_hand())
			user << "<span class='warning'>You need your other hand to be empty</span>"
			return
		wield()
		user << "<span class='notice'>You grab the [base_name] with both hands.</span>"
		if (src.wieldsound)
			playsound(src.loc, wieldsound, 50, 1)

		var/obj/item/weapon/material/twohanded/offhand/O = new /obj/item/weapon/material/twohanded/offhand(user) ////Let's reserve his other hand~
		O.name = "[base_name] - offhand"
		O.desc = "Your second grip on the [base_name]."
		user.put_in_inactive_hand(O)

	if(istype(user,/mob/living/carbon/human))
		var/mob/living/carbon/human/H = user
		H.update_inv_l_hand()
		H.update_inv_r_hand()

	return

/obj/item/weapon/material/twohanded/ui_action_click()
	if(src in usr)
		attack_self(usr)

/obj/item/weapon/material/twohanded/verb/wield_twohanded()
	set name = "Wield two-handed weapon"
	set category = "Object"
	set src in usr

	attack_self(usr)

///////////OFFHAND///////////////
/obj/item/weapon/material/twohanded/offhand
	w_class = 5
	icon_state = "offhand"
	name = "offhand"
	default_material = "placeholder"

/obj/item/weapon/material/twohanded/offhand/unwield()
	if (ismob(loc))
		var/mob/living/our_mob = loc
		our_mob.remove_from_mob(src)

	qdel(src)

/obj/item/weapon/material/twohanded/offhand/wield()
	if (ismob(loc))
		var/mob/living/our_mob = loc
		our_mob.remove_from_mob(src)

	qdel(src)

/obj/item/weapon/material/twohanded/offhand/update_icon()
	return

/*
 * Fireaxe
 */
/obj/item/weapon/material/twohanded/fireaxe  // DEM AXES MAN, marker -Agouri
	icon_state = "fireaxe0"
	base_icon = "fireaxe"
	name = "fire axe"
	desc = "Truly, the weapon of a madman. Who would think to fight fire with an axe?"
	unwielded_force_divisor = 0.25
	force_divisor = 0.7 // 10/42 with hardness 60 (steel) and 0.25 unwielded divisor
	sharp = 1
	edge = 1
	w_class = 4.0
	slot_flags = SLOT_BACK
	force_wielded = 30
	attack_verb = list("attacked", "chopped", "cleaved", "torn", "cut")
	applies_material_colour = 0

/obj/item/weapon/material/twohanded/fireaxe/afterattack(atom/A as mob|obj|turf|area, mob/user as mob, proximity)
	if(!proximity) return
	..()
	if(A && wielded)
		if(istype(A,/obj/structure/window))
			var/obj/structure/window/W = A
			W.shatter()
		else if(istype(A,/obj/structure/grille))
			qdel(A)
		else if(istype(A,/obj/effect/plant))
			var/obj/effect/plant/P = A
			P.die_off()

/obj/item/weapon/material/twohanded/fireaxe/pre_attack(var/mob/living/target, var/mob/living/user)
	if(istype(target))
		cleave(user, target)
	..()

//spears, bay edition
/obj/item/weapon/material/twohanded/spear
	icon_state = "spearglass0"
	base_icon = "spearglass"
	name = "spear"
	desc = "A haphazardly-constructed yet still deadly weapon of ancient design."
	force = 10
	w_class = 4.0
	slot_flags = SLOT_BACK
	force_wielded = 0.75           // 22 when wielded with hardness 15 (glass)
	unwielded_force_divisor = 0.65 // 14 when unwielded based on above
	thrown_force_divisor = 1.5 // 20 when thrown with weight 15 (glass)
	throw_speed = 3
	edge = 1
	sharp = 0
	hitsound = 'sound/weapons/bladeslice.ogg'
	attack_verb = list("attacked", "poked", "jabbed", "torn", "gored")
	default_material = "glass"

//Putting heads on spears
/*bj/item/organ/external/head/attackby(var/obj/item/weapon/W, var/mob/living/user, params)
	if(istype(W, /obj/item/weapon/material/twohanded/spear))
		user << "<span class='notice'>You stick the head onto the spear and stand it upright on the ground.</span>"
		var/obj/structure/headspear/HS = new /obj/structure/headspear(user.loc)
		var/matrix/M = matrix()
		src.transform = M
		user.drop_item()
		src.loc = HS
		var/image/IM = image(src.icon,src.icon_state)
		IM.overlays = src.overlays.Copy()
		HS.overlays += IM
		qdel(W)
		qdel(src)
		return
	return ..()*/

/obj/item/weapon/material/twohanded/spear/attackby(var/obj/item/I, var/mob/living/user)
	if(istype(I, /obj/item/organ/external/head))
		user << "<span class='notice'>You stick the head onto the spear and stand it upright on the ground.</span>"
		var/obj/structure/headspear/HS = new /obj/structure/headspear(user.loc)
		var/matrix/M = matrix()
		I.transform = M
		usr.drop_item()
		I.forceMove(HS)
		var/mutable_appearance/MA = new(I)
		MA.layer = FLOAT_LAYER
		HS.add_overlay(MA)
		HS.name = "[I.name] on a spear"
		qdel(src)
		return
	return ..()

//predefined materials for spears
/obj/item/weapon/material/twohanded/spear/steel/New(var/newloc)
	..(newloc,"steel")

/obj/item/weapon/material/twohanded/spear/plasteel/New(var/newloc)
	..(newloc,"plasteel")

/obj/item/weapon/material/twohanded/spear/diamond/New(var/newloc)
	..(newloc,"diamond")

/obj/structure/headspear
	name = "head on a spear"
	desc = "How barbaric."
	icon_state = "headspear"
	density = 0
	anchored = 1

/obj/structure/headspear/attack_hand(mob/living/user)
	user.visible_message("<span class='warning'>[user] kicks over \the [src]!</span>", "<span class='danger'>You kick down \the [src]!</span>")
	new /obj/item/weapon/material/twohanded/spear(user.loc)
	for(var/obj/item/organ/external/head/H in src)
		H.loc = user.loc
	qdel(src)
