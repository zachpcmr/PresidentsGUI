////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Init
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
fileManagerWin          plform          "fileManager_search.plf"
editModal               plform          "filemanager_edit.plf"
                        include         "presidents.io"
                        include         "parties.io"
//global vars are lame...
//but its the only okish solution I can think of
#sortedStateTracker     integer         1(6):
#firstNameTrack                         ("0"):
#lastNameTrack                          ("0"):
#termStartTrack                         ("0"):
#termEndTrack                           ("0"):
#vicePTrack                             ("0"):
#partyTrack                             ("0")
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Start
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
start
    
    call main
    stop
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Start of Main, this is where the program loops forever from.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
main function
    entry

    call openFiles
    call initializeForms
    call initCombobox using editWinPartyCB
    call initCombobox using mainWinPartyCB
    call LoadPresidentsInfoIntoListViewISAM
    
    loop
        waitevent
    repeat
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Takes presidents from a read, and one by one and lists them in the LV
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LoadPresidentsInfoIntoListViewISAM function
    entry
presidents_Rec          record like     Presidents_Record   // Record structure for president information
dummykey                init            0x01                // Initial dummy key value
errorText               dim             200                 // Buffer for error messages
presidentPartyName      dim             30                  // Buffer for president party name
addDataToList           form            "1"                 // Form with a value of one, which is passed as a param for display to add
itemCount               form            4                   // Counter for the number of items

    read Presidents_IFile,dummykey;;

    loop 
        // Read from the ISAM file into the record
        readks Presidents_IFile; presidents_Rec, *LL      
        until over
        call chopPresidentsRec using presidents_Rec       
        call getPresidentpartyNameDescription giving presidentPartyName using presidents_Rec.partyID  
        call DisplayPresidentsInfoIntoListView giving itemCount using presidents_Rec,presidentPartyName,addDataToList

    repeat
    
    call recordCountSetter using itemCount               
    call setFocusToFirstItem
    setprop     MainWin,visible=1                      

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Chop presidents records for easy insertion to the LV
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
chopPresidentsRec function
presidents_Rec          record likeptr  Presidents_Record   // Record structure for president information
    entry

    chop presidents_Rec.firstName
    chop presidents_Rec.lastName
    chop presidents_Rec.termStartDate
    chop presidents_Rec.termEndDate
    chop presidents_Rec.vicePresidents

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Takes the partyID, reads to find what it corresponds to, and takes the description from the match.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
getPresidentpartyNameDescription function
partyID                 form            2
    entry
partyKey                dim             Parties_IKey_Size  //size 2
partyRec                record like     Parties_IO  
errorText               dim             200

    packkey partyKey from partyID
    read Parties_IFile,partyKey;partyRec, *LL
    
    if over
        move "INVALID PARTY" to partyRec.Description
        move "Invalid Party" to errorText
        call errorHandler using errorText
        return
    endif

    chop partyRec.Description
    return using partyRec.Description

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Goes through each record, or just one for edits, and lists them on the listview
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DisplayPresidentsInfoIntoListView function
presidents_Rec          record like     Presidents_Record
presidentPartyName      dim             30       
operationMode           form            2
    entry 
hiddenRowISAMKeys       dim             120
lvRow                   form            10
itemCount               form            4
dateMaskStart           init            "9999-99-99"
dateMaskEnd             init            "9999-99-99"
nextSelectedItem        form            "1"
ADD_ITEM                form            "1"

    packkey hiddenRowISAMKeys from presidents_Rec.lastName,presidents_Rec.firstName,presidents_Rec.termStartDate
    // ItemCount is the amount of items in the Lv
    MainWinPresidentsLV.GetItemCount giving itemCount
    // Displays date in a user friendly syntax
    edit presidents_Rec.termStartDate into dateMaskStart
    edit presidents_Rec.termEndDate into dateMaskEnd
    if (dateMaskEnd="9999-99-99")
        move "" to dateMaskEnd
    endif

    // This case is for adding 
    if (operationMode=ADD_ITEM)

        // Insert record at bottom
        MainWinPresidentsLV.InsertItemEx using  *Text=hiddenRowISAMKeys:
                                        *Index=itemCount:    //= The amount of items, so it inserts at bottom
                                        *Subitem1=presidents_Rec.lastName:
                                        *Subitem2=presidents_Rec.firstName:
                                        *Subitem3=dateMaskStart:
                                        *Subitem4=dateMaskEnd:
                                        *Subitem5=presidents_Rec.vicePresidents:
                                        *Subitem6=presidentPartyName

    // This case is for editing
    else 
        // Gets the item selected, packs up two seperate string, combines them, and replaces the
        // previous data for the item with the updated info.
        call editARecordForLV using presidents_Rec,lvRow,nextSelectedItem,hiddenRowISAMKeys:
                                    dateMaskStart,dateMaskEnd,presidentPartyName                                     
    endif
    // Return how many items are in the Lv
    return using itemCount
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Edits a record from the LV with updated information, overwriting the previous info.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
editARecordForLV function
presidents_Rec          record like     Presidents_Record
lvRow                   form            10
nextSelectedItem        form            "1"
hiddenRowISAMKeys       dim             120
dateMaskStart           init            "9999-99-99"
dateMaskEnd             init            "9999-99-99"
presidentPartyName      dim             30     
    entry
