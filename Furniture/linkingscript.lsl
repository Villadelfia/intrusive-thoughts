integer getNumberOfPrims()
{
    if (llGetObjectPrimCount(llGetKey()) == 0 ) return llGetNumberOfPrims();
    return llGetObjectPrimCount(llGetKey());
}

default
{
    state_entry()
    {
        if(getNumberOfPrims() != 1) llRegionSay(-1443216791, llGetLinkKey(LINK_ROOT));
        else                       llRegionSay(-1443216791, llGetKey());
        llRemoveInventory(llGetScriptName());
    }
}