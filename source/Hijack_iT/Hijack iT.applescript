-- Hijack iT!.applescript
-- Hijack iT!
-- Version 2.7

--  Created by Sean P. Kane on Wed April 28 2004.
--  Copyright (c) 2004-2006 Sean Kane.

-- This script and all related files have been re-released with the following license effective: October 12, 2011
Hijack iT by Sean P. Kane is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
Based on a work at https://github.com/spkane/Hijack-iT

(*
Hijack iT!  Version 20060312

Thanks to these existing scripts for inspiration and help:
Pick a Playlist - by Wooden Brain Concepts - 12/29/01
"Just Play This One" v1.0 by Doug Adams
Julian C. Westerhout's Click Scripts for Audio Hijack Pro
Ted Stevko's Applescripting the Unscriptable
Brad Brighton for helping me across the finish line.
Oringal License Key Code written by Thomas Kuehner, Koeln, Germany, 05-25-2003 - <macgix@macgix-services.com> - <http://macgix-services.com>
MacScripter.net
apple's Applescript-users and applescript-studio mailing lists
Michal Aase: For his testing which helped make this application much more robust and stable.
and finally to all my registered users who's patronage and support made this all possible.

TODO:
FIX AHP Double Quit error
itunes zoom issues
internationalization
radio streams
save prefered playlist

Done:
adding support for tagging
Fixed error that caused the year tag not to be recorded
*)

property pMusicFolder : "/"
property pThePlaylist : "Hijack iT!"
property pTheSession : "Hijack iT! Preset"
property pTheTotal : 0
property pCanceled : 0
property pMDR : "1"
property pESM : "1"
property pDB : -30.0
property pSeconds : 2.0
property pQuitApps : "1"
property pNewLog : 1
property pDebug : 0

-- Definition of the translation table definition. Please change bList to your own! 
property aList : {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}

-- DO NOT CHANGE THE LINE BELOW!!!!!!
property bList : {"4", "2", "6", "9", "J", "a", "n", "X", "Q", "z", "8", "3", "L", "o", "V", "e"}

-- The shift used by subroutines
-- DO NOT CHANGE THE LINE BELOW!!!!!!
property tSh : 7 -- Shift should not lead to ascii numbers smaller than 1 and higher than 255 ! - Respect it!

-- ------------------------------------------------------------------------------
-- ENCODER

-- Main routine
on convNameToSerial(tName, tShift)
	
	set temp to {}
	set tempList to {}
	set tList to {}
	
	-- Convert string to ASCII number list
	repeat with t from 1 to length of tName
		set tempChar to character t of tName as string
		set tList to tList & ((ASCII number of tempChar) + tShift)
	end repeat
	
	-- Convert ASCII number list to Hexadezimal with shifting
	set tempList to {}
	repeat with t from 1 to count of items of tList
		set tempChar to (item t of tList) as integer
		set tempList to tempList & makeIntToHex(tempChar)
	end repeat
	
	-- Convert hexadezimal string into another format using the the table definition
	set temp to {}
	repeat with t from 1 to count of tempList
		set tempItem to (item t of tempList) as string
		set temp to temp & EncodeHex(tempItem)
	end repeat
	
	-- Build four digit string parts and create the resulting string
	set tempList to {}
	repeat with n from 1 to count of items of temp by 2
		try
			set tempList to tempList & ((item n of temp & item (n + 1) of temp & "-") as string)
		on error errnum
			--	do nothing, the list count was simply odd
		end try
	end repeat
	
	-- Check if list count was even or odd and respect this in the resulting string
	if (count of items of temp) mod 2 = 1 then
		-- The list was odd and the last item has to be added
		set tempList to tempList & (last item of temp)
	else
		-- The list was even but the string may end with a slash instead of a value
		set tempList to (characters 1 thru -2 of (tempList as string)) as string
	end if
	return tempList as string
	
end convNameToSerial

-- Creates a hexadezimal format using the hexIt(m) soubroutine
on makeIntToHex(n)
	set aN to n div 16
	set bN to n mod 16
	set aN to hexIt(aN)
	set bN to hexIt(bN)
	return (aN & bN) as string
end makeIntToHex

-- Subroutine of makeIntoHex(n) changing numbers greater 10 to the corresponding hex chars
on hexIt(m)
	if m > 9 then
		if m = 10 then
			return "A"
		else if m = 11 then
			return "B"
		else if m = 12 then
			return "C"
		else if m = 13 then
			return "D"
		else if m = 14 then
			return "E"
		else if m = 15 then
			return "F"
		end if
	else
		return m
	end if
end hexIt

-- Translate result of MakeIntoHex using the table definition
on EncodeHex(k)
	
	set k to k as string
	
	set aItem to character 1 of k
	set bItem to character 2 of k
	
	set a2Item to my changeVal(aItem)
	set b2Item to my changeVal(bItem)
	
	return (a2Item & b2Item) as string
	
end EncodeHex

-- Subrouting of EncodeHex(k) - Changes value based on the table definition
on changeVal(p)
	set p to p as string
	repeat with l from 1 to count of items of aList
		if p = ((item l of aList) as string) then
			set p to ((item l of bList) as string)
			exit repeat
		end if
	end repeat
	return p
end changeVal

-- ------------------------------------------------------------------------------
-- DECODER