workString              dim             32768
workString2             dim             32768
successCheck            integer         1

    MainWinPresidentsLV.GetNextItem giving lvRow using *Flags=nextSelectedItem:
                                                       *Start=(-1)

    // 0 is the place holder for col 0, we need col 0 to have the right amount of spaces so we packkey it
    // but we can just pack everything else. Our delimiter is | which seperates each column for the item
    pack workString from "0|",presidents_Rec.lastName,"|",presidents_Rec.firstName,"|",dateMaskStart:
                            "|",dateMaskEnd,"|",presidents_Rec.vicePresidents,"|",presidentPartyName
    packkey workString2 from hiddenRowISAMKeys

    // 0x20 replaces data in the row, will only let it be a literal for some reason.
    MainWinPresidentsLV.SetItemTextAll giving successCheck using *Index=lvRow:
                                                                 *Text=workString:
                                                                 *Options=0x20:
                                                                 *Delimiter="|"

    // Makes sure our hiddenISAMrow has the correct spacing
    MainWinPresidentsLV.SetItemText giving successCheck using *Index=lvRow:
                                                              *Text=workString2
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Lists how many items are in the Lv on our mainWin at the bottom of the page
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
recordCountSetter function
itemCount               form            4
dimTemp                 dim             30
    entry
    pack dimTemp from "Records: ",itemCount
    setprop mainWinRecordCount, Text=dimTemp

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Sets up all our forms so we can use them going forward.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
initializeForms function
    entry

    formload    fileManagerWin
    formload    editModal
    //change this back to 0 after development
    setprop     MainWin,visible=1
    setprop     editWin,visible=0
    setfocus    mainWinLastNameET

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Opens all our files that our program relies on
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
openFiles function
    entry

    open Presidents_Filelist
    open Parties_Filelist

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Search with the keys provided by user
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LoadPresidentsInListViewAAM function
presAKeys               record like     PresidentsAKeys 
presidents_Rec          record like     Presidents_Record    
    entry
errorText               dim             200
hiddenRowISAMKeys       dim             120
presidentPartyName      dim             30
itemCount               form            4
addDataToList           form            "1"

    // Read to find the record with keys
    read Presidents_AFile,presAKeys; presidents_Rec, *LL

    // If we didnt find anything that matched...
    if over
        move "There was an issue finding records that matched those parameters." to errorText
        call errorHandler using errorText
        return
    endif

    // If we found a match, chop it to insert into LV, get the description of party for the LV...
    call chopPresidentsRec using presidents_Rec
    call getPresidentpartyNameDescription giving presidentPartyName using presidents_Rec.partyID  

    // Go through each record found, displaying each one.
    loop
        call chopPresidentsRec using presidents_Rec
        call DisplayPresidentsInfoIntoListView giving itemCount using presidents_Rec,presidentPartyName,addDataToList
        readkg Presidents_AFile; presidents_Rec, *LL                            
    repeat until over

    call setFocusToFirstItem 
    // Update the amount of records.
    call recordCountSetter using itemCount

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// After the list is filled, makes sure to select the first item in the list
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
setFocusToFirstItem function
    entry
focusAndSelected        form            "3"
    MainWinPresidentsLV.SetItemState using *Index=0:
                                        *State=focusAndSelected:
                                        *Statemask=0x3
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Pack records for AAM search keys
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
ConvertSearchParamsToAKeys function
presAKeys               record likeptr  PresidentsAKeys
    entry
