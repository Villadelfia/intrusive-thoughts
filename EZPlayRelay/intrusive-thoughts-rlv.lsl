#include <IT/globals.lsl>
key controller = NULL_KEY;
key objectifier = NULL_KEY;
key primary = NULL_KEY;
key rememberedFurniture = NULL_KEY;
list restrictions = [];

release(integer propagate)
{
    llSetTimerEvent(0.0);
    controller = NULL_KEY;
    objectifier = NULL_KEY;
    restrictions = [];
    llMessageLinked(LINK_SET, X_API_SET_RELAY, "", NULL_KEY);
    if(propagate) llMessageLinked(LINK_SET, X_API_RELEASE, "", NULL_KEY);
}

handlerlvrc(string msg, key id)
{
    list args = llParseStringKeepNulls(msg,[","],[]);
    string ident = llList2String(args,0);
    list commands = llParseString2List(llList2String(args,2),["|"],[]);
    integer i;
    string command;
    integer nc = llGetListLength(commands);

    for(i=0; i<nc; ++i)
    {
        command = llList2String(commands,i);
        if(llGetSubString(command,0,0)=="@")
        {
            llRegionSayTo(id, RLVRC, ident+","+(string)id+","+command+",ok");
            if(command != "@clear")
            {
                llOwnerSay(command);
                list subargs = llParseString2List(command, ["="], []);
                string behav = llGetSubString(llList2String(subargs, 0), 1, -1);
                integer index = llListFindList(restrictions, [behav]);
                string comtype = llList2String(subargs, 1);
                if(comtype == "n" || comtype == "add")
                {
                    if(index == -1) restrictions += [behav];
                }
                else if(comtype == "y" || comtype == "rem")
                {
                    if(index != -1) restrictions = llDeleteSubList(restrictions, index, index);
                }
            }
        }
        else if(command == "!release")
        {
            release(TRUE);
            llRegionSayTo(id, RLVRC, ident+","+(string)id+","+command+",ok");
        }
    }

    if(restrictions == [])
    {
        release(TRUE);
    }
}


default
{
    state_entry()
    {
        release(FALSE);
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == X_API_ACTIVATE)
        {
            primary = id;
            rememberedFurniture = (key)str;
            state active;
        }
    }
}

state active
{
    attach(key id)
    {
        if(id == NULL_KEY) llResetScript();
    }

    state_entry()
    {
        llListen(RLVRC, "", NULL_KEY, "");
    }

    listen(integer c, string n, key id, string m)
    {
        if(controller != NULL_KEY) return;
        if(objectifier != NULL_KEY) return;

        list args = llParseStringKeepNulls(m, [","], []);
        if(llGetListLength(args)!=3) return;

        string ident = llList2String(args, 0);
        string target = llList2String(args, 1);
        string command = llList2String(args, 2);
        string firstcommand = llList2String(llParseString2List(command, ["|"], []), 0);
        string behavior = llList2String(llParseString2List(firstcommand, ["="], []), 0);
        string value = llList2String(llParseString2List(firstcommand, ["="], []), 1);

        // Return if ident is not known.
        if(ident != "release" && ident != "restrict" && ident != "c" && ident != "cantp" &&
           ident != "acid" && ident != "cv" && ident != "focus" && ident != "cmd" &&
           ident != "tpt" && ident != "st" && ident != "si") return;

        // Or if the target is not us.
        if(target != (string)llGetOwner() && target != "ffffffff-ffff-ffff-ffff-ffffffffffff") return;

        // Or if it's not one of the allowed sources.
        // Allowed sources are the previous owner, or objects owned by them, or the last remembered furniture.
        vector size = llGetAgentSize(primary);
        integer allowed = FALSE;
        if(id == primary || llGetOwnerKey(id) == primary || id == rememberedFurniture) allowed = TRUE;

        // If the primary owner is present and none of the above hold, we also allow objects created by the same creator.
        // This is then assumed to be furniture.
        if(allowed == FALSE && size != ZERO_VECTOR && llGetCreator() == llList2Key(llGetObjectDetails(id, [OBJECT_CREATOR]), 0))
        {
            rememberedFurniture = id;
            allowed = TRUE;
            llMessageLinked(LINK_SET, X_API_REMEMBER_FURNITURE, "", rememberedFurniture);
        }

        if(!allowed) return;

        // Do the thing.
        llMessageLinked(LINK_SET, X_API_SET_RELAY, "", (key)target);
        handlerlvrc(m, id);
    }

    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == X_API_RELEASE)
        {
            release(FALSE);
        }
        else if(num == X_API_SET_OBJECTIFIER)
        {
            objectifier = id;
        }
        if(num == X_API_REMEMBER_FURNITURE)
        {
            rememberedFurniture = id;
        }
        else if(num == X_API_SET_CONTROLLER)
        {
            controller = id;
        }
    }
}
