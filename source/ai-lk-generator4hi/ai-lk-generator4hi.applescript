-- ai-lk-generator4hi.applescript
-- ai-lk-generator4hi

Hijack iT by Sean P. Kane is licensed under a Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
https://github.com/spkane/Hijack-iT

(*
Original code written by Thomas Kuehner, Koeln, Germany, 05-25-2003 - <macgix@macgix-services.com> - <http://macgix-services.com>.
*)

-- Definition of the translation table definition. Please change bList to your own! 
property aList : {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F"}
--for pd
property bList : {"0", "2", "m", "1", "w", "f", "3", "o", "n", "4", "u", "k", "s", "9", "5", "j"}
--for hi
--property bList : {"4", "2", "6", "9", "J", "a", "n", "X", "Q", "z", "8", "3", "L", "o", "V", "e"}

-- The shift used by subroutines
--for pad
property tSh : 3 -- Shift should not lead to ascii numbers smaller than 1 and higher than 255 ! - Respect it!
--for hi
--property tSh : 4 -- Shift should not lead to ascii numbers smaller than 1 and higher than 255 ! - Respect it!


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



on clicked theObject
	if name of theObject = "generate" then
		try
			tell window "main_window"
				set tRes to contents of text field "name"
				set vName to tRes
			end tell
			set tRes to convNameToSerial(tRes, tSh)
			set vLicKey to tRes
			tell window "main_window"
				set contents of text field "lic_key" to tRes
			end tell
			set tRes to convSerialToName(tRes, tSh)
			set vRevName to tRes
			tell window "main_window"
				set contents of text field "rev_name" to tRes
			end tell
			if vRevName ­ vName then
				display dialog "Warning something is wrong. License Key does not decode to the same name that was entered!!"
			end if
		on error
			error "Unable to generate key." number 999
		end try
	end if
end clicked