workVar                 dim             100
isItemBlank             dim             10 
partyID                 form            1
selectedComboboxItem    form            1
checkedValue            integer         1  
AkeysPrepare            record like     AkeysPrep  

    // Grabs the value of LastName
    getprop mainWinLastNameET, text=workVar    
    move workVar to AkeysPrepare.lastNameAKeyPrep

    // Grabs the value of FirstName
    getprop mainWinFirstNameET, text=workVar    
    move workVar to AkeysPrepare.firstNameAKeyPrep

    // Grabs the value of Term Start
    getprop mainWinTermStartEDT, checked=checkedValue
    move checkedValue to AkeysPrepare.termStartCheck

    // Grabs the value of Term End
    getprop mainWinTermEndEDT, checked=checkedValue
    move checkedValue to AkeysPrepare.termEndCheck

    // Checks on our combo box and sees if they clicked option
    mainWinPartyCB.GetText giving isItemBlank
    move isItemBlank to AkeysPrepare.partyDescAKeyPrep

    // Grabs the value of Vice President/s
    getprop mainWinVicePresET, text=workVar    
    move workVar to AkeysPrepare.vicepresAKeyPrep

    call PresidentsBuildAKeys using presAkeys,AkeysPrepare
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Collect data from input boxes, put into record
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
gatherEditFormData  function
presidents_Rec          record likeptr  Presidents_Record
    entry
workVar                 dim             2000
errorText               dim             200
partyID                 form            1
selectedComboboxItem    form            1
emptyCheck              integer         1
AAMCharCheck            integer         2
errorLength             integer         4
checkedValue            integer         1

    // Grab value of LastName
    getprop editWinLastNameET, text=workVar
    chop workVar
    movelptr workVar to AAMCharCheck
    
    if (workVar!="" && AAMCharCheck>2)
        move workVar to presidents_Rec.lastName  
    else
        move "Please enter a lastname of 3 characters or more " to errorText
    endif

    // Grab value of FirstName
    getprop editWinFirstNameET, text=workVar
    chop workVar
    movelptr workVar to AAMCharCheck
    if (workVar!="" && AAMCharCheck>2)
        move workVar to presidents_Rec.firstName
    else
        append "Please enter a firstname of 3 characters or more " to errorText
    endif

    // Grab value of TermStart
    getprop editWinTermStartEDT, text=workVar
    chop workVar
    movelptr workVar to AAMCharCheck
    move workVar to presidents_Rec.termStartDate

    // Grab value of TermEnd, which is ALLOWED to be nothing
    // if its unchecked, pass a value of NOTHING as the end date.
    // otherwise, just pass whatever the date is set to.
    getprop editWinTermEndEDT, checked=checkedValue
    if (checkedValue=0)
        move "" to presidents_Rec.termEndDate
    else
        getprop editWinTermEndEDT, text=workVar
        chop workVar
        movelptr workVar to AAMCharCheck
        move workVar to presidents_Rec.termEndDate
    endif

    // Grab value/s of Vice Presidents
    getprop editWinVicePresET, text=workVar
    chop workVar
    movelptr workVar to AAMCharCheck
    if (AAMCharCheck>2 || AAMCharCheck=0)
        move workVar to presidents_Rec.vicePresidents
    else
        append "Please enter a vice president name of 3 characters or more " to errorText
    endif
    
    call GetComboboxItemID giving partyID using editWinPartyCB

    move partyID to presidents_Rec.partyID
    reset errorText
    chop errorText
    count errorLength from errorText
    
    //if multiple errors throw generic
    if (errorLength>65)
        move "Please fill out all forms with three characters or more" to errorText
    endif
    return using errorText

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Gets the hidden ID of the combobox item to do a search with partyID later
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
GetComboboxItemID function
pCombobox               combobox        ^
    entry
selectedComboboxItem    form            1
partyID                 form            1

    pCombobox.GetCurSel giving selectedComboboxItem
    pCombobox.GetItemData giving partyID using *Index=selectedComboboxItem
    return using partyID

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Obtain our hidden columns data to do a read later
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
gatherHiddenColData function
    entry
hiddenISAMData          dim             Presidents_IKey_Size
lvRow                   form            10
nextSelectedItem        form            "2"        

    MainWinPresidentsLV.GetNextItem giving lvRow using *Flags=nextSelectedItem:
                                                       *Start=(-1)
    MainWinPresidentsLV.GetItemText giving hiddenISAMData using *Index=lvRow
                                                        
    chop hiddenISAMData
    return using hiddenISAMData
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Populate the edit modal with our hidden data
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
populateEditModal function
presidents_Rec          record like     Presidents_Record
presidentPartyName      dim             30   
    entry
