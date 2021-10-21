#include <IT/globals.lsl>
key storedobject = NULL_KEY;
key storedavatar = NULL_KEY;
key capturing = NULL_KEY;
string storedname = "";
key linkTarget = NULL_KEY;
integer handle = -1;
vector startPos = ZERO_VECTOR;
vector endPos   = ZERO_VECTOR;
rotation startRot = ZERO_ROTATION;
rotation endRot   = ZERO_ROTATION;
vector startScale = <1.0, 1.0, 1.0>;
vector endScale   = ZERO_VECTOR;
float startAlpha = 1.0;
float endAlpha   = 0.0;
float tVar = 0.0;
string myName = "";

float fCos(float x, float y, float t) 
{
    float F = (1-llCos(t*PI))/2;
    return (x*(1-F))+(y*F);
}

vector vCos(vector x, vector y, float t) 
{
    float F = (1-llCos(t*PI))/2;
    return (x*(1-F))+(y*F);
}

rotation rCos(rotation x, rotation y, float t)
{
    float f = (1-llCos(t*PI))/2;
    float ang = llAngleBetween(x, y);
    if(ang > PI) ang -= TWO_PI;
    return x * llAxisAngle2Rot(llRot2Axis(y/x)*x, ang*f);
}

whichperson()
{
    storedavatar = NULL_KEY;
    if(storedobject == NULL_KEY) return;

    list agents = llGetAgentList(AGENT_LIST_REGION, []);
    integer n = llGetListLength(agents);
    while(~--n)
    {
        key agent = llList2Key(agents, n);
        if(llList2Key(llGetObjectDetails(agent, [OBJECT_ROOT]), 0) == storedobject)
        {
            storedavatar = agent;
            return;
        }
    }

    // If we get here, something has gone horribly wrong.
    llRegionSayTo(storedobject, MANTRA_CHANNEL, "unsit");
    llResetScript();
}

saytoobject(string n, string m)
{
    string old = llGetObjectName();
    llSetObjectName(n);
    llRegionSayTo(storedavatar, GAZE_ECHO_CHANNEL, m);
    llSetObjectName(old);
}

default
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        if(llGetLinkNumber() != 0)
        {
            state running;
            return;
        }
        llOwnerSay("Welcome to your " + llGetObjectName() + ".\n\nFirst, I need to link up with another object. Please rename the object you want to link me to what you want me to be, and set up the object description as per the included manual, then drop the script I am giving you right now into that object and follow the instructions.");
        llGiveInventory(llGetOwner(), "IT Furniture Linking Script");
        handle = llListen(-1443216791, "", NULL_KEY, "");
        llPreloadSound("dec9fb53-0fef-29ae-a21d-b3047525d312");
    }

    listen(integer channel, string name, key id, string message)
    {
        if(llGetOwner() != llGetOwnerKey(id)) return;
        llListenRemove(handle);
        handle = -1;
        linkTarget = (key)message;
        llOwnerSay("I am linking to " + llList2String(llGetObjectDetails(linkTarget, [OBJECT_NAME]), 0) + ". Please grant me the linking permission to complete setup.");
        llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
    }

    run_time_permissions(integer perm) 
    {
        if(perm & PERMISSION_CHANGE_LINKS) 
        {
            list     info = llGetObjectDetails(linkTarget, [OBJECT_POS, OBJECT_ROT, OBJECT_NAME, OBJECT_DESC]) + llGetBoundingBox(linkTarget);
            vector   pos  = llList2Vector(info, 0);
            rotation rot  = llList2Rot(info, 1);
            myName = llList2String(info, 2);
            vector   c1   = llList2Vector(info, 4) * rot + pos;
            vector   c2   = llList2Vector(info, 5) * rot + pos;
            vector   size = llList2Vector(info, 5) - llList2Vector(info, 4);

            startPos = llGetPos();
            endPos   = (c1 + c2) * 0.5;

            startRot = llGetRot();
            endRot   = rot;

            startScale = llGetScale();
            endScale   = size;

            startAlpha = 1.0;
            endAlpha   = 0.1;

            tVar = 0.0;

            llSetObjectDesc(llList2String(info, 3));
            llSetTimerEvent(0.05);
        }
        else
        {
            llOwnerSay("You must grant the linking permission to continue.");
            llResetScript();
        }
    }

    timer()
    {
        if(tVar <= 1.0)
        {
            tVar += 0.025;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_ROTATION, rCos(startRot, endRot, tVar),
                                                     PRIM_SIZE,     vCos(startScale, endScale, tVar),
                                                     PRIM_COLOR,    ALL_SIDES, <0.784, 0.094, 0.094>, fCos(startAlpha, endAlpha, tVar)]);
            llSetRegionPos(vCos(startPos, endPos, tVar));
        }
        else if(tVar <= 2.0)
        {
            tVar += 0.2;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, fCos(0.0, 0.2, tVar-1.0)]);
        }
        else if(tVar <= 2.5)
        {
            tVar += 0.5;
            llPlaySound("dec9fb53-0fef-29ae-a21d-b3047525d312", 1.0);
        }
        else if(tVar <= 3.5)
        {
            tVar += 0.2;
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_GLOW, ALL_SIDES, fCos(0.2, 0.0, tVar-2.5)]);
        }
        else
        {
            llSetTimerEvent(0.0);
            llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE,    ALL_SIDES, TEXTURE_TRANSPARENT, <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0,
                                                     PRIM_COLOR,      ALL_SIDES, <1.0, 1.0, 1.0>, 1.0,
                                                     PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_MASK, 255,
                                                     PRIM_GLOW,       ALL_SIDES, 0.0]);
            llCreateLink(linkTarget, TRUE);
            llSetObjectName(myName);
            llSetStatus(STATUS_PHANTOM, TRUE);
            llOwnerSay("Alright, I'm good to go. You can now store objects in me via the IT Master HUD.");
            state running;
        }
    }
}

