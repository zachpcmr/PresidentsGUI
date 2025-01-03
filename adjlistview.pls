//While you are waiting on feedback on your program:

//I want you to take a look at all of your listview logic. Listviews tend to be pretty generic objects - the columns and the data are variable, but the basic operations are the same: add an item, delete an item, highlight an item, etc. With that thought in mind, I'd like you to create a new program called adjlistview.pls. Here's some starter code:

// adjlistview.pls - listview helper library
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// a test function you can use to make sure that the functions you write work as expected
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
unittest lfunction
    entry
testListview            listview
mainWin                 mainwindow
itemTextAll             dim         32768

r form 2

    create mainWin;testListview=1:24:1:80,fullrow=1,gridline=1
    activate testListview

    // set up some dummy data in the listview
    testListview.InsertColumnEx using *Index=0,*Text="Column 0",*Width=100
    testListview.InsertColumnEx using *Index=1,*Text="Column 0",*Width=100
    testListview.InsertColumnEx using *Index=2,*Text="Column 0",*Width=100
    testListview.InsertColumnEx using *Index=3,*Text="Column 0",*Width=100
    for r from 0 to 10
        testListview.InsertItemEx using *Index=r,*Text="Row",*Subitem1="Subitem 1",*Subitem2="Subitem 2",*Subitem3="Subitem 3"
    repeat 

    // make sure the objects are visible
    winshow

    // TODO: call functions for the generic listview processes - example given
    
    call LvSelectItemByIndex using testListview,"3"
    call LvAddItemByItemCount using testListview,"Is","This","Working","?"
    call LvDeleteItemByGivenItemNumber using testListview,"2"
    //incorrect index on purpose. This is solely to test LvGetItemCountForErrorHandling
    call LvDeleteItemByGivenItemNumber using testListview,"20" 
    call LvEditItemByGivenItemNumber using testListview,"1","This","Row","Is","Edited"
    call LvGetItemTextAll giving itemTextAll using testListview,"1"

    call LvDeleteAllItems using testListview
    waitevent
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// example function that selects a row from a listview, make sure it's visible, and returns 1 on success
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvSelectItemByIndex lfunction
pListview                           listview        ^
lvIndexToHighlight                  form            3
    entry
result                              integer         1
LvIndexInRange                      integer         1
    
    // Error handling...
    call LvGetItemCountForErrorHandling giving LvIndexInRange using pListview,lvIndexToHighlight
    return using (0) if (LvIndexInRange=0)

    // Sets Item to be selected and focused...
    pListview.SetItemState giving result using *Index=lvIndexToHighlight,*State=3,*StateMask=3
    return using (0) if (result = 0)

    // Forces screen to move to the item focused/selected
    pListview.EnsureVisible giving result using *Index=lvIndexToHighlight,*Partial=0
    return using (0) if (result = 0)

    return using (1)

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//add to LV
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvAddItemByItemCount function
pListview          listview      ^
colZero            dim           20
colOne             dim           20
colTwo             dim           20
colThree           dim           20
    entry
successCheck       form           1
itemCount          integer        4
LvIndexInRange     integer        1

    // Gives var needed...
    pListview.GetItemCount giving itemCount

    // Checks itemCount with error handling...
    call LvGetItemCountForErrorHandling giving LvIndexInRange using pListview,LvIndexInRange
    return using (0) if (LvIndexInRange=0)

    // Inserts all strings given column by column for the item 
    // From the given index...
    pListview.InsertItemEx giving successCheck using  *Text=colZero:
                                  *Index=itemCount:  
                                  *Subitem1=colOne:
                                  *Subitem2=colTwo:
                                  *Subitem3=colThree

    return using (0) if (successCheck="-1")

    return using (1)

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Delete an item from the given index from a Lv
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvDeleteItemByGivenItemNumber function
pListview              listview        ^
lvIndexToDelete        form            3
    entry
successCheck           form            1
LvIndexInRange         integer         1

    // Error handling...
    call LvGetItemCountForErrorHandling giving LvIndexInRange using pListview,lvIndexToDelete
    return using (0) if (LvIndexInRange=0)

    // Delete item from index given...
    pListview.DeleteItem using *Index=lvIndexToDelete
    return using (1)

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Edit an item from the given index from a Lv
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvEditItemByGivenItemNumber function
pListview              listview        ^
lvIndexToEdit          form            3
colZero                dim          1000
colOne                 dim          1000
colTwo                 dim          1000
colThree               dim          1000
    entry
successCheck           form            2
workString             dim         32768
LvIndexInRange         integer         1

    // Error handling...
    call LvGetItemCountForErrorHandling giving LvIndexInRange using pListview,lvIndexToEdit
    return using (0) if (LvIndexInRange=0)

    // Packs up vars in a comma delimited format...
    packkey workString from colZero,",",colOne,",",colTwo,",",colThree                
    chop workString

    // Sets each var seperated by commas into each col...
    pListview.SetItemTextAll giving successCheck using *Index=lvIndexToEdit:
                                                             *Text=workString:
                                                             *Options=0x20
    //TODO I dont know the error return for this one...
    return using (0) if (successCheck!="-1")
    return using (1)

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Delete all items on call // kind of silly since its one line.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvDeleteAllItems function
pListview              listview        ^
    entry
    
    pListview.DeleteAllItems

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//GetItemTextAll, returns each column text for an item in a comma delimited format
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvGetItemTextAll function
pListview              listview        ^
lvIndexToGetItemText   form            3
    entry
itemTextAll            dim         32768
LvIndexInRange         integer         1
    
    // Error handling...
    call LvGetItemCountForErrorHandling giving LvIndexInRange using pListview,lvIndexToGetItemText
    return using (0) if (LvIndexInRange=0)

    // Comma delimited format...
    pListview.GetItemTextAll giving itemTextAll using *Index=lvIndexToGetItemText

    // Deals with spaces...
    chop itemTextAll
    squeeze itemTextAll,itemTextAll

    // Return the comma delimited string with no spaces...
    // Each item represents each column, left to right...
    return using itemTextAll

    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Error handler to make sure what we item count we are using is within range. Returns 1 on an in range value
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
LvGetItemCountForErrorHandling function
pListview              listview        ^
lvIndex                form            3
    entry
itemCount              integer         4
negativeOne            const         "-1"

    // Get how many items in Lv...
    pListview.GetItemCount giving itemCount

    // If not valid...
    return using (0) if (itemCount<lvIndex)
    return using (0) if (negativeOne>lvIndex)

    return using (1)
    
    functionend
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