workVar                 dim             20
    
    //we have the record, now update the boxes
    //use the update keyword with the info from the input boxes from user
    setprop editWinLastNameET,Text=presidents_Rec.lastName
    setprop editWinFirstNameET,Text=presidents_Rec.firstName
    setprop editWinTermStartEDT,Text=presidents_Rec.termStartDate
    
    // If endDate is empty set the edit modal to be unchecked. 
    if (presidents_Rec.termEndDate="")
        setprop editWinTermEndEDT, checked=0    
    else
        setprop editWinTermEndEDT,Text=presidents_Rec.termEndDate
    endif
    setprop editWinVicePresET,Text=presidents_Rec.vicePresidents
    editWinPartyCB.SelectString using *String=presidentPartyName:
                                          *Index=0

    setprop     editWin,visible=1
    clear presidents_Rec
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Do a read from our hidden info, find the record.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
FindRecordDblClickedEdit function
presidents_Rec          record likeptr  Presidents_Record
presidentPartyName      dim             ^  
    entry
hiddenISAMData          dim             Presidents_IKey_Size
errorText               dim             200

    call gatherHiddenColData giving hiddenISAMData
    read Presidents_IFile,hiddenISAMData; presidents_Rec, *LL

    call chopPresidentsRec using presidents_Rec

    if over
    move "There Was An Issue Finding That Record" to errorText
        call errorHandler using errorText
    endif
    
    call getPresidentpartyNameDescription giving presidentPartyName using presidents_Rec.partyID
    move presidentPartyName to presidents_Rec.partyID

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Add a new record 
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickMainWinAddBT function
    entry
    
    call clearModalForAddingRecord
    setprop editWin,visible=1
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Clears all inputs, and gets rid of selections to start fresh
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
clearModalForAddingRecord function
    entry
lvRow                   form            10
nextSelectedItem        form            "2"
deselectItem            form            "0"

    setprop editWinLastNameET,Text=""
    setprop editWinFirstNameET, Text=""
    setprop editWinTermStartEDT, Text=""
    setprop editWinTermEndEDT, Text=""
    setprop editWinVicePresET, Text=""
    setprop editWinLastNameET, Text=""
    editWinPartyCB.SetCurSel using *Index=0

    // Clears previous selections to make sure we dont grab  
    // previously selected record
    MainWinPresidentsLV.GetNextItem giving lvRow using *Flags=nextSelectedItem:
                                                       *Start=(-1)
    // Clears selection
    MainWinPresidentsLV.SetItemState using *Index=lvRow:
                                        *State=deselectItem:
                                        *Statemask=0x2
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// On click edit a record, calling our manageEditModal handler to finish the logic.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickMainWinEditBT function
    entry
errorText               dim             200
lvRow                   form            10
nextSelectedItem        form            "2"

    MainWinPresidentsLV.GetNextItem giving lvRow using *Flags=nextSelectedItem:
                                                   *Start=(-1)
    if (lvRow!=-1)
        call manageEditModal
    else
        move "Please Select A Record To Edit" to errorText
        call errorHandler using errorText
    endif

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// On click, grabs record if it exists, and then calls processDelete to handle our logic
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickMainWinDeleteBT function
    entry
errorText               dim             200
lvRow                   form            10
nextSelectedItem        form            "2"

    // Grabs selected item to process for deletion.
    MainWinPresidentsLV.GetNextItem giving lvRow using *Flags=nextSelectedItem:
                                                   *Start=(-1)
    // If a item is highlighted...
    if (lvRow!=-1)
        call deleteRecord
    else
        move "Please Select A Record To Delete" to errorText
        call errorHandler using errorText
    endif

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Performs all tasks needed for the edit modal, does a read to find the record double
// clicked on, then populates with that info
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
manageEditModal function
    entry
presidents_Rec          record like     Presidents_Record
presidentPartyName      dim             30

    // Using the hidden data, finds the record we are dealing with
    call FindRecordDblClickedEdit using presidents_Rec,presidentPartyName
    // Populate the edit modal with info
    call populateEditModal using presidents_Rec,presidentPartyName
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Has an error pop up with whatever text was included describing the error.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
errorHandler function
errorText               dim             200
    entry