on convSerialToName(tNum, tShift)
	
	-- Remove slashes from number string
	set temp to {}
	repeat with t from 1 to length of tNum
		set tempChar to character t of tNum
		if tempChar ­ "-" then set temp to temp & tempChar
	end repeat
	set tNum to temp as string
	set temp to {} -- free memory ;-)
	
	-- Retranslate the elements using the table definition the other way round
	set temp to {}
	repeat with t from 1 to length of tNum
		set temp to temp & rechangeValue(character t of tNum)
	end repeat
	set tNum to temp as string
	
	-- Break the string in a two digit formatted list
	set tNum to breakString(tNum)
	
	-- Recalculate the elements into dezimal format 
	set temp to {}
	repeat with t from 1 to count of tNum
		try
			set temp to temp & (makeHexToDec(item t of tNum))
		on error
			exit repeat
		end try
	end repeat
	set tNum to temp
	
	-- Build ASCII characters from the ASCII number list and downshift
	set temp to {}
	repeat with t from 1 to count of tNum
		set temp to temp & makeASCIIfromNUM(item t of tNum)
	end repeat
	set tNum to temp as string
	
	return tNum
	
end convSerialToName

-- Make list of two digit elements
on breakString(aString)
	
	set tempList to {}
	set aString to characters of aString
	repeat with n from 1 to count of items of aString by 2
		try
			set tempList to tempList & ((item n of aString & item (n + 1) of aString) as string)
		on error errnum
			--	do nothing, the list count was simply odd
		end try
	end repeat
	
	return tempList
	
end breakString

-- Retranslate the elements using the table definition the other way round
on rechangeValue(p)
	set p to p as string
	repeat with l from 1 to count of items of bList
		if p = ((item l of bList) as string) then
			set p to ((item l of aList) as string)
			exit repeat
		end if
	end repeat
	return p
end rechangeValue

-- Creates a dezimal format using the decIt(m) soubroutine
on makeHexToDec(n)
	
	set n to n as string
	
	set aN to character 1 of n
	set bN to character 2 of n
	
	set aN to decIt(aN)
	set bN to decIt(bN)
	
	return (aN * 16 + bN) as integer
	
end makeHexToDec

-- Subroutine of makeIntoHex(n) changing numbers greater 10 to the corresponding hex chars
on decIt(m)
	
	if m = "A" then
		return 10
	else if m = "B" then
		return 11
	else if m = "C" then
		return 12
	else if m = "D" then
		return 13
	else if m = "E" then
		return 14
	else if m = "F" then
		return 15
	else
		return m
	end if
end decIt

-- Build ASCII characters from the ASCII number list by downshifting
on makeASCIIfromNUM(tNum)
	return ASCII character (tNum - tSh)
end makeASCIIfromNUM

on DisplayDebug(vDebugHeader, vDebugMessage)
	set vLogFile to (((path to home folder) as text) & "Library:Logs:Hijack iT!.log")
	tell window "debug_window"
		try
			set vLogContent to (get content of text view "debug_console" of scroll view "debug_scroll")
			set vLogTime to (current date)
			set vLogEntry to (vLogTime & ": " & vDebugHeader & ": " & vDebugMessage) as string
			if pNewLog = 1 then
				tell me
					write_to_file(vLogEntry, vLogFile, false)
				end tell
			else
				tell me
					write_to_file(vLogEntry, vLogFile, true)
				end tell
			end if
			set content of text view "debug_console" of scroll view "debug_scroll" to vLogContent & "
" & vLogEntry
		on error
			error "Unable to send Debug output to log window." number 999
		end try
	end tell
end DisplayDebug

on write_to_file(this_data, target_file, append_data)
	try
		set the target_file to the target_file as text
		set the open_target_file to open for access file target_file with write permission
		if append_data is false then set eof of the open_target_file to 0
		write this_data & "
" to the open_target_file starting at eof
		close access the open_target_file
		return true
	on error
		try
			close access file target_file
		end try
		return false
	end try
end write_to_file

on ReadPrefs()
	try
		set vPrefsPath to (path to preferences as string) & "com.actionable_intelligence.Hijack_iT.plist"
		set vPosixPrefsPath to POSIX path of file vPrefsPath
		set vDefaultPrefs to (path to me as string) & "Contents:Resources:com.actionable_intelligence.Hijack_iT.plist"
		set vPosixDefaultPrefs to POSIX path of file vDefaultPrefs
		if pDebug = 1 then
			tell me
				DisplayDebug("Copy Prefs", quoted form of vPosixDefaultPrefs & " " & quoted form of vPosixPrefsPath)
			end tell
		end if
		do shell script "if [ ! -f " & quoted form of vPosixPrefsPath & " ]; then cp " & quoted form of vPosixDefaultPrefs & " " & quoted form of vPosixPrefsPath & " ; fi"
		set vPrefsPlist to read property list file (vPrefsPath)
		set vRegisteredName to |name| of vPrefsPlist
		set vLicenseKey to |LicenseKey| of vPrefsPlist
		if pDebug = 1 then
			tell me
				DisplayDebug("Registration Window Values", vRegisteredName & " " & vLicenseKey)
			end tell
		end if
		tell window "Registration"
			set contents of text field "reg_name" to vRegisteredName
			set contents of text field "lic_key" to vLicenseKey
		end tell
	on error
		error "Unable to read preferences file" number 999
	end try
end ReadPrefs

on WritePrefs()
	try
		set vPrefsPath to (path to preferences as string) & "com.actionable_intelligence.Hijack_iT.plist"
		set vPosixPrefsPath to POSIX path of file vPrefsPath
		set vDefaultPrefs to (path to me as string) & "Contents:Resources:com.actionable_intelligence.Hijack_iT.plist"
		set vPosixDefaultPrefs to POSIX path of file vDefaultPrefs
		if pDebug = 1 then
			tell me
				DisplayDebug("Write Prefs Paths", quoted form of vPosixDefaultPrefs & " " & quoted form of vPosixPrefsPath)
			end tell
		end if
		do shell script "if [ ! -f " & quoted form of vPosixPrefsPath & " ]; then cp " & quoted form of vPosixDefaultPrefs & " " & quoted form of vPosixPrefsPath & " ; fi"
		tell window "Registration"
			set vRegisteredName to contents of text field "reg_name"
			set vLicenseKey to contents of text field "lic_key"
		end tell
		if pDebug = 1 then
			tell me
				DisplayDebug("Write Pref Values", vRegisteredName & " " & vLicenseKey)
			end tell
		end if
		store property list {|name|:vRegisteredName, |LicenseKey|:vLicenseKey} in file (vPrefsPath)
	on error
		error "Unable to write preferences file" number 999
	end try
