#include <IT/globals.lsl>
float fillfactor = 0.25;

float finterp(float x, float y, float t) 
{
    return x*(1-t) + y*t;
}

calculateFill()
{
    if(fillfactor < 0.0) fillfactor = 0.0;
    if(fillfactor > 1.0) fillfactor = 1.0;
    vector rootsize = llList2Vector(llGetLinkPrimitiveParams(0, [PRIM_SIZE]), 0);
    vector thissize = llList2Vector(llGetLinkPrimitiveParams(LINK_THIS, [PRIM_SIZE]), 0);
    float min = -(rootsize.z/2.0);
    float max = 0.0;
    float zvalue = finterp(min, max, fillfactor);
    float zsize = finterp(max, rootsize.z, fillfactor);
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
        llSetTextureAnim(ANIM_ON | PING_PONG | SCALE | SMOOTH | LOOP, 0, 0, 0, 0.975, .05, 0.05);
        llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, 1, 1, 1, 1.0, 0, 0.1);
        llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, 2, 1, 1, 1.0, 0, 0.2);
        llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, 3, 1, 1, 1.0, 0, 0.2);
        llSetTextureAnim(ANIM_ON | SMOOTH | LOOP, 4, 1, 1, 1.0, 0, 0.1);
        llLoopSound("38510ac5-5338-ec76-1a6c-c2115538aa8d", 0.5);
        calculateFill();
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == API_FILL_FACTOR)
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