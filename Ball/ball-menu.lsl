#include <IT/globals.lsl>
key rezzer;
key firstavatar;
key httpid;
string prefix = "??";
integer imRestrict = 0;
integer visionRestrict = 0;
integer hearingRestrict = 0;
integer speechRestrict = 1;
integer dazeRestrict = 1;
integer cameraRestrict = 1;
integer inventoryRestrict = 1;
integer worldRestrict = 1;
integer isHidden = 0;

string restrictionString()
{
    return (string)imRestrict + "," + 
           (string)visionRestrict + "," + 
           (string)hearingRestrict + "," + 
           (string)speechRestrict + "," + 
           (string)dazeRestrict + "," + 
           (string)cameraRestrict + "," + 
           (string)inventoryRestrict + "," + 
           (string)worldRestrict + "," + 
           (string)isHidden;
}

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
    llRegionSayTo(firstavatar, 0, "Vision Options:");
    if(visionRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(visionRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi1 Dark fog at 10 meters.]");
    else if(visionRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Dark fog at 10 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Dark fog at 10 meters.");
    if(visionRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi2 Light fog at 10 meters.]");
    else if(visionRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Light fog at 10 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Light fog at 10 meters.");
    if(visionRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi3 Dark fog at 5 meters.]");
    else if(visionRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Dark fog at 5 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Dark fog at 5 meters.");
    if(visionRestrict < 4)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi4 Light fog at 5 meters.]");
    else if(visionRestrict == 4)  llRegionSayTo(firstavatar, 0, " * Light fog at 5 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Light fog at 5 meters.");
    if(visionRestrict < 5)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi5 Dark fog at 2 meters.]");
    else if(visionRestrict == 5)  llRegionSayTo(firstavatar, 0, " * Dark fog at 2 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Dark fog at 2 meters.");
    if(visionRestrict < 6)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi6 Light fog at 2 meters.]");
    else if(visionRestrict == 6)  llRegionSayTo(firstavatar, 0, " * Light fog at 2 meters.");
    else                          llRegionSayTo(firstavatar, 0, " - Light fog at 2 meters.");
    if(visionRestrict < 7)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "vi7 Blind.]");
    else if(visionRestrict == 7)  llRegionSayTo(firstavatar, 0, " * Blind.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Hearing Options:");
    if(hearingRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                           llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(hearingRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "he1 Incapable of hearing anyone but wearer and co-captured victims.]");
    else if(hearingRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Incapable of hearing anyone but wearer and co-captured victims.");
    else                           llRegionSayTo(firstavatar, 0, " - Incapable of hearing anyone but wearer and co-captured victims.");
    if(hearingRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "he2 Incapable of hearing anyone but wearer.]");
    else if(hearingRestrict == 2)  llRegionSayTo(firstavatar, 0, " * Incapable of hearing anyone but wearer.");
    else                           llRegionSayTo(firstavatar, 0, " - Incapable of hearing anyone but wearer.");
    if(hearingRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "he3 Deaf.]");
    else if(hearingRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Deaf.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Speech Options:");
    if(speechRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(speechRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp1 Not capable of speech except to owner and other captives. Can emote.]");
    else if(speechRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Not capable of speech except to owner and other captives. Can emote.");
    else                          llRegionSayTo(firstavatar, 0, " - Not capable of speech except to owner and other captives. Can emote.");
    if(speechRestrict < 2)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp2 No longer capable of emoting.]");
    else if(speechRestrict == 2)  llRegionSayTo(firstavatar, 0, " * No longer capable of emoting.");
    else                          llRegionSayTo(firstavatar, 0, " - No longer capable of emoting.");
    if(speechRestrict < 3)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "sp3 Incapable of any kind of speech, even to owner.]");
    else if(speechRestrict == 3)  llRegionSayTo(firstavatar, 0, " * Incapable of any kind of speech, even to owner.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Daze Options:");
    if(dazeRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                        llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(dazeRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "da1 Location and people hidden.]");
    else if(dazeRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Location and people hidden.");
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Camera Options:");
    if(cameraRestrict == 0)       llRegionSayTo(firstavatar, 0, " * No restrictions.");
    else                          llRegionSayTo(firstavatar, 0, " - No restrictions.");
    if(cameraRestrict < 1)        llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "ca1 Camera restricted to wearer.]");
    else if(cameraRestrict == 1)  llRegionSayTo(firstavatar, 0, " * Camera restricted to wearer.");
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
    llRegionSayTo(firstavatar, 0, " ");
    llRegionSayTo(firstavatar, 0, "Visibility Options:");
    if(!isHidden)  llRegionSayTo(firstavatar, 0, " - Under the ground, nameplate visible.");
    else           llRegionSayTo(firstavatar, 0, " * Under the ground, nameplate visible.");
    if(isHidden)   llRegionSayTo(firstavatar, 0, " - [secondlife:///app/chat/5/" + prefix + "invis Completely invisible, even the nameplate. Slightly fiddly to become visible again after release.]");
    else           llRegionSayTo(firstavatar, 0, " * Completely invisible, even the nameplate. Slightly fiddly to become visible again after release.");
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
    llOwnerSay("Vision Options:");
    if(visionRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi0 No restrictions.]");
    else                     llOwnerSay(" * No restrictions.");
    if(visionRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi1 Dark fog at 10 meters.]");
    else                     llOwnerSay(" * Dark fog at 10 meters.");
    if(visionRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi2 Light fog at 10 meters.]");
    else                     llOwnerSay(" * Light fog at 10 meters.");
    if(visionRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi3 Dark fog at 5 meters.]");
    else                     llOwnerSay(" * Dark fog at 5 meters.");
    if(visionRestrict != 4)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi4 Light fog at 5 meters.]");
    else                     llOwnerSay(" * Light fog at 5 meters.");
    if(visionRestrict != 5)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi5 Dark fog at 2 meters.]");
    else                     llOwnerSay(" * Dark fog at 2 meters.");
    if(visionRestrict != 6)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi6 Light fog at 2 meters.]");
    else                     llOwnerSay(" * Light fog at 2 meters.");
    if(visionRestrict != 7)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "vi7 Blind.]");
    else                     llOwnerSay(" * Blind.");
    llOwnerSay(" ");
    llOwnerSay("Hearing Options:");
    if(hearingRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he0 No restrictions.]");
    else                      llOwnerSay(" * No restrictions.");
    if(hearingRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he1 Incapable of hearing anyone but wearer and co-captured victims.]");
    else                      llOwnerSay(" * Incapable of hearing anyone but wearer and co-captured victims.");
    if(hearingRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he2 Incapable of hearing anyone but wearer.]");
    else                      llOwnerSay(" * Incapable of hearing anyone but wearer.");
    if(hearingRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "he3 Deaf.]");
    else                      llOwnerSay(" * Deaf.");
    llOwnerSay(" ");
    llOwnerSay("Speech Options:");
    if(speechRestrict != 0)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp0 No restrictions.]");
    else                     llOwnerSay(" * No restrictions.");
    if(speechRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp1 Not capable of speech except to owner and other captives. Can emote.]");
    else                     llOwnerSay(" * Not capable of speech except to owner and other captives. Can emote.");
    if(speechRestrict != 2)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp2 No longer capable of emoting.]");
    else                     llOwnerSay(" * No longer capable of emoting.");
    if(speechRestrict != 3)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "sp3 Incapable of any kind of speech, even to owner.]");
    else                     llOwnerSay(" * Incapable of any kind of speech, even to owner.");
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
    if(cameraRestrict != 1)  llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "ca1 Camera restricted to wearer.]");
    else                     llOwnerSay(" * Camera restricted to wearer.");
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
    llOwnerSay(" ");
    llOwnerSay("Visibility Options:");
    if(!isHidden)  llOwnerSay(" - Under the ground, nameplate visible.");
    else           llOwnerSay(" * Under the ground, nameplate visible.");
    if(isHidden)   llOwnerSay(" - [secondlife:///app/chat/5/" + prefix + "invis Completely invisible, even the nameplate. Slightly fiddly to become visible again after release.]");
    else           llOwnerSay(" * Completely invisible, even the nameplate. Slightly fiddly to become visible again after release.");
    llOwnerSay(" ");
    llOwnerSay("Other Options:");
    llOwnerSay(" - Type /5" + prefix + "name <new name> to rename this object.");
    llOwnerSay(" - If there is a purple cylinder present, you can move it to change the object's nameplate, then click it to hide it.");
}

