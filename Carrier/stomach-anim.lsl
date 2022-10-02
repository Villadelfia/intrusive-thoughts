#include <IT/globals.lsl>
float curvol = 0.5;

float getVolume()
{
    float vol = 0.5;
    integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
    while(~--n)
    {
        string nm = llGetInventoryName(INVENTORY_NOTECARD, n);
        if(startswith(nm, "~volume")) vol = (float)llList2String(llParseString2List(nm, ["="], []), 1);
    }
    return vol;
}

playSound()
{
    curvol = getVolume();
    llStopSound();
    if(llGetInventoryName(INVENTORY_SOUND, 0) == "") llLoopSound("5f6b61f1-d55e-236f-8173-a4a25695f26d", curvol);
    else                                             llLoopSound(llGetInventoryName(INVENTORY_SOUND, 0), curvol);
}

default
{
    state_entry()
    {
        playSound();
    }

    timer()
    {
        if(curvol != getVolume()) playSound();
    }

    on_rez(integer start_param)
    {
        playSound();
        llSetTimerEvent(5.0);
    }
}