end WritePrefs

on CheckKey()
	try
		set vPrefsPath to (path to preferences as string) & "com.actionable_intelligence.Hijack_iT.plist"
		set vPrefsPlist to read property list file (vPrefsPath)
		tell window "Registration"
			set vCurrentName to contents of text field "reg_name"
			set vCurrentLicenseKey to contents of text field "lic_key"
		end tell
		-- Encode with a shift of tSh
		set vNameToKey to convNameToSerial(vCurrentName, tSh)
		set vKeyToName to convSerialToName(vCurrentLicenseKey, tSh)
		if pDebug = 1 then
			tell me
				DisplayDebug("Registration Key Validation", vCurrentName & " " & vKeyToName & " " & vCurrentLicenseKey & " " & vNameToKey)
			end tell
		end if
		if vKeyToName = vCurrentName then
			if vNameToKey = vCurrentLicenseKey then
				tell window "Registration"
					set contents of text field "registered" to "Registered"
				end tell
				tell window "main_window"
					set contents of text field "lic_status" to "Registered"
				end tell
				set vCustomer to "1"
			else
				tell window "Registration"
					set contents of text field "registered" to "Unregistered"
				end tell
				tell window "main_window"
					set contents of text field "lic_status" to "Unregistered"
				end tell
				set vCustomer to "0"
			end if
		else
			tell window "Registration"
				set contents of text field "registered" to "Unregistered"
			end tell
			tell window "main_window"
				set contents of text field "lic_status" to "Unregistered"
			end tell
			set vCustomer to "0"
		end if
		if pDebug = 1 then
			tell me
				DisplayDebug("Customer", vCustomer)
			end tell
		end if
		return vCustomer
	on error
		error "Unable to verify License Key" number 999
	end try
end CheckKey

on coerceToInteger(vRecord)
	--  This code coerces all the reals it finds in rec to integers.
	--  This code  also recurs down through any nested records it finds.
	--
	--  NOTE: this code *only* deals with user properties.  Its possible
	--  to process keyword properties as well, but that is an exercise
	--  for the reader.
	
	local keys, values
	
	--    Pull the record apart into a list of keys and a list of values
	set keys to get user property names vRecord
	set values to get user property keys in vRecord
	
	--    Iterate over the values, coercing and recurring as needed
	repeat with i from 1 to length of keys
		local itemClass
		
		set itemClass to class of item i of values
		if itemClass is record then
			set item i of values to coerceToInteger(item i of values)
		else if itemClass is real then
			set item i of values to (item i of values) as integer
		end if
	end repeat
	
	--  Construct and return a new record
	return set user property keys in {} to values
end coerceToInteger

on RegisterExtraSuites()
	set vExtraSuitesLoc to (path to me as string) & "Contents:Resources:Scripting Additions:Extra Suites.app" as string
	if pDebug = 1 then
		tell me
			DisplayDebug("Helper App", vExtraSuitesLoc)
		end tell
	end if
	using terms from application "Extra Suites"
		tell application vExtraSuitesLoc
			ES register "Sean Kane" with 26514284
		end tell
	end using terms from
end RegisterExtraSuites

on RegisterGrowl()
	if pDebug = 1 then
		tell me
			DisplayDebug("Growl", "Setup")
		end tell
	end if
	try
		tell application "GrowlHelperApp"
			-- Make a list of all the notification types 
			-- that this script will ever send:
			set the allNotificationsList to Â
				{"Current Recording"}
			
			-- Make a list of the notifications 
			-- that will be enabled by default.      
			-- Those not enabled by default can be enabled later 
			-- in the 'Applications' tab of the growl prefpane.
			set the enabledNotificationsList to Â
				{"Current Recording"}
			
			-- Register our script with growl.
			-- You can optionally (as here) set a default icon 
			-- for this script's notifications.
			register as application Â
				"Hijack iT!" all notifications allNotificationsList Â
				default notifications enabledNotificationsList Â
				icon of application "Hijack iT!"
		end tell
	end try
end RegisterGrowl

on ActivateAHP()
	if pDebug = 1 then
		tell me
			DisplayDebug("Activate", "AHP")
		end tell
	end if
	tell application "Audio Hijack Pro"
		try
			launch
		on error
			error "Could not start Audio Hijack Pro" number 100
		end try
	end tell
end ActivateAHP

on ActivateItunes()
	if pDebug = 1 then
		tell me
			DisplayDebug("Activate", "iTunes")
		end tell
	end if
	tell application "iTunes"
		try
			launch
		on error
			error "Could not initialize iTunes" number 101
		end try
	end tell
end ActivateItunes

on GetPlaylistName()
	tell window "main_window"
		try
			set vTheChoice to the title of popup button "Hijack" as string
			if pDebug = 1 then
				tell me
					DisplayDebug("PlayList Title", vTheChoice)
				end tell
			end if
		on error
			error "Could not determine what playlist was choosen." number 102
		end try
	end tell
	tell application "iTunes"
		try
			set pThePlaylist to item 1 of (every playlist whose name is vTheChoice)
			if pDebug = 1 then
				tell me
					DisplayDebug("iTunes Playlist", name of pThePlaylist)
				end tell
			end if
			return pThePlaylist
		on error
			error "Could not set playlist." number 103
		end try
	end tell