result                  integer         1

    chop errorText
    alert caution,errorText,result

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Removes the selected item from the LV to delete
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
removeDeletedItemFromListView function
    entry
lvRow                   form            10
nextSelectedItem        form            "2"

    // Grabs previously selected item from LV, and deletes it from the LV.
    MainWinPresidentsLV.GetNextItem giving lvRow using *Flags=nextSelectedItem:
                                                   *Start=(-1)
    MainWinPresidentsLV.DeleteItem using *Index=lvRow

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Handles the save event of the modal. Handles everything from the read to find the record, to the saving of our 
// data, to the addition of it to the LV.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
processModalSave function
    entry
presidents_Rec          record like     Presidents_Record      // Record structure for president information
errorText               dim             200                    // Buffer for error messages
presidentPartyName      dim             30                     // Buffer for president party name
itemCount               form            4                      // Counter for the number of items in LV
emptyCheck              integer         1                      // Integer flag for empty check
addDataToList           form            "9"                    // Form identifier for adding data
hiddenISAMData          dim             Presidents_IKey_Size   // Buffer for hidden ISAM key data
focusAndSelected        form            "3"                    // Form identifier for focus and selection

    // Grabs the hidden col data for a read to make sure we have the right item.
    // Also makes it so we know whether to add or edit the record 
    call gatherHiddenColData giving hiddenISAMData
    // Grabs the edit form data so we can update our record.
    call gatherEditFormData giving errorText using presidents_Rec

    // If there are errors...
    if (errorText!="")
        call errorHandler using errorText
        return
    endif

    // If there is no hiddenData detected then add...
    if (hiddenISAMData="")
        call saveRecord using presidents_Rec
        move 1 to addDataToList
    // If there is data, then update...
    else
        call gatherHiddenColData giving hiddenISAMData
        call updateRecord using presidents_Rec,hiddenISAMData
    endif

    // Grabs the description from the partyID, this will make it so we can insert the description
    // into the LV
    call getPresidentpartyNameDescription giving presidentPartyName using presidents_Rec.partyID
    // Displays edited or added record on LV
    call DisplayPresidentsInfoIntoListView giving itemCount using presidents_Rec,presidentPartyName,addDataToList

    //After editing or adding, sets focus and selection on said item.
    MainWinPresidentsLV.SetItemState using *Index=itemCount:
                                        *State=focusAndSelected:
                                        *Statemask=0x3
    MainWinPresidentsLV.EnsureVisible using *Index=itemCount:
                                        *Partial=0
    // Shows how many records we have on our main page.
    call recordCountSetter using itemCount
    call closeEditWin

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
processMainWindowSearch function
    entry
presAKeys               record like     PresidentsAKeys       
temp                    dim             100                   
lengthCheckForAAM       integer         4                     

    MainWinPresidentsLV.DeleteAllItems
    // Takes each prop, and gets it ready for AAM searches
    call ConvertSearchParamsToAKeys using presAKeys
    
    // If not a single param is filled, just fetch all presidents again
    pack temp from presAKeys.firstName,presAKeys.lastName,presAKeys.termStartDate:
                   presAKeys.termEndDate,presAKeys.vicePresidents,presAKeys.partyID
    chop temp
    movelptr temp to lengthCheckForAAM
    // If lp for temp is below 6 throw an error
    // the strict if() makes it so it can still search with no params
    if (lengthCheckForAAM<6 && lengthCheckForAAM!=0 && presAkeys.partyID="") 
        call errorCheckForAAMLength using temp,lengthCheckForAAM
        return
    endif

    // If no parameters...
    if (temp = "" ) 
        call LoadPresidentsInfoIntoListViewISAM 
    // If ANY parameters...
    else
        call LoadPresidentsInListViewAAM using presAKeys
    endif

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Checks to make sure our prop value is three or more chars, AAM searches dont support less.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
errorCheckForAAMLength function
temp                    dim             100
lengthCheckForAAM       integer         4
    entry

    call errorHandler using "Please Search With 3 Characters Or More."
    call LoadPresidentsInfoIntoListViewISAM  

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Goes through an array and depending on it being a zero or a 1, it sorts the column clicked from the LV
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
sortLv function
    entry
