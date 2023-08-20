#include <IT/globals.lsl>
float fillfactor = 0.25;
integer volumelink = 1;
float curvol = 0.5;

float finterp(float x, float y, float t)
{
    return x*(1-t) + y*t;
}

calculateFill()
{
    if(fillfactor < 0.0) fillfactor = 0.0;
    if(fillfactor > 1.0) fillfactor = 1.0;
    vector volumesize = llList2Vector(llGetLinkPrimitiveParams(volumelink, [PRIM_SIZE]), 0);
    vector volumepos = llList2Vector(llGetLinkPrimitiveParams(volumelink, [PRIM_POS_LOCAL]), 0);
    vector thissize = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_SIZE]), 0);
    float max = volumepos.z;
    float min = max-(volumesize.z/2.0);
    float zvalue = finterp(min, max, fillfactor);
    float zsize = finterp(0, volumesize.z, fillfactor);
    vector mylocalpos = llGetLocalPos();
    vector localpos = <mylocalpos.x, mylocalpos.y, zvalue>;
    thissize.z = zsize;
    if(thissize.z < 0.01) thissize.z = 0.01;
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_POS_LOCAL, localpos, PRIM_SIZE, thissize]);
}

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
    // Gurgling and liquid sound.
    curvol = getVolume();
    llStopSound();
    if(llGetInventoryName(INVENTORY_SOUND, 0) == "") llLoopSound("38510ac5-5338-ec76-1a6c-c2115538aa8d", curvol);
    else                                             llLoopSound(llGetInventoryName(INVENTORY_SOUND, 0), curvol);
}

default
{
    state_entry()
    {
        llSetTextureAnim(ANIM_ON | PING_PONG | SCALE | SMOOTH | LOOP, ALL_SIDES, 0, 0, 0.975, .05, 0.05);
        integer i = llGetNumberOfPrims();
        for (; i >= 0; --i)
        {
            if (llGetLinkName(i) == "volume")
            {
                volumelink = i;
                llOwnerSay("Volume link found at link number " + (string)i + ".");
            }
        }
        calculateFill();
        playSound();
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == X_API_FILL_FACTOR)
        {
            fillfactor = (float)str;
            calculateFill();
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_SCALE) calculateFill();
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