default
{
    state_entry()
    {
        rezzer = llGetOwner();
    }

    on_rez(integer start_param)
    {
        rezzer = llGetOwnerKey((key)llList2String(llGetObjectDetails(llGetKey(), [OBJECT_REZZER_KEY]), 0));
    }

    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            if(llAvatarOnSitTarget() != NULL_KEY)
            {
                prefix = llToLower(llGetSubString(llGetUsername(llAvatarOnSitTarget()), 0, 1));
                firstavatar = llAvatarOnSitTarget();
                httpid = llHTTPRequest("http://villadelfia.org:3000/itprefs/l/" + llEscapeURL((string)rezzer + "-" + (string)llAvatarOnSitTarget()), [], "");
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
            visionRestrict = (integer)llList2String(settings, 1);
            hearingRestrict = (integer)llList2String(settings, 2);
            speechRestrict = (integer)llList2String(settings, 3);
            dazeRestrict = (integer)llList2String(settings, 4);
            cameraRestrict = (integer)llList2String(settings, 5);
            inventoryRestrict = (integer)llList2String(settings, 6);
            worldRestrict = (integer)llList2String(settings, 7);
            isHidden = (integer)llList2String(settings, 8);
            llHTTPRequest("http://villadelfia.org:3000/itprefs/s/" + llEscapeURL((string)rezzer + "-" + (string)llAvatarOnSitTarget()) + "/" + llEscapeURL(str), [], "");
        }
        else if(num == X_API_SETTINGS_LOAD)
        {
            list settings = llParseString2List(str, [","], []);
            imRestrict = (integer)llList2String(settings, 0);
            visionRestrict = (integer)llList2String(settings, 1);
            hearingRestrict = (integer)llList2String(settings, 2);
            speechRestrict = (integer)llList2String(settings, 3);
            dazeRestrict = (integer)llList2String(settings, 4);
            cameraRestrict = (integer)llList2String(settings, 5);
            inventoryRestrict = (integer)llList2String(settings, 6);
            worldRestrict = (integer)llList2String(settings, 7);
            isHidden = (integer)llList2String(settings, 8);
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