end GetPlaylistName

on GetSessionName()
	tell window "main_window"
		try
			set vTheChoice to the title of popup button "Session" as string
			if pDebug = 1 then
				tell me
					DisplayDebug("Session Title", vTheChoice)
				end tell
			end if
		on error
			error "Could not determine what session was choosen." number 102
		end try
	end tell
	tell application "Audio Hijack Pro"
		try
			set pTheSession to item 1 of (every session whose name is vTheChoice)
			if pDebug = 1 then
				tell me
					DisplayDebug("AHP Session", name of pTheSession)
				end tell
			end if
			return pTheSession
		on error
			error "Could not set session." number 103
		end try
	end tell
end GetSessionName

on CountTracks(pThePlaylist)
	tell application "iTunes"
		try
			set pTheTotal to count tracks in pThePlaylist
			if pDebug = 1 then
				tell me
					DisplayDebug("Total Tracks", pTheTotal)
				end tell
			end if
			return pTheTotal
		on error
			error "Could not determine how many tracks are in the playlist." number 104
		end try
	end tell
end CountTracks

on HijackItunes()
	if pDebug = 1 then
		tell me
			DisplayDebug("Hijack", "iTunes")
		end tell
	end if
	tell application "Audio Hijack Pro"
		tell pTheSession
			try
				start hijacking pTheSession relaunch yes
			on error
				error "Unable to start hijacking." number 112
			end try
		end tell
	end tell
end HijackItunes

on DisableTracks(pThePlaylist, pTheTotal)
	if pDebug = 1 then
		tell me
			DisplayDebug("Disable", "Tracks")
		end tell
	end if
	set vPlayedAll to false
	set vCount to 1
	repeat while vPlayedAll is false
		tell application "iTunes"
			try
				set enabled of track vCount of pThePlaylist to false
			on error
				error "Unable to disable track." number 112
			end try
		end tell
		set vCount to vCount + 1
		set vFinished to pTheTotal + 1
		if vCount = vFinished then
			set vPlayedAll to true
		end if
	end repeat
	if pMDR = "1" then
		tell me
			MinimizeApps()
		end tell
	end if
end DisableTracks

