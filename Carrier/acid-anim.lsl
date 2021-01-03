#include <IT/globals.lsl>
float fillfactor = 0.25;
integer volumelink = 1;

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
        llLoopSound("38510ac5-5338-ec76-1a6c-c2115538aa8d", 0.5);
        calculateFill();
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
}