#include <IT/globals.lsl>
key rezzer;
key firstavatar;
key httpid;
integer volumelink = -1;
string prefix = "??";
integer imRestrict = 0;
integer speechRestrict = 0;
integer dazeRestrict = 1;
integer cameraRestrict = 1;
integer inventoryRestrict = 1;
integer worldRestrict = 1;

sitterMenu()
{
    llSetObjectName("");
    llRegionSayTo(firstavatar, 0, "Object Options Menu:");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "IM Options:");
    if(imRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                      llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(imRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "im1 Cannot open IM sessions.]");
    else if(imRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Cannot open IM sessions.");
    else                      llRegionSayTo(firstavatar, 0, " - Cannot open IM sessions.");
    if(imRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "im2 Cannot send IMs.]");
    else if(imRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Cannot send IMs.");
    else                      llRegionSayTo(firstavatar, 0, " - Cannot send IMs.");
    if(imRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "im3 Cannot send or receive IMs.]");
    else if(imRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Cannot send or receive IMs.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Speech Options:");
    if(speechRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(speechRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp1 No longer capable of speech.]");
    else if(speechRestrict == 1)  llRegionSayTo(firstavatar, 0, " * No longer capable of speech.");
    else                          llRegionSayTo(firstavatar, 0, " - No longer capable of speech.");
    if(speechRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp2 No longer capable of speech or emoting.]");
    else if(speechRestrict == 3)  llRegionSayTo(firstavatar, 0, " * No longer capable of speech or emoting.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Daze Options:");
    if(dazeRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                        llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(dazeRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "da1 Location and people hidden.]");
    else if(dazeRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Location and people hidden.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Camera Options:");
    if(cameraRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "ca0 No restrictions.]");
    if(cameraRestrict == 1)       llRegionSayTo(firstavatar, 0, " * Camera restricted to inside stomach.");
    else                          llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "ca1 Camera restricted to inside stomach.]");
    if(cameraRestrict == 2)       llRegionSayTo(firstavatar, 0, " * Camera restricted to predator.");
    else                          llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "ca2 Camera restricted to predator.]");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Inventory Options:");
    if(inventoryRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                             llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(inventoryRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "in1 No inventory.]");
    else if(inventoryRestrict == 1)  llRegionSayTo(firstavatar, 0, " * No inventory.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "World Options:");
    if(worldRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                         llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(worldRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "wo1 No world interaction.]");
    else if(worldRestrict == 1)  llRegionSayTo(firstavatar, 0, " * No world interaction.");
    llSetObjectName("carrier");
}

ownerMenu()
{
    llSetObjectName("");
    llOwnerSay("Object Options Menu:");
    llOwnerSay(" ");
    llOwnerSay("IM Options:");
    if(imRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im0 No restrictions.]");
    else                 llOwnerSay(" * No restrictions.");
    if(imRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im1 Cannot open IM sessions.]");
    else                 llOwnerSay(" * Cannot open IM sessions.");
    if(imRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im2 Cannot send IMs.]");
    else                 llOwnerSay(" * Cannot send IMs.");
    if(imRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "im3 Cannot send or receive IMs.]");
    else                 llOwnerSay(" * Cannot send or receive IMs.");
    llOwnerSay(" ");
    llOwnerSay("Speech Options:");
    if(speechRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp0 No restrictions.]");
    else                     llOwnerSay(" * No restrictions.");
    if(speechRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp1 No longer capable of speech.]");
    else                     llOwnerSay(" * No longer capable of speech.");
    if(speechRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp2 No longer capable of speech or emoting.]");
    else                     llOwnerSay(" * No longer capable of speech or emoting.");
    llOwnerSay(" ");
    llOwnerSay("Dazing Options:");
    if(dazeRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "da0 No restrictions.]");
    else                   llOwnerSay(" * No restrictions.");
    if(dazeRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "da1 Location and people hidden.]");
    else                   llOwnerSay(" * Location and people hidden.");
    llOwnerSay(" ");
    llOwnerSay("Camera Options:");
    if(cameraRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "ca0 No restrictions.]");
    else                     llOwnerSay(" * No restrictions.");
    if(cameraRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "ca1 Camera restricted to inside stomach.]");
    else                     llOwnerSay(" * Camera restricted to inside stomach.");
    if(cameraRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "ca2 Camera restricted to predator.]");
    else                     llOwnerSay(" * Camera restricted to predator.");
    llOwnerSay(" ");
    llOwnerSay("Inventory Options:");
    if(inventoryRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "in0 No restrictions.]");
    else                        llOwnerSay(" * No restrictions.");
    if(inventoryRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "in1 No inventory.]");
    else                        llOwnerSay(" * No inventory.");
    llOwnerSay(" ");
    llOwnerSay("World Options:");
    if(worldRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "wo0 No restrictions.]");
    else                    llOwnerSay(" * No restrictions.");
    if(worldRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "wo1 No world interaction.]");
    else                    llOwnerSay(" * No world interaction.");
    llSetObjectName("carrier");
}

default
{
    state_entry()
    {
        rezzer = llGetOwner();
        integer i = llGetNumberOfPrims();
        for (; i >= 0; --i)
        {
            if (llGetLinkName(i) == "volume")
            {
                volumelink = i;
                llOwnerSay("Volume link found at link number " + (string)i + ".");
            }
        }
    }

    on_rez(integer start_param)
    {
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
    }

    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            if(llAvatarOnLinkSitTarget(volumelink) != NULL_KEY)
            {
                prefix = llToLower(llGetSubString(llGetUsername(llAvatarOnLinkSitTarget(volumelink)), 0, 1));
                firstavatar = llAvatarOnLinkSitTarget(volumelink);
                httpid = llHTTPRequest("http://villadelfia.org:3000/itvore/l/" + llEscapeURL((string)rezzer + "-" + (string)llAvatarOnLinkSitTarget(volumelink)), [], "");
            }
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_GIVE_MENU)
        {
            if(id == llGetOwner()) ownerMenu();
            else                   sitterMenu();
        }
        else if(num == X_API_SETTINGS_SAVE)
        {
            list settings = llParseString2List(str, [","], []);
            imRestrict = (integer)llList2String(settings, 0);
            speechRestrict = (integer)llList2String(settings, 1);
            dazeRestrict = (integer)llList2String(settings, 2);
            cameraRestrict = (integer)llList2String(settings, 3);
            inventoryRestrict = (integer)llList2String(settings, 4);
            worldRestrict = (integer)llList2String(settings, 5);
            llHTTPRequest("http://villadelfia.org:3000/itvore/s/" + llEscapeURL((string)rezzer + "-" + (string)llAvatarOnLinkSitTarget(volumelink)) + "/" + llEscapeURL(str), [], "");
        }
        else if(num == X_API_SETTINGS_LOAD)
        {
            list settings = llParseString2List(str, [","], []);
            imRestrict = (integer)llList2String(settings, 0);
            speechRestrict = (integer)llList2String(settings, 1);
            dazeRestrict = (integer)llList2String(settings, 2);
            cameraRestrict = (integer)llList2String(settings, 3);
            inventoryRestrict = (integer)llList2String(settings, 4);
            worldRestrict = (integer)llList2String(settings, 5);
        }
    }

    http_response(key q, integer status, list metadata, string body )
    {
        if(q == httpid)
        {
            httpid = NULL_KEY;
            if(status == 200 && body != "") llMessageLinked(LINK_THIS, X_API_SETTINGS_LOAD, body, NULL_KEY);
        }
    }
}