on GetTrackName(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vThisTrack to track vCount of pThePlaylist
			set vCurrentlyPlayingTemp to the name of vThisTrack
			set vCurrentlyPlaying to vCurrentlyPlayingTemp
			if pDebug = 1 then
				tell me
					DisplayDebug("Currently Playing", vCurrentlyPlaying)
				end tell
			end if
			return vCurrentlyPlaying
		on error
			error "Unable to get current track's name." number 113
		end try
	end tell
end GetTrackName

on GetTrackAlbum(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackAlbum to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackAlbum to the album of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Album", vTrackAlbum)
				end tell
			end if
			return vTrackAlbum
		end try
	end tell
end GetTrackAlbum

on GetTrackArtist(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackArtist to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackArtist to the artist of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Artist", vTrackArtist)
				end tell
			end if
			return vTrackArtist
		end try
	end tell
end GetTrackArtist

on GetTrackYear(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackYear to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackYear to the year of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Year", vTrackYear)
				end tell
			end if
			return vTrackYear
		end try
	end tell
end GetTrackYear

on GetTrackComposer(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackComposer to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackComposer to the composer of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Composer", vTrackComposer)
				end tell
			end if
			return vTrackComposer
		end try
	end tell
end GetTrackComposer

on GetTrackDiscCount(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackDiscCount to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackDiscCount to the disc count of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Disc Count", vTrackDiscCount)
				end tell
			end if
			return vTrackDiscCount
		end try
	end tell
end GetTrackDiscCount

on GetTrackDiscNumber(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackDiscNumber to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackDiscNumber to the disc number of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Disc Number", vTrackDiscNumber)
				end tell
			end if
			return vTrackDiscNumber
		end try
	end tell
end GetTrackDiscNumber

on GetTrackGenre(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackGenre to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackGenre to the genre of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track Genre", vTrackGenre)
				end tell
			end if
			return vTrackGenre
		end try
	end tell
end GetTrackGenre

on GetTrackTrackCount(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackTrackCount to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackTrackCount to the track count of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track's Track Count", vTrackTrackCount)
				end tell
			end if
			return vTrackTrackCount
		end try
	end tell
end GetTrackTrackCount

on GetTrackTrackNumber(pThePlaylist, vCount)
	tell application "iTunes"
		try
			set vTrackTrackNumber to ""
			set vThisTrack to track vCount of pThePlaylist
			set vTrackTrackNumber to the track number of vThisTrack
			if pDebug = 1 then
				tell me
					DisplayDebug("Track's Track Number", vTrackTrackNumber)
				end tell
			end if
			return vTrackTrackNumber
		end try
	end tell
end GetTrackTrackNumber

on SetRecordingName(vCurrentlyPlaying)
	tell application "Audio Hijack Pro"
		tell session pTheSession
			try
				set output name format of pTheSession to vCurrentlyPlaying
			on error
				error "Unable to set recording song name." number 116
			end try
		end tell
	end tell
end SetRecordingName

on SetTags(vTrackName, vTrackAlbum, vTrackArtist, vTrackYear, vTrackComposer, vTrackDiscCount, vTrackDiscNumber, vTrackGenre, vTrackTrackCount, vTrackTrackNumber)
	tell application "Audio Hijack Pro"
		tell session pTheSession
			try
				set title tag of pTheSession to vTrackName
				set year tag of pTheSession to (vTrackYear as string)
				set album tag of pTheSession to vTrackAlbum
				set artist tag of pTheSession to vTrackArtist
				set track number tag of pTheSession to (vTrackTrackNumber as string)
				set genre tag of pTheSession to vTrackGenre
				set comment tag of pTheSession to "Converted using Hijack iT! on an Apple Macintosh."
			on error
				error "Unable to set output file information tags." number 116
			end try
		end tell
	end tell
end SetTags

(*
on SetSilenceOptions(vDuration, vLevel)
	tell application "Audio Hijack Pro"
		tell session pTheSession
			try
				set duration of silence monitor options to vDuration
				set level of silence monitor options to vLevel
			on error
				error "Unable to setsilence options." number 116
			end try
		end tell
	end tell
end SetSilenceOptions
*)

on GetMusicFolder()
	tell application "Audio Hijack Pro"
		try
			set pMusicFolder to (get output folder of pTheSession)
			if pDebug = 1 then
				tell me
					DisplayDebug("Music Folder", pMusicFolder)
				end tell
			end if
		on error
			error "Can not determine where music is saved to." number 117
		end try
	end tell
	tell window "main_window"
		try
			set enabled of button "open_music" to true
		on error
			error "Can not enable Open Music Folder button." number 117
		end try
	end tell
end GetMusicFolder

on RewindTrack(pThePlaylist, vCount, vMovement)
	tell application "iTunes"
		try
			play track vCount of pThePlaylist
			pause track
			set the player position to 0
			if pDebug = 1 then
				tell me
					DisplayDebug("rewind", "track")
				end tell
			end if
		on error
			error "Unable to rewind track." number 119
		end try
	end tell
end RewindTrack

on RecordItunes()
	if pDebug = 1 then
		tell me
			DisplayDebug("Record", "iTunes")
		end tell
	end if
	tell application "Audio Hijack Pro"
		tell session pTheSession
			try
				start recording pTheSession
			on error
				error "Unable to start recording track." number 118
			end try
		end tell
	end tell
end RecordItunes

on PlaySong(pThePlaylist, vCount, vMovement, vTrackName, vTrackArtist)
	if pCanceled ­ 1 then
		try
			tell application "GrowlHelperApp" --	Send a Notification...
				notify with name Â
					"Current Recording" title Â
					"Starting to Record:" description vTrackName & "
" & vTrackArtist Â
					application name Â
					"Hijack iT!" icon of application "Hijack iT!"
			end tell
		end try
		tell application "iTunes"
			try
				play track vCount of pThePlaylist
				set vStartTime to (current date)
				if pDebug = 1 then
					tell me
						DisplayDebug("Track Start Time", vStartTime)
					end tell
				end if
			on error
				error "Unable to play track." number 119
			end try
		end tell
	end if
	if pCanceled ­ 1 then
		tell window "main_window" of me
			set vLicStatus to contents of text field "lic_status"
		end tell
	end if
	if pCanceled ­ 1 then
		tell application "iTunes"
			try
				set vSongLength to ((get finish of track vCount of pThePlaylist) + 1) as integer
				if vLicStatus = "Registered" and pCanceled ­ 1 then
					tell me
						DisplayDebug("Registered User", vLicStatus)
					end tell
					if vMovement = "1" and pCanceled ­ 1 then
						if pDebug = 1 then
							tell me
								DisplayDebug("Keep Awake", vMovement)
							end tell
						end if
						--Keep Awake Enabled
						set vMoveCount to 1 as integer
						tell me
							PopMouse(vMoveCount)
						end tell
						set vCurrentTime to (current date)
						set vElapsedTime to (vCurrentTime - vStartTime)
						set vRemainingTime to (vSongLength - vElapsedTime)
						repeat while vRemainingTime ³ 20 and pCanceled ­ 1
							tell me
								PopMouse(vMoveCount)
							end tell
							if vMoveCount = 1 then
								set vMoveCount to 0 as integer
							else
								set vMoveCount to 1 as integer
							end if
							delay 10
							set vCurrentTime to (current date)
							set vElapsedTime to (vCurrentTime - vStartTime)
							set vRemainingTime to (vSongLength - vElapsedTime)
						end repeat
						set vCurrentTime to (current date)
						set vElapsedTime to (vCurrentTime - vStartTime)
						set vRemainingTime to (vSongLength - vElapsedTime)
						if pCanceled ­ 1 then
							delay vRemainingTime
						end if
					else
						--No keep awake enabled
						if pDebug = 1 then
							tell me
								DisplayDebug("Keep Awake", vMovement)
							end tell
						end if
						set vCurrentTime to (current date)
						set vElapsedTime to (vCurrentTime - vStartTime)
						set vRemainingTime to (vSongLength - vElapsedTime)
						repeat while vRemainingTime ³ 20 and pCanceled ­ 1
							delay 10
							set vSongLength to ((get finish of track vCount of pThePlaylist) + 1) as integer
							set vCurrentTime to (current date)
							set vElapsedTime to (vCurrentTime - vStartTime)
							set vRemainingTime to (vSongLength - vElapsedTime)
						end repeat
						set vCurrentTime to (current date)
						set vElapsedTime to (vCurrentTime - vStartTime)
						set vRemainingTime to (vSongLength - vElapsedTime)
						if pCanceled ­ 1 then
							delay vRemainingTime
						end if
					end if
				else
					--DEMO version (unregistered)
					tell me
						DisplayDebug("Unregistered User", vLicStatus)
					end tell
					if vSongLength ³ 30 then
						delay 30
					else
						delay vSongLength
					end if
				end if
			on error
				error "Unable to determine when to stop recording." number 120
			end try
			try
				stop
			on error
				error "Unable to stop track." number 121
			end try
		end tell
	end if
end PlaySong

on StopRecording()
	if pDebug = 1 then
		tell me
			DisplayDebug("Stop", "Recording")
		end tell
	end if
	tell application "Audio Hijack Pro"
		tell session pTheSession
			try
				stop recording pTheSession
			on error
				error "Unable to stop recording." number 122
			end try
		end tell
	end tell
end StopRecording

on EnableTracks(pThePlaylist, pTheTotal)
	if pDebug = 1 then
		tell me
			DisplayDebug("Enable", "Tracks")
		end tell
	end if
	set vPlayedAll to false
	set vCount to 1
	repeat while vPlayedAll is false
		tell application "iTunes"
			try
				set enabled of track vCount of pThePlaylist to true
			on error
				error "Unable to enable track." number 123
			end try
		end tell
		set vCount to vCount + 1
		set vFinished to pTheTotal + 1
		if vCount = vFinished then
			set vPlayedAll to true
		end if
	end repeat
	if pMDR = "1" then
		tell me
			MinimizeApps()
			--does not work
			--set frontmost to true
		end tell
	end if
end EnableTracks

on ForceEnableTracks(pThePlaylist, pTheTotal)
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Enable", "Tracks")
		end tell
	end if
	set vPlayedAll to false
	set vCount to 1
	repeat while vPlayedAll is false
		tell application "iTunes"
			try
				set enabled of track vCount of pThePlaylist to true
			end try
		end tell
		set vCount to vCount + 1
		set vFinished to pTheTotal + 1
		if vCount = vFinished then
			set vPlayedAll to true
		end if
	end repeat
end ForceEnableTracks

on PopMouse(vMoveCount)
	try
		tell application "Extra Suites"
			set vMouseLoc to ES mouse location
			if pDebug = 1 then
				tell me
					DisplayDebug("Current Mouse Location", item 1 of vMouseLoc & " " & item 2 of vMouseLoc)
				end tell
			end if
			if vMoveCount = 1 then
				set item 1 of vMouseLoc to (item 1 of vMouseLoc) + 1
				set item 2 of vMouseLoc to (item 2 of vMouseLoc) + 1
			else
				set item 1 of vMouseLoc to (item 1 of vMouseLoc) - 1
				set item 2 of vMouseLoc to (item 2 of vMouseLoc) - 1
			end if
			ES move mouse vMouseLoc
			if pDebug = 1 then
				tell me
					DisplayDebug("New Mouse Location", item 1 of vMouseLoc & " " & item 2 of vMouseLoc)
				end tell
			end if
		end tell
	on error
		error "Failed to keep system awake." number 999
	end try
end PopMouse

on MinimizeApps()
	if pDebug = 1 then
		tell me
			DisplayDebug("Minimize", "iTunes")
		end tell
	end if
	tell application "iTunes"
		try
			--set miniaturized of every window to true
			set collapsed of window 1 to true
			--set zoomed of window 1 to true
		on error
			error "Could not minimize iTunes." number 124
		end try
	end tell
	if pDebug = 1 then
		tell me
			DisplayDebug("Minimize", "AHP")
		end tell
	end if
	tell application "Audio Hijack Pro"
		try
			set miniaturized of window 1 to true
		on error
			error "Could not minimize Audio Hijack Pro." number 124
		end try
	end tell
	if pDebug = 1 then
		tell me
			DisplayDebug("Minimize", "Hijack iT!")
		end tell
	end if
	--tell me
	--try
	--set collapsed of window 1 to true
	--on error
	--error "Could not minimize Hijack iT!." number 124
	--end try
	--end tell
end MinimizeApps

on MaximizeApps()
	if pDebug = 1 then
		tell me
			DisplayDebug("Maximize", "iTunes")
		end tell
	end if
	tell application "iTunes"
		try
			--Bug in iTunes - This does not work
			--set collapsed of window 1 to false
			set visible of window 1 to false
			set visible of window 1 to true
		on error
			error "Could not maximize iTunes." number 124
		end try
	end tell
	if pDebug = 1 then
		tell me
			DisplayDebug("Maximize", "AHP")
		end tell
	end if
	tell application "Audio Hijack Pro"
		try
			set miniaturized of window 1 to false
		on error
			error "Could not maximize Audio Hijack Pro." number 124
		end try
	end tell
	if pDebug = 1 then
		tell me
			DisplayDebug("Maximize", "Hijack iT!")
		end tell
	end if
	--tell me
	--try
	--set miniaturized of every window to false
	--on error
	--error "Could not maximize Hijack iT!." number 124
	--end try
	--end tell
end MaximizeApps

on ForceMaximizeApps()
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Maximize", "iTunes")
		end tell
	end if
	tell application "iTunes"
		--Bug in iTunes. This does not work
		--set collapsed of window 1 to false
		set visible of window 1 to false
		set visible of window 1 to true
	end tell
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Maximize", "AHP")
		end tell
	end if
	tell application "Audio Hijack Pro"
		set miniaturized of window 1 to false
	end tell
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Maximize", "Hijack iT!")
		end tell
	end if
	--tell me
	--set miniaturized of every window to false
	--end tell
end ForceMaximizeApps

on QuitItunes()
	if pDebug = 1 then
		tell me
			DisplayDebug("Quit", "iTunes")
		end tell
	end if
	tell application "iTunes"
		try
			quit
		on error
			error "Could not quit iTunes." number 124
		end try
	end tell
end QuitItunes

on QuitAHP()
	if pDebug = 1 then
		tell me
			DisplayDebug("Quit", "AHP")
		end tell
	end if
	tell application "Audio Hijack Pro"
		try
			quit
		on error
			error "Unable to quit Audio Hijack Pro" number 125
		end try
	end tell
end QuitAHP

on ForceQuitItunes()
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Quit", "iTunes")
		end tell
	end if
	tell application "iTunes"
		try
			quit
		end try
	end tell
end ForceQuitItunes

on ForceQuitAHP()
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Quit", "AHP")
		end tell
	end if
	tell application "Audio Hijack Pro"
		try
			quit
		end try
	end tell
end ForceQuitAHP

on CleanUp(pThePlaylist, pTheTotal)
	if pDebug = 1 then
		tell me
			DisplayDebug("Cleaning", "Up")
		end tell
	end if
	EnableTracks(pThePlaylist, pTheTotal)
	if pMDR = "1" then
		tell me
			MaximizeApps()
			--does not work
			--set frontmost to true
		end tell
	end if
end CleanUp

on ForceCleanUp(pThePlaylist, pTheTotal)
	if pDebug = 1 then
		tell me
			DisplayDebug("Force Cleaning", "Up")
		end tell
	end if
	ForceEnableTracks(pThePlaylist, pTheTotal)
	if pMDR = "1" then
		tell me
			ForceMaximizeApps()
			--does not work
			--set frontmost to true
		end tell
	end if
end ForceCleanUp

on OpenResults()
	try
		if pDebug = 1 then
			tell me
				DisplayDebug("Open Music Folder", quoted form of pMusicFolder)
			end tell
		end if
		do shell script "open " & quoted form of pMusicFolder
	on error
		error "Unable to open folder that contains saved music." number 126
	end try
end OpenResults

on clicked theObject
	if pDebug = 1 then
		tell me
			DisplayDebug("Clicked Object", name of theObject)
		end tell
	end if
	if name of theObject = "open_music" then
		tell me
			OpenResults()
		end tell
	else if name of theObject = "refresh_playlists" then
		try
			tell application "iTunes"
				set returnedPlaylists to name of playlists
			end tell
		on error
			error "Unable to get playlists." number 127
		end try
		try
			delete every menu item of menu of the popup button "Hijack" of window "main_window"
		on error
			error "Unable to delete playlist menu items." number 128
		end try
		repeat with playlistName in returnedPlaylists
			if pDebug = 1 then
				tell me
					DisplayDebug("Playlist Name", playlistName)
				end tell
			end if
			try
				make new menu item at the end of menu items of menu of the popup button "Hijack" of window "main_window" with properties {title:playlistName, enabled:true}
			on error
				error "Unable to make new playlist menu item." number 129
			end try
		end repeat
	else if name of theObject = "refresh_sessions" then
		try
			tell application "Audio Hijack Pro"
				set returnedSessions to name of sessions
			end tell
		on error
			error "Unable to get sessions." number 127
		end try
		try
			delete every menu item of menu of the popup button "Session" of window "main_window"
		on error
			error "Unable to delete session menu items." number 128
		end try
		repeat with sessionName in returnedSessions
			if pDebug = 1 then
				tell me
					DisplayDebug("Session Name", sessionName)
				end tell
			end if
			try
				make new menu item at the end of menu items of menu of the popup button "Session" of window "main_window" with properties {title:sessionName, enabled:true}
			on error
				error "Unable to make new session menu item." number 129
			end try
		end repeat
	else if name of theObject = "reg_done" then
		try
			hide window "registration"
		on error
			error "Could not close registration window" number 300
		end try
	else if name of theObject = "buy_now" then
		try
			open location "http://homepage.mac.com/spkane/ai_software/purchases.html"
		on error
			error "Unable to open web page" number 300
		end try
	else if name of theObject = "cancel" then
		try
			set pCanceled to 1 as integer
			if pDebug = 1 then
				tell me
					DisplayDebug("Canceled", pCanceled)
				end tell
			end if
		on error
			error "Could not cancel process" number 300
		end try
	else if name of theObject = "quit_apps" then
		tell window "main_window"
			set pQuitApps to the state of the button "quit_apps" as string
		end tell
	else if name of theObject = "Start_Button" then
		tell window "main_window"
			set enabled of button "Start_Button" to false
		end tell
		set pCanceled to 0 as integer
		tell window "main_window"
			set vMovement to the state of button "movement" as string
			set pMDR to the state of the button "mdr" as string
			set pESM to the state of the button "esm" as string
			set pDB to the contents of text field "db"
			set pSeconds to the contents of the text field "seconds"
		end tell
		if pMDR = "1" and pCanceled ­ 1 then
			MinimizeApps()
		end if
		if pCanceled ­ 1 then
			GetPlaylistName()
			set pThePlaylist to result
		end if
		if pCanceled ­ 1 then
			GetSessionName()
			set pTheSession to result
		end if
		if pCanceled ­ 1 then
			CountTracks(pThePlaylist)
			set pTheTotal to result
		end if
		if pCanceled ­ 1 then
			HijackItunes()
		end if
		if pCanceled ­ 1 then
			DisableTracks(pThePlaylist, pTheTotal)
		end if
		if pCanceled ­ 1 then
			GetMusicFolder()
		end if
		set vCount to 1
		set vPlayedAll to false
		repeat while vPlayedAll is false and pCanceled ­ 1
			if pCanceled ­ 1 then
				GetTrackName(pThePlaylist, vCount)
				set vCurrentlyPlaying to result
				set vTrackName to vCurrentlyPlaying
			end if
			if pCanceled ­ 1 then
				GetTrackAlbum(pThePlaylist, vCount)
				set vTrackAlbum to result
			end if
			if pCanceled ­ 1 then
				GetTrackArtist(pThePlaylist, vCount)
				set vTrackArtist to result
			end if
			if pCanceled ­ 1 then
				GetTrackYear(pThePlaylist, vCount)
				set vTrackYear to result
			end if
			if pCanceled ­ 1 then
				GetTrackComposer(pThePlaylist, vCount)
				set vTrackComposer to result
			end if
			if pCanceled ­ 1 then
				GetTrackDiscCount(pThePlaylist, vCount)
				set vTrackDiscCount to result
			end if
			if pCanceled ­ 1 then
				GetTrackDiscNumber(pThePlaylist, vCount)
				set vTrackDiscNumber to result
			end if
			if pCanceled ­ 1 then
				GetTrackGenre(pThePlaylist, vCount)
				set vTrackGenre to result
			end if
			if pCanceled ­ 1 then
				GetTrackTrackCount(pThePlaylist, vCount)
				set vTrackTrackCount to result
			end if
			if pCanceled ­ 1 then
				GetTrackTrackNumber(pThePlaylist, vCount)
				set vTrackTrackNumber to result
			end if
			if pCanceled ­ 1 then
				SetRecordingName(vCurrentlyPlaying)
			end if
			if pCanceled ­ 1 then
				SetTags(vTrackName, vTrackAlbum, vTrackArtist, vTrackYear, vTrackComposer, vTrackDiscCount, vTrackDiscNumber, vTrackGenre, vTrackTrackCount, vTrackTrackNumber)
			end if
			if pCanceled ­ 1 then
				RewindTrack(pThePlaylist, vCount, vMovement)
			end if
			if pCanceled ­ 1 then
				RecordItunes()
			end if
			if pCanceled ­ 1 then
				PlaySong(pThePlaylist, vCount, vMovement, vTrackName, vTrackArtist)
			end if
			if pCanceled ­ 1 then
				StopRecording()
			end if
			set vCount to vCount + 1
			set vFinished to pTheTotal + 1
			if pCanceled ­ 1 then
				if vCount = vFinished then
					set vPlayedAll to true
				end if
				if pDebug = 1 then
					tell me
						DisplayDebug("Played All Tracks", vPlayedAll)
					end tell
				end if
			end if
		end repeat
		if pCanceled ­ 1 then
			CleanUp(pThePlaylist, pTheTotal)
			OpenResults()
		else
			CleanUp(pThePlaylist, pTheTotal)
		end if
		tell window "main_window"
			set enabled of button "Start_Button" to true
		end tell
	end if
end clicked

on choose menu item theObject
	if pDebug = 1 then
		tell me
			DisplayDebug("Choosen Menu Object", name of theObject)
		end tell
	end if
	if name of theObject = "Help" then
		set vHelpPath to (path to me as string) & "Contents:Resources:HI_README.pdf"
		set vPosixHelpPath to POSIX path of file vHelpPath
		if pDebug = 1 then
			tell me
				DisplayDebug("Help Path", quoted form of vPosixHelpPath)
			end tell
		end if
		try
			do shell script "open " & quoted form of vPosixHelpPath
		on error
			error "Could not open help file."
		end try
	else if name of theObject = "register" then
		try
			show window "registration"
		on error
			error "Could not open registration window" number 300
		end try
	else if name of theObject = "open_log" then
		try
			show window "debug_window"
		on error
			error "Could not open debug window" number 300
		end try
	else if name of theObject = "QuitHI" then
		if pQuitApps = "1" then
			ForceQuitItunes()
			ForceQuitAHP()
		end if
		quit
	end if
end choose menu item

on action theObject
	if pDebug = 1 then
		tell me
			DisplayDebug("Action Object", name of theObject)
		end tell
	end if
	if name of theObject = "reg_name" or name of theObject = "lic_key" then
		CheckKey()
		set vCustomer to result
		WritePrefs()
	end if
end action

on awake from nib theObject
	if pDebug = 1 then
		tell me
			show window "debug_window"
			DisplayDebug("Awake Object", name of theObject)
		end tell
	end if
	if name of theObject = "Registration" then
		ReadPrefs()
		CheckKey()
		set vCustomer to result
	else if name of theObject = "Hijack" then
		set pNewLog to 0
		RegisterGrowl()
		RegisterExtraSuites()
		ActivateItunes()
		try
			tell application "iTunes"
				set returnedPlaylists to name of playlists
			end tell
		on error
			error "Unable to get playlists." number 127
		end try
		try
			delete every menu item of menu of theObject
		on error
			error "Unable to delete playlist menu items." number 128
		end try
		repeat with playlistName in returnedPlaylists
			if pDebug = 1 then
				tell me
					DisplayDebug("Playlist Name", playlistName)
				end tell
			end if
			try
				make new menu item at the end of menu items of menu of theObject with properties {title:playlistName, enabled:true}
			on error
				error "Unable to make new playlist menu item." number 129
			end try
		end repeat
	else if name of theObject = "Session" then
		ActivateAHP()
		try
			tell application "Audio Hijack Pro"
				set returnedSessions to name of sessions
			end tell
		on error
			error "Unable to get sessions." number 127
		end try
		try
			delete every menu item of menu of theObject
		on error
			error "Unable to delete session menu items." number 128
		end try
		repeat with sessionName in returnedSessions
			if pDebug = 1 then
				tell me
					DisplayDebug("Session Name", sessionName)
				end tell
			end if
			try
				make new menu item at the end of menu items of menu of theObject with properties {title:sessionName, enabled:true}
			on error
				error "Unable to make new session menu item." number 129
			end try
		end repeat
	end if
end awake from nib

on should quit after last window closed theObject
	if pDebug = 1 then
		tell me
			DisplayDebug("Should Quit Object", name of theObject)
		end tell
	end if
	ForceCleanUp(pThePlaylist, pTheTotal)
	if pQuitApps = "1" then
		ForceQuitItunes()
		ForceQuitAHP()
	end if
	quit
end should quit after last window closed

on should close theObject
	if name of theObject = "main_window" then
		if pDebug = 1 then
			tell me
				DisplayDebug("Should Close Object", name of theObject)
			end tell
		end if
		if pQuitApps = "1" then
			ForceQuitItunes()
			ForceQuitAHP()
		end if
		quit
	end if
end should close
