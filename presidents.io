    %IFNDEF Presidents_Filelist                     // include this only once
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
// TEXT FILE: PRESIDENTS.TXT
//
//  AAM KEYS: PRESIDENTS.AAM                            -> lastName, firstName, termStartDate, termEndDate, partyID, 
//                                                          vicePresidents
//
// ISAM KEYS: PRESIDENTS_BY_LAST_FIRST_STARTDATE.ISI    -> termStartDate 
//            PRESIDENTS_BY_STARTDATE.ISI               -> lastName, firstName, termStartDate
//
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    include "fileio.inc"                            // contains IKEY definition
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Presidents_Filelist is in the UDA namespace - there's not a good way around it unfortunately
Presidents_Filelist     filelist
Presidents_AFile        afile           fixed=122,name="PRESIDENTS.AAM"
Presidents_IFile        ifile           fixed=122,name="PRESIDENTS_BY_LAST_FIRST_STARTDATE.ISI"
Presidents_IFile2       ifile           fixed=122,name="PRESIDENTS_BY_STARTDATE.ISI"
                        filelistend

Presidents_Record       record definition           // BYTES    DESCRIPTION
collision               form            2       // 001-002  numeric value, incremented on each write/update, rolls over to 0 after 99
lastName                dim             20      // 003-022  president's last name  
firstName               dim             15      // 023-037  president's first name
termStartDate           dim             8       // 038-045  YYYYMMDD start date of term (first term if re-elected consecutively)
termEndDate             dim             8       // 046-053  YYYYMMDD end date of term (second term if  re-elected consecutively; blank 
                                                            //           for current president)
partyID                 form            2       // 054-055  id value that represents a value from the parties file
vicePresidents          dim             67      // 056-122  free-form list of vice presidents (if any)
                        recordend

Presidents_IKey_Size    const           "43"      // lastName, firstName, termStartDate
Presidents_IKey2_Size   const           "8"       // termStartDate

PresidentsAKeys         record          definition           // Key# Type    Examples
lastName                dim             23      // 01   L,X,F   "01LJ"      - matches Jefferson, Johnson, Jackson  
firstName               dim             18      // 02   L,X,F   "02LJohn"   - matches John Adams, John Quincy Adams, John Tyler, etc.
termStartDate           dim             11      // 03   L,X,F   "03L19"     - matches all presidents inaugurated in 20th century (1900's)
termEndDate             dim             11      // 04   L,X,F   "04L18"     - matches all presidents whose terms ended in 19th century
partyID                 dim             5       // 05   X       "05X 2"     - matches all presidents with partyID = 2 (Democratic)
vicePresidents          dim             70      // 06   F       "06FJohn"   - matches all records where VP field contains "john"
                        recordend

AkeysPrep               record          definition  
lastNameAKeyPrep        dim             30         
firstNameAKeyPrep       dim             30 
vicepresAKeyPrep        dim             30  
partyDescAKeyPrep       dim             30
termStartCheck          integer         1       
termEndCheck            integer         1       
                        recordend
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
PresidentsBuildAKeys function
presAkeys               record likeptr  PresidentsAKeys
AkeysP                  record likeptr  AkeysPrep     
    entry
partyID                 form            1
workVar                 dim             100

    // chop AKeysP
    if (AkeysP.lastNameAKeyPrep!="")
        pack presAKeys.lastName from "01F",AkeysP.lastNameAKeyPrep
    endif 

    if (AkeysP.firstNameAKeyPrep!="")
        pack presAKeys.firstName from "02F",AkeysP.firstNameAKeyPrep
    endif   

    if (AkeysP.termStartCheck="1")
        getprop mainWinTermStartEDT, text=workVar    
        if (workVar!="0" && workVar!="")
            pack presAKeys.termStartDate from "03F",workVar
        endif
    endif  

    if (AkeysP.termEndCheck="1")
        getprop mainWinTermEndEDT, text=workVar    
        if (workVar!="0" && workVar!="")
            pack presAKeys.termEndDate from "04F",workVar
        endif  
     endif

    if (AkeysP.partyDescAKeyPrep!="")
        call GetComboboxItemID giving partyID using mainWinPartyCB
        move partyID to workVar
        chop workVar

        pack presAKeys.partyID from "05F ",workVar
    endif
    debug
    if (AkeysP.vicepresAKeyPrep!="")
        pack presAKeys.vicePresidents from "06F",AkeysP.vicepresAKeyPrep
    endif  

    functionend
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
updateRecord function
presidents_Rec          record like     Presidents_Record
hiddenISAMData          dim             Presidents_IKey_Size
    entry
errorText               dim             200

    // Grabs our values from our hidden Column, reads the data to make sure we have the right
    // record, and then we increase collision because we are doing a update
    read Presidents_IFile,hiddenISAMData; presidents_Rec.collision, *LL
    incr presidents_Rec.collision

    update Presidents_Filelist;presidents_Rec

    functionend
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
saveRecord function
presidents_Rec          record          like Presidents_Record
    entry

    incr presidents_Rec.collision //will always be one here
    write Presidents_Filelist;presidents_Rec

    functionend
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
deleteRecord function
    entry
presidents_Rec          record like     Presidents_Record
hiddenISAMData          dim             Presidents_IKey_Size 
errorText               dim             200

    // Gather hidden data and read to be sure we have the right file
    call gatherHiddenColData giving hiddenISAMData
    read Presidents_IFile,hiddenISAMData; presidents_Rec, *LL

    // If over, then nothing was selected to delete
    if over
        move "There Was An Issue Finding That Record" to errorText
        call errorHandler using errorText
        return
    endif

    // If not over, deletes the record.
    delete Presidents_Filelist

    // Removes the record from our LV
    call removeDeletedItemFromListView
    call closeEditWin

    functionend
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    %ENDIF
    