state running
{
    state_entry()
    {
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(GAZE_CHAT_CHANNEL, "", NULL_KEY, "");
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == MANTRA_CHANNEL)
        {
            // The IT controller is asking if we have anything stored.
            if(m == "furniture")
            {
                if(storedobject == NULL_KEY) llRegionSayTo(id, MANTRA_CHANNEL, "furniture 0");
                else                         llRegionSayTo(id, MANTRA_CHANNEL, "furniture 1");
            }

            // We've been by the IT controller that we have to give up whatever we are storing.
            else if(startswith(m, "puton"))
            {
                if(storedobject == NULL_KEY) return;
                llRegionSayTo(storedobject, MANTRA_CHANNEL, "puton " + (string)llGetOwnerKey(id) + "|||" + storedname);
                storedobject = NULL_KEY;
                llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES);
                llSetTimerEvent(0.0);
            }

            // We've been told by the IT controller that whatever it is storing is now ours.
            else if(startswith(m, "putdown"))
            {
                // If we already had an object, we do an exchange.
                if(storedobject != NULL_KEY) llRegionSayTo(storedobject, MANTRA_CHANNEL, "puton " + (string)llGetOwnerKey(id) + "|||" + storedname);

                // We store the object.
                list params = llParseString2List(llDeleteSubString(m, 0, llStringLength("putdown")), ["|||"], []);
                storedobject = (key)llList2String(params, 0);
                storedname = llList2String(params, 1);
                whichperson();

                // Let the object know to follow us now.
                llRegionSayTo(storedobject, MANTRA_CHANNEL, "putdown " + (string)llGetKey() + "|||" + llGetObjectName());
                llRegionSayTo(id, MANTRA_CHANNEL, "putdown");
                llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
                llSetTimerEvent(2.5);
            }

            // We've been told by the IT controller to capture someone.
            else if(startswith(m, "capture"))
            {
                // If we have an object, refuse.
                if(storedobject != NULL_KEY) return;

                // If we don't have a ball, refuse.
                if(llGetInventoryType("ball") != INVENTORY_OBJECT) return;

                // Set the uuid of who to capture.
                capturing = (key)llDeleteSubString(m, 0, llStringLength("putdown"));

                // Then do it.
                integer option = 4 | 1;
                if(contains(llGetObjectDesc(), "invis")) option = 4 | 2;
                llRezAtRoot("ball", llGetPos(), ZERO_VECTOR, ZERO_ROTATION, option);
            }
        }
        else if(c == GAZE_CHAT_CHANNEL)
        {
            // Don't bother if we have no object.
            if(storedobject == NULL_KEY) return;

            // First we check if the message would already be allowed...
            if(llToLower(llStringTrim(m, STRING_TRIM)) != "/me" && startswith(m, "/me") == TRUE && contains(m, "\"") == FALSE) return;

            // If it's the right avatar, we say it.
            if(storedavatar == id) llSay(0, m);
        }
    }

    object_rez(key id)
    {
        if(llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0) != "ball") return;
        storedobject = id;
        storedavatar = capturing;
        storedname = llGetObjectName();
        llRegionSayTo(id, MANTRA_CHANNEL, "sit " + (string)capturing + "|||" + llGetObjectName() + "|||NULL");
        llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);
        llSay(0, "A magical force begins acting on the body of " + llGetDisplayName(capturing) + " as they find themselves being transformed into the form of a " + llGetObjectName() + ".");
        llSetTimerEvent(15.0);
    }

    timer()
    {
        if(llGetObjectDetails(storedobject, [OBJECT_POS]) == []) llResetScript();
        llSetTimerEvent(2.5);
    }
}