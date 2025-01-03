    %IFNDEF Parties_Filelist                        // include this only once
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// TEXT FILE: PARTIES.TXT
//
//  AAM KEYS: PARTIES.AAM           -> lastName, firstName, termStartDate, termEndDate, partyID, vicePresidents
//
// ISAM KEYS: PARTIES_BY_ID.ISI     -> id 
//            PARTIES_BY_NAME.ISI   -> description
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
Parties_Filelist        filelist
Parties_IFile           ifile           fixed=34,name="PARTIES_BY_ID.ISI"
Parties_IFile2          ifile           fixed=34,name="PARTIES_BY_NAME.ISI"
                        filelistend

Parties_IO              record          definition      // BYTES    DESCRIPTION
collision               form            2               // 001-002  numeric value, incremented on each write/update, rolls over to 0 after 99
id                      form            2               // 003-004  unique record identified
description             dim             30              // 005-034  unique description of party
                        recordend

Parties_IKey_Size       const           "2"             // id
Parties_IKey2_Size      const           "30"            // description
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// write a function that reads the ini for parties, and makes
// a dynamic list of all the parties for our combobox and then gives them
// a number associated with them, this makes it so when we have "federalist" it has 
// the number "1" with it, we can use this for our lookups
initCombobox function
pCombobox               combobox        ^
//need object
    entry
partyRec                record like     Parties_IO 
dummykey                init            0x01
workString              dim             32768
hex09                   init            0x09
hex7F                   init            0x7F

    pCombobox.ResetContent
    //do a read with a dummy key to make sure we are at the top of the file
    read Parties_IFile2,dummykey;;
    loop

        readks Parties_IFile2;partyRec
        until (over)                      //how to get ID?
        append hex7F to workString
        append partyRec.description to workString
        append hex09 to workString
        append partyRec.id to workString
        
    
    repeat 
    reset workString
    pCombobox.addstring using *String=workString:
                              *Flags=1

    functionend
    %ENDIF