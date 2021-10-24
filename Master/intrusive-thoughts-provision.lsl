#include <IT/globals.lsl>
key lastparcel = NULL_KEY;
key provisiontarget = NULL_KEY;
string provisionname = "";
string provisiondesc = "";
integer provisionstate = 0;
string await = "";

integer canrez(vector pos)
{
    integer flags = llGetParcelFlags(pos);
    if(flags & PARCEL_FLAG_ALLOW_CREATE_OBJECTS) return TRUE;
    list details = llGetParcelDetails(pos, [PARCEL_DETAILS_OWNER, PARCEL_DETAILS_GROUP]);
    if(llList2Key(details, 0) == llGetOwner()) return TRUE;
    return(flags & PARCEL_FLAG_ALLOW_CREATE_GROUP_OBJECTS) && llSameGroup(llList2Key(details, 1));
}

provision()
{
    if(provisionstate == 0)
    {
        // First, we try to check if they happen to be wearing a possession object.
        llRegionSayTo(provisiontarget, MANTRA_CHANNEL, "objping");
        llSetTimerEvent(5.0);
    }
    else if(provisionstate == 1)
    {
        // The victim did not have a possession object. Let's get a restriction going to try and provision them.
        llRegionSayTo(provisiontarget, RLVRC, "itprovision," + (string)provisiontarget + ",@notify:" + (string)PROV_CHANNEL + ";inv_offer=add|@sit=n");
        await = "itprovision";
        llSetTimerEvent(30.0);
    }
    else if(provisionstate == 2)
    {
        // Let's check if they have the folder already.
        llRegionSayTo(provisiontarget, RLVRC, "ifprovhave," + (string)provisiontarget + ",@getinvworn:~itposs/" + VERSION_FULL + "=" + (string)PROV_CHANNEL);
        llSetTimerEvent(30.0);
    }
    else if(provisionstate == 3)
    {
        // Give the folder...
        llGiveInventoryList(provisiontarget, "#RLV/~itposs/" + VERSION_FULL, ["Intrusive Thoughts Possessor"]);
        llSetTimerEvent(30.0);
    }
    else if(provisionstate == 4)
    {
        // Attach it.
        llRegionSayTo(provisiontarget, RLVRC, "itprovattach," + (string)provisiontarget + ",@attachover:~itposs/" + VERSION_FULL + "=force|@sit=y|!release");
        llSetTimerEvent(30.0);
    }
}

default
{
    state_entry()
    {
        llListen(RLVRC, "", NULL_KEY, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(PROV_CHANNEL, "", NULL_KEY, "");
    }

    attach(key id)
    {
        if(id == NULL_KEY) llSetTimerEvent(0.0);
    }

    listen(integer c, string n, key id, string m)
    {
        if(c == RLVRC)
        {
            if(llGetOwnerKey(id) != provisiontarget) return;
            list params = llParseString2List(m, [","], []);
            if(llGetListLength(params) != 4) return;
            if((key)llList2String(params, 1) != llGetKey()) return;
            integer accept = llList2String(params, 3) == "ok";
            string identifier = llList2String(params, 0);
            string command = llList2String(params, 2);

            if(identifier == await)
            {
                if(await == "itprovision")
                {
                    llSetTimerEvent(0.0);
                    if(accept == TRUE)
                    {
                        // We have a notification going, let's check if they have the object...
                        provisionstate = 2;
                        provision();
                    }
                    else
                    {
                        // Fail.
                        llRegionSayTo(provisiontarget, RLVRC, "release," + (string)provisiontarget + ",!release");
                        llMessageLinked(LINK_SET, M_API_PROVISION_RESPONSE, (string)provisiontarget + "|||" + provisionname + "|||" + provisiondesc, NULL_KEY);
                        provisiontarget = NULL_KEY;
                    }
                }
                await = "";
            }
        }
        else if(c == MANTRA_CHANNEL)
        {
            if(llGetOwnerKey(id) != provisiontarget) return;

            if(m == "objready " + (string)provisiontarget)
            {
                llSetTimerEvent(0.0);
                llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
                llMessageLinked(LINK_SET, M_API_PROVISION_RESPONSE, (string)provisiontarget + "|||" + provisionname + "|||" + provisiondesc, id);
                provisiontarget = NULL_KEY;
            }
            else if(m == "objbusy " + (string)provisiontarget)
            {
                // Fail.
                llSetTimerEvent(0.0);
                llRegionSayTo(provisiontarget, RLVRC, "release," + (string)provisiontarget + ",!release");
                llMessageLinked(LINK_SET, M_API_PROVISION_RESPONSE, (string)provisiontarget + "|||" + provisionname + "|||" + provisiondesc, NULL_KEY);
                provisiontarget = NULL_KEY;
            }
        }
        else if(c == PROV_CHANNEL)
        {
            if(llGetOwnerKey(id) != provisiontarget) return;

            if(provisionstate == 2)
            {
                if(contains(m, "/notify")) return;

                // Check for response.
                llSetTimerEvent(0.0);
                if(m == "")
                {
                    provisionstate = 3;
                    provision();
                }
                else
                {
                    provisionstate = 4;
                    provision();
                }
            }
            else if(provisionstate == 3)
            {
                if(contains(m, "/accepted_in_rlv"))
                {
                    provisionstate = 4;
                    provision();
                }
                else
                {
                    // Failed.
                    llSetTimerEvent(0.0);
                    llRegionSayTo(provisiontarget, RLVRC, "release," + (string)provisiontarget + ",!release");
                    llMessageLinked(LINK_SET, M_API_PROVISION_RESPONSE, (string)provisiontarget + "|||" + provisionname + "|||" + provisiondesc, NULL_KEY);
                    provisiontarget = NULL_KEY;
                }
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_PROVISION_REQUEST)
        {
            provisiontarget = id;
            provisionstate = 0;
            list params = llParseString2List(str, ["|||"], []);
            provisionname = llList2String(params, 0);
            provisiondesc = llList2String(params, 1);
            vector pos = llGetPos();
            key parcelid = llList2Key(llGetParcelDetails(pos, [PARCEL_DETAILS_ID]), 0);

            // Check if we can rez.
            if(!canrez(pos))
            {
                if(parcelid != lastparcel)
                {
                    llOwnerSay("Cannot rez on this parcel. Trying to set land group. If that fails I will perform a no-rez capture.");
                    llOwnerSay("@setgroup:" + (string)llList2Key(llGetParcelDetails(pos, [PARCEL_DETAILS_GROUP]), 0) + "=force");
                    llSleep(2.5);
                }
            }
            lastparcel = parcelid;

            if(!canrez(pos)) 
            {
                // If not, try no-rez objectification.
                provision();
            }
            else
            {
                // If we can, throw control back to the mother script.
                llRezAtRoot("ball", pos - <0.0, 0.0, 3.0>, ZERO_VECTOR, ZERO_ROTATION, (integer)llList2String(params, 2));
            }
        }
    }

    timer()
    {
        llSetTimerEvent(0.0);
        if(provisionstate == 0)
        {
            // Didn't get a response. Now attempting to get a notify going.
            provisionstate = 1;
            provision();
        }
        else
        {
            // Failed.
            llRegionSayTo(provisiontarget, RLVRC, "release," + (string)provisiontarget + ",!release");
            llMessageLinked(LINK_SET, M_API_PROVISION_RESPONSE, (string)provisiontarget + "|||" + provisionname + "|||" + provisiondesc, NULL_KEY);
            provisiontarget = NULL_KEY;
        }
    }
}