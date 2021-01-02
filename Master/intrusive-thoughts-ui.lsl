#include <IT/globals.lsl>

list buttons =         [];
list buttonlinks =     [];
list buttonstates =    [];
list buttonfilters =   [];

list indicators =      [];
list indicatorlinks =  [];

list textfields = [];
list textfieldtexts = [];

integer islocked = FALSE;
integer ishidden = FALSE;
integer isstatus = FALSE;

string lockedavatarname = "";
key lockedavatarkey = NULL_KEY;
string seenavatarname = "";
key seenavatarkey = NULL_KEY;
string seenobjectname = "";
key seenobjectkey = NULL_KEY;

float hoverheight = 0.0;

setheight()
{
    llOwnerSay("Hover height set to " + (string)hoverheight + ".");
    llOwnerSay("@adjustheight:" + (string)hoverheight + "=force");
}

setbuttonfilter(string filter, integer active)
{
    if(filter == "") return;
    float alpha;
    integer i = llGetListLength(buttonfilters);
    while(~--i)
    {
        string f = llList2String(buttonfilters, i);
        if(f == filter)
        {
            buttonstates = llListReplaceList(buttonstates, [active], i, i);
            if(active) alpha = 0.0;
            else       alpha = 0.7;
            llSetLinkAlpha(llList2Integer(buttonlinks, i), alpha, ALL_SIDES);
        }
    }

    i = llListFindList(indicators, [filter]);
    if(i == -1) return;
    if(active) alpha = 0.0;
    else       alpha = 1.0;
    llSetLinkAlpha(llList2Integer(indicatorlinks, i), alpha, ALL_SIDES);
}

string fontmap = " !\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~     ";
string fonttex = "bf38763e-9b99-e83b-f8d7-0f003d66103c";
vector indextooffset(integer index)
{
    if(index < 0 || index > 99) return <0, 0, 0>;
    integer x = index % 10;
    integer y = index / 10;
    return <-0.7+(x*0.1), 0.7-(y*0.1), 0>;
}

integer settext(integer line, string text)
{
    string lineprefix = (string)line + ".";
    integer suffix = 0;
    integer i = llListFindList(textfields, [lineprefix + (string)suffix]);
    if(i == -1) return FALSE;

    if(llList2String(textfieldtexts, line) == text) return TRUE;
    textfieldtexts = llListReplaceList(textfieldtexts, [text], line, line);

    list links = [];
    while(i != -1)
    {
        links += llList2Integer(textfields, i + 1);
        suffix++;
        i = llListFindList(textfields, [lineprefix + (string)suffix]);
    }

    integer maxlength = llGetListLength(links);
    while(llStringLength(text) < (maxlength * 8)) text = text + " ";
    if(llStringLength(text) > (maxlength * 8)) text = llDeleteSubString(text, -1, -1);

    integer j = 0;
    integer link = 0;
    list options = [];
    while(j < maxlength)
    {
        i = 0;
        link = llList2Integer(links, j);
        options += [PRIM_LINK_TARGET, link];
        while(i < 8)
        {
            options += [PRIM_TEXTURE, i, fonttex, <1.6,1.6,0>, indextooffset(llSubStringIndex(fontmap, llGetSubString(text, i+(j*8), i+(j*8)))), 0.0];
            i++;
        }
        j++;
    }
    llSetLinkPrimitiveParamsFast(0, options);
    return TRUE;
}

integer validatedisplayname(string name)
{
    integer l = llStringLength(name);
    while(~--l)
    {
        if(!contains(fontmap, llGetSubString(name, l, l))) return FALSE;
    }
    return TRUE;
}

sethide()
{
    if(ishidden) llSetLocalRot(<0.0, 0.0, -0.70711, 0.70711>);
    else         llSetLocalRot(ZERO_ROTATION);
}

dosetup()
{
    integer i = llGetNumberOfPrims();
    while(~i)
    {
        key link = llGetLinkKey(i);
        list details = llGetObjectDetails(link, [OBJECT_NAME, OBJECT_DESC]);
        string name = llList2String(details, 0);
        string desc = llList2String(details, 1);
        if(desc == "indicator")
        {
            indicators += [name];
            indicatorlinks += [i];
        }
        else if(desc == "text")
        {
            textfields += [name, i];
            textfieldtexts += ["x"];
        }
        else if(startswith(desc, "button"))
        {
            buttons += [name];
            buttonlinks += [i];
            string filter = llList2String(llParseString2List(desc, [".have"], []), 1);
            buttonfilters += [filter];
            if(filter == "")
            {
                buttonstates += [TRUE];
                llSetLinkAlpha(i, 0.0, ALL_SIDES);
            }
            else if(filter == "hidden")
            {
                buttonstates += [TRUE];
                llSetLinkAlpha(i, 1.0, ALL_SIDES);
            }
            else
            {
                buttonstates += [FALSE];
                llSetLinkAlpha(i, 0.7, ALL_SIDES);
            }
        }
        --i;
    }
    i = 0;
    while(settext(i++, ""));
    llSetObjectName("");
    llListen(BALL_CHANNEL, "", llGetOwner(), "");
    llMessageLinked(LINK_SET, M_API_HUD_STARTED, "", (key)"");
}

doquicksetup()
{
    integer i = 0;
    while(settext(i++, ""));
    islocked = FALSE;
    isstatus = FALSE;
    hoverheight = 0.0;
    llSetObjectName("");
    llMessageLinked(LINK_SET, M_API_HUD_STARTED, "", (key)"");
    llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
}

default
{
    changed(integer change)
    {
        if(change & CHANGED_OWNER) resetscripts();
    }

    attach(key id)
    {
        if(id) doquicksetup();
    }

    state_entry()
    {
        resetother();
        dosetup();
    }

    listen(integer channel, string name, key id, string message)
    {
        string oldn = llGetObjectName();
        llSetObjectName("Your Thoughts");
        llOwnerSay(message);
        llSetObjectName(oldn);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == M_API_CAM_AVATAR)
        {
            if(validatedisplayname(str))
            {
                seenavatarname = str;
            }
            else
            {
                seenavatarname = llGetUsername(id);
                string outname = "";
                list names = llParseString2List(seenavatarname, ["."], []);
                integer i = 0;
                integer l = llGetListLength(names);
                while(i < l)
                {
                    string word = llList2String(names, i);
                    word = llToUpper(llGetSubString(word, 0, 0)) + llGetSubString(word, 1, -1);
                    if(llToLower(word) != "resident") outname += word;
                    if(i != l-1) outname += " ";
                    ++i;
                }
                seenavatarname = outname;
            }
            seenavatarkey = id;
            if(isstatus || islocked) return;
            settext(0, seenavatarname);
        }
        else if(num == M_API_CAM_OBJECT)
        {
            seenobjectname = str;
            seenobjectkey = id;
            if(isstatus) return;
            settext(1, str);
        }
        else if(num == M_API_STATUS_MESSAGE)
        {
            isstatus = TRUE;
            seenobjectname = str;
            seenobjectkey = id;
            settext(0, str);
            settext(1, (string)id);
        }
        else if(num == M_API_STATUS_DONE)
        {
            isstatus = FALSE;
            if(!islocked) settext(0, seenavatarname);
            else          settext(0, lockedavatarname);
            settext(1, seenobjectname);
        }
        else if(num == M_API_LOCK)
        {
            lockedavatarkey = id;
            if(validatedisplayname(str))
            {
                lockedavatarname = str;
            }
            else
            {
                lockedavatarname = llGetUsername(id);
                string outname = "";
                list names = llParseString2List(lockedavatarname, ["."], []);
                integer i = 0;
                integer l = llGetListLength(names);
                while(i < l)
                {
                    string word = llList2String(names, i);
                    word = llToUpper(llGetSubString(word, 0, 0)) + llGetSubString(word, 1, -1);
                    if(llToLower(word) != "resident") outname += word;
                    if(i != l-1) outname += " ";
                    ++i;
                }
                lockedavatarname = outname;
            }
            if(str == "")
            {
                islocked = FALSE;
                setbuttonfilter("lock", FALSE);
                settext(0, seenavatarname);
            }
            else
            {
                islocked = TRUE;
                setbuttonfilter("lock", TRUE);
                settext(0, ">" + str + "<");
            }
        }
        else if(num == M_API_SET_FILTER)
        {
            setbuttonfilter(str, (integer)((string)id));
        }
        else if(num == M_API_BUTTON_PRESSED)
        {
            if(str == "hide")
            {
                ishidden = !ishidden;
                sethide();
            }
            else if(str == "lock")
            {
                if(islocked) llMessageLinked(LINK_SET, M_API_LOCK, "", NULL_KEY);
                else         llMessageLinked(LINK_SET, M_API_LOCK, seenavatarname, seenavatarkey);
            }
            else if(str == "sit")
            {
                llSetObjectName("RLV Sit");
                if(llGetAgentInfo(lockedavatarkey) & AGENT_SITTING)
                {
                    llOwnerSay("Standing up '" + lockedavatarname + "'.");
                    if(lockedavatarkey == llGetOwner()) llOwnerSay("@unsit=force");
                    else                                llRegionSayTo(lockedavatarkey, RLVRC, "st," + (string)lockedavatarkey + ",@unsit=force");
                }
                else
                {
                    llOwnerSay("Sitting '" + lockedavatarname + "' on '" + seenobjectname + "'.");
                    if(lockedavatarkey == llGetOwner()) llOwnerSay("@sit:" + (string)seenobjectkey + "=force");
                    else                                llRegionSayTo(lockedavatarkey, RLVRC, "si," + (string)lockedavatarkey + ",@sit:" + (string)seenobjectkey + "=force");
                }
                llSetObjectName("");
            }
            else if(str == "leash")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "leashto " + (string)seenobjectkey);
            }
            else if(str == "rclear")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "CLEAR");
            }
            else if(str == "rdetach")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "FORCECLEAR");
            }
            else if(str == "rreset")
            {
                llRegionSayTo(lockedavatarkey, MANTRA_CHANNEL, "RESETRELAY");
            }
            else if(str == "reset")
            {
                hoverheight = 0.0;
                setheight();
            }
            else if(str == "++")
            {
                hoverheight += 3.0;
                setheight();
            }
            else if(str == "+")
            {
                hoverheight += 0.5;
                setheight();
            }
            else if(str == "--")
            {
                hoverheight -= 3.0;
                setheight();
            }
            else if(str == "-")
            {
                hoverheight -= 0.5;
                setheight();
            }
        }
    }

    touch_start(integer total_number)
    {
        string name = llGetLinkName(llDetectedLinkNumber(0));
        integer i = llListFindList(buttons, [name]);
        if(i == -1) return;
        if(ishidden == TRUE && name != "hide") return;
        string filter = llList2String(buttonfilters, i);
        if(filter != "" && llList2Integer(buttonstates, i) == FALSE) return;
        llMessageLinked(LINK_SET, M_API_BUTTON_PRESSED, name, seenobjectkey);
    }
}