dateMaskSort            init            "yyyy-mm-dd"
dateAscSort             form            "5"
dateDescSort            form            "6"
alphaAsc                form            "1"
alphaDesc               form            "2"
colBtnIndex             form            2

    // Using a global array, checks on state of column to see which way it needs to be sorted
    // Asc or descending
    eventinfo 0, result=colBtnIndex
    switch colBtnIndex
        case 1
            if (#firstNameTrack)
                MainWinPresidentsLV.SortColumn using *Column=1:
                                                 *Type=alphaDesc
                decr #firstNameTrack
            else
                MainWinPresidentsLV.SortColumn using *Column=1:
                                                 *Type=alphaAsc
                incr #firstNameTrack
            endif

        case 2
            if (#lastNameTrack)
                MainWinPresidentsLV.SortColumn using *Column=2:
                                                 *Type=alphaDesc
                decr #lastNameTrack
            else
                MainWinPresidentsLV.SortColumn using *Column=2:
                                                 *Type=alphaAsc
                incr #lastNameTrack
            endif

        case 3
            if (#termStartTrack)
                MainWinPresidentsLV.SortColumn using *Column=3:
                                                 *Type=dateDescSort:
                                                 *Mask=dateMaskSort
                decr #termStartTrack
            else 
                MainWinPresidentsLV.SortColumn using *Column=3:
                                                 *Type=dateAscSort:
                                                 *Mask=dateMaskSort
                incr #termStartTrack
            endif

        case 4 
            if (#termEndTrack)
                MainWinPresidentsLV.SortColumn using *Column=4:
                                                 *Type=dateDescSort:
                                                 *Mask=dateMaskSort
                decr #termEndTrack
            else
                MainWinPresidentsLV.SortColumn using *Column=4:
                                                 *Type=dateAscSort:
                                                 *Mask=dateMaskSort
                incr #termEndTrack
            endif

        case 5
            if (#vicePTrack)
                MainWinPresidentsLV.SortColumn using *Column=5:
                                                 *Type=alphaDesc
                decr #vicePTrack
            else 
                MainWinPresidentsLV.SortColumn using *Column=5:
                                                 *Type=alphaAsc
                incr #vicePTrack
            endif

        case 6 
            if (#partyTrack)
                MainWinPresidentsLV.SortColumn using *Column=6:
                                                 *Type=alphaDesc
                decr #partyTrack
            else
                MainWinPresidentsLV.SortColumn using *Column=6:
                                                 *Type=alphaAsc
                incr #partyTrack
            endif
    endswitch

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Closes the edit modal
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
closeEditWin function
    entry

    setprop     editWin,visible=0

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// End of .pls functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Start of .plf functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// On click of the top of the column of the LV, it sorts the data depending on which column is clicked
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onColClickMainWinLV function
    entry

    call sortLv

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// On click of delete button, goes through the entire process of deleting the selected record.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickEditWinDeleteBT function
    entry

    call deleteRecord

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Obtain new data, update with it.    
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickEditModalSave function
    entry
    
    call processModalSave

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Resets our mainWin entirely so its as if you start fresh
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickMainWinResetBT function
    entry

    MainWinPresidentsLV.DeleteAllItems 
    setprop mainWinLastNameET, Text=""
    setprop mainWinFirstNameET, Text=""
    setprop mainWinTermStartEDT, checked=0
    setprop mainWinTermEndEDT, checked=0
    setprop mainWinVicePresET, Text=""
    mainWinPartyCB.SetCurSel using *Index=0

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// On click of search, looks up presidents with/without params   
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onClickMainWinSearchBT function
    entry

    call processMainWindowSearch

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// On click of a button from our toolbar, it checks to see which button.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onItemClickMainWinTB function
    entry
btnIndex                form            2

    eventinfo 0,result=btnIndex
    switch btnIndex
        case 1
            // Add button
            call onClickMainWinAddBT
        case 2
            // Edit button
            call onClickMainWinEditBT
        case 3
            // Delete button
            call onClickMainWinDeleteBT
        case 4 
            // Search button
            call onClickMainWinSearchBT
        case 5
            // Reset button
            call onClickMainWinResetBT
    endswitch

    return

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Close program on X click
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onCloseMainWin function
    entry
    stop

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Edit modal pops up from double-click
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onDblClickMainWinLV function
    entry

    call manageEditModal

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// When the X button is hit, closes the modal.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
onCloseEditWin function
    entry

    call closeEditWin

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Close Edit Modal through cancel button
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////    
onClickEditWinCancelBT function
    entry

    call closeEditWin
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//End of .plf functions
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////