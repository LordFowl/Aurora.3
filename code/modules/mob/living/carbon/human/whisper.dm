//Lallander was here
/mob/living/carbon/human/whisper(message as text)
	var/alt_name = ""

	if(say_disabled)	//This is here to try to identify lag problems
		to_chat(usr, "<span class='warning'>Speech is currently admin-disabled.</span>")
		return

	message = sanitize(message)

	if (client && client.handle_spam_prevention(message,MUTE_IC))
		return

	if (src.stat == 2)
		return src.say_dead(message)

	if (src.stat)
		return

	if(name != GetVoice())
		alt_name = "(as [get_id_name("Unknown")])"

	//parse the language code and consume it
	var/datum/language/speaking = parse_language(message)
	if (speaking)
		message = copytext(message,2+length(speaking.key))

	whisper_say(message, speaking, alt_name)


//This is used by both the whisper verb and human/say() to handle whispering
/mob/living/carbon/human/proc/whisper_say(var/message, var/datum/language/speaking = null, var/alt_name="", var/verb="whispers")

	if (istype(src.wear_mask, /obj/item/clothing/mask/muzzle))
		to_chat(src, "<span class='danger'>You're muzzled and cannot speak!</span>")
		return

	var/message_range = 1
	var/eavesdropping_range = 2
	var/watching_range = 5
	var/italics = 1

	var/not_heard //the message displayed to people who could not hear the whispering
	if (speaking)
		if (speaking.whisper_verb)
			verb = speaking.whisper_verb
			not_heard = "[verb] something"
		else
			var/adverb = pick("quietly", "softly")
			verb = "[speaking.speech_verb] [adverb]"
			not_heard = "[speaking.speech_verb] something [adverb]"
	else
		not_heard = "[verb] something" //TODO get rid of the null language and just prevent speech if language is null

	message = capitalize(trim(message))

	if(speech_problem_flag)
		var/list/handle_r = handle_speech_problems(message)
		message = handle_r[1]
		verb = handle_r[2]
		if(verb == "yells loudly")
			verb = "slurs emphatically"
		else
			var/adverb = pick("quietly", "softly")
			verb = "[verb] [adverb]"

		speech_problem_flag = handle_r[3]

	if(!message || message=="")
		return

	log_whisper("[key_name(src)] : ([get_lang_name(speaking)]) [message]",ckey=key_name(src))

	//looks like this only appears in whisper. Should it be elsewhere as well? Maybe handle_speech_problems?
	var/voice_sub
	if(istype(back,/obj/item/weapon/rig))
		var/obj/item/weapon/rig/rig = back
		// todo: fix this shit
		if(rig.speech && rig.speech.voice_holder && rig.speech.voice_holder.active && rig.speech.voice_holder.voice)
			voice_sub = rig.speech.voice_holder.voice
	else
		for(var/obj/item/gear in list(wear_mask,wear_suit,head))
			if(!gear)
				continue
			var/obj/item/voice_changer/changer = locate() in gear
			if(changer && changer.active && changer.voice)
				voice_sub = changer.voice

	if(voice_sub == "Unknown")
		if(copytext(message, 1, 2) != "*")
			var/list/temp_message = text2list(message, " ")
			var/list/pick_list = list()
			for(var/i = 1, i <= temp_message.len, i++)
				pick_list += i
			for(var/i=1, i <= abs(temp_message.len/3), i++)
				var/H = pick(pick_list)
				if(findtext(temp_message[H], "*") || findtext(temp_message[H], ";") || findtext(temp_message[H], ":")) continue
				temp_message[H] = ninjaspeak(temp_message[H])
				pick_list -= H
			message = jointext(temp_message, " ")
			message = replacetext(message, "o", "¤")
			message = replacetext(message, "p", "ž")
			message = replacetext(message, "l", "£")
			message = replacetext(message, "s", "§")
			message = replacetext(message, "u", "µ")
			message = replacetext(message, "b", "ß")

	var/list/listening = hearers(message_range, src)
	listening |= src

	//ghosts
	for (var/mob/M in dead_mob_list)	//does this include players who joined as observers as well?
		if (!(M.client))
			continue
		if(M.stat == DEAD && M.client && (M.client.prefs.toggles & CHAT_GHOSTEARS))
			listening |= M

	//Pass whispers on to anything inside the immediate listeners.
	for(var/mob/L in listening)
		for(var/mob/C in L.contents)
			if(istype(C,/mob/living))
				listening += C

	//pass on the message to objects that can hear us.
	for (var/obj/O in view(message_range, src))
		spawn (0)
			if (O)
				O.hear_talk(src, message, verb, speaking)

	var/list/eavesdropping = hearers(eavesdropping_range, src)
	eavesdropping -= src
	eavesdropping -= listening

	var/list/watching  = hearers(watching_range, src)
	watching  -= src
	watching  -= listening
	watching  -= eavesdropping

	//now mobs

	var/list/listening_clients = list()	// The clients we're going to show the speech bubble to.

	for(var/mob/M in listening)
		M.hear_say(message, verb, speaking, alt_name, italics, src)
		if (M.client)
			listening_clients += M.client

	if (eavesdropping.len)
		var/new_message = stars(message)	//hopefully passing the message twice through stars() won't hurt... I guess if you already don't understand the language, when they speak it too quietly to hear normally you would be able to catch even less.
		for(var/mob/M in eavesdropping)
			M.hear_say(new_message, verb, speaking, alt_name, italics, src)
			if (M.client)
				listening_clients += M.client

	var/speech_bubble_test = say_test(message)
	var/image/speech_bubble = image('icons/mob/talk.dmi',src,"h[speech_bubble_test]")
	INVOKE_ASYNC(GLOBAL_PROC, /proc/flick_overlay, speech_bubble, listening_clients, 30)

	if (watching.len)
		var/rendered = "<span class='game say'><span class='name'>[src.name]</span> [not_heard].</span>"
		for (var/mob/M in watching)
			M.show_message(rendered, 2)
