#include <IT/globals.lsl>

key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;
string mode = "unset";
string prefix = "";
list commands = [];
list commanddescription = [];
list commandscript = [];
list commanduuids = [];
list commandslaveallowed = [];
list commandinteractor = [];

default
{
    state_entry()
    {
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");

        // Parse through all other scripts, reset those not owner by creator and those starting with plugin.
        integer i;
        integer n = llGetInventoryNumber(INVENTORY_SCRIPT);
        for(i = 0; i < n; ++i)
        {
            string name = llGetInventoryName(INVENTORY_SCRIPT, i);
            key creator = llGetInventoryCreator(name);
            if(creator != llGetInventoryCreator(llGetScriptName()) || startswith(llToLower(name), "plugin")) llResetOtherScript(name);
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED) mode = "slave";
        else if(num == M_API_HUD_STARTED) mode = "master";
        else if(num == S_API_OWNERS)
        {
            owners = [];
            list new = llParseString2List(str, [","], []);
            integer n = llGetListLength(new);
            while(~--n)
            {
                owners += [(key)llList2String(new, n)];
            }
            primary = id;
        }
        else if(num == S_API_OTHER_ACCESS)
        {
            publicaccess = (integer)str;
            groupaccess = (integer)((string)id);
        }
        else if(num == IT_PLUGIN_REGISTER)
        {
            key new = NULL_KEY;
            string command = llList2String(llParseString2List((string)id, [" "], []), 0);
            if(llListFindList(commandscript, [str]) != -1 && llListFindList(commands, [command]) != -1)
            {
                // Already cached.
                integer idx = llListFindList(commands, [command]);
                llMessageLinked(LINK_SET, IT_PLUGIN_RESPONSE, mode + "," + str + "," + command, llList2Key(commanduuids, idx));
            }
            else
            {
                // Try to create new uuid.
                if(llListFindList(commands, [command]) == -1)
                {
                    new = llGenerateKey();
                    commands += [command];
                    commanddescription += [str];
                    commandscript += [str];
                    commanduuids += [new];
                    commandslaveallowed += [FALSE];
                    if(mode != "slave") commandinteractor += [llGetOwner()];
                    else                commandinteractor += [primary];
                }
                llMessageLinked(LINK_SET, IT_PLUGIN_RESPONSE, mode + "," + str + "," + command, new);
            }
        }
        else if(num == IT_PLUGIN_DESCRIPTION)
        {
            integer idx = llListFindList(commanduuids, [id]);
            if(idx != -1)
            {
                commanddescription = llListReplaceList(commanddescription, [str], idx, idx);
                llMessageLinked(LINK_SET, IT_PLUGIN_ACK, "OK", id);
            }
        }
        else if(num == IT_PLUGIN_OWNERSAY)
        {
            integer idx = llListFindList(commanduuids, [id]);
            if(idx != -1)
            {
                string command = llList2String(commands, idx);
                if(mode == "slave") command = prefix + command;
                str = strreplace(str, "%COMMAND%", "/1" + command);
                str = strreplace(str, "%APPCOMMAND%", "secondlife:///app/chat/1/" + command);
                string old = llGetObjectName();
                llSetObjectName("");
                ownersay(llList2Key(commandinteractor, idx), str, 0);
                llSetObjectName(old);
                llMessageLinked(LINK_SET, IT_PLUGIN_ACK, "OK", id);
            }
        }
        else if(num == IT_PLUGIN_ALLOWSLAVE)
        {
            integer idx = llListFindList(commanduuids, [id]);
            if(idx != -1)
            {
                if(str == "0")
                {
                    commandslaveallowed = llListReplaceList(commandslaveallowed, [FALSE], idx, idx);
                    llMessageLinked(LINK_SET, IT_PLUGIN_ACK, "OK", id);
                }
                else if(str == "1")
                {
                    commandslaveallowed = llListReplaceList(commandslaveallowed, [TRUE], idx, idx);
                    llMessageLinked(LINK_SET, IT_PLUGIN_ACK, "OK", id);
                }
                else
                {
                    llMessageLinked(LINK_SET, IT_PLUGIN_ACK, "String argument must be 0 or 1 for an IT_PLUGIN_ALLOWSLAVE call.", id);
                }
            }
        }
        else if(num == M_API_LOCK)
        {
            mode = "master";
            llMessageLinked(LINK_SET, IT_PLUGIN_LOCK, str, id);
        }
        else if(num == M_API_CAM_OBJECT)
        {
            mode = "master";
            llMessageLinked(LINK_SET, IT_PLUGIN_OBJECT, str, id);
        }
        else if(num <= -1000 && num > -1999)
        {
            mode = "slave";
        }
        else if(num <= -2000 && num > -2999)
        {
            mode = "master";
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY) mode = "unset";
    }

    listen(integer c, string n, key id, string m)
    {
        // We haven't started up yet.
        if(llGetListLength(commands) == 0) return;

        // Filter on allowed users.
        id = llGetOwnerKey(id);
        if(mode != "slave" && id != llGetOwner()) return;
        if(mode == "slave" && isowner(id) == FALSE && id != llGetOwner()) return;

        // If slave, check for prefix.
        if(mode == "slave")
        {
            if(startswith(m, "#") && id == llGetOwner())      return;
            if(startswith(m, prefix))                         m = llDeleteSubString(m, 0, 1);
            else if(startswith(m, "*") || startswith(m, "#")) m = llDeleteSubString(m, 0, 0);
            else                                              return;
        }

        if(m == "plugin" || m == "plugins")
        {
            llSetObjectName("");
            ownersay(id, "List of plugins:", 0);
            ownersay(id, " ", 0);
            integer n = llGetListLength(commands);
            while(~--n)
            {
                string c = llList2String(commands, n);
                string d = llList2String(commanddescription, n);
                if(mode == "slave")
                {
                    if(id != llGetOwner() || isowner(id) == TRUE || llList2Integer(commandslaveallowed, n) == TRUE)
                    {
                        ownersay(id, d + ": [secondlife:///app/chat/1/" + prefix + llEscapeURL(c) + " " + c + "]", 0);
                    }
                }
                else
                {
                    ownersay(id, d + ": [secondlife:///app/chat/1/" + llEscapeURL(c) + " " + c + "]", 0);
                }
            }
            if(mode == "slave") llSetObjectName(slave_base);
            else                llSetObjectName(master_base);
            return;
        }

        string command = llList2String(llParseString2List(m, [" "], []), 0);
        string arguments = llStringTrim(llDeleteSubString(m, 0, llStringLength(command)-1), STRING_TRIM);
        integer index = llListFindList(commands, [command]);

        if(index == -1) return;
        if(mode == "slave" && id == llGetOwner() && isowner(id) == FALSE && llList2Integer(commandslaveallowed, index) == FALSE) return;

        commandinteractor = llListReplaceList(commandinteractor, [id], index, index);
        key commanduuid = llList2Key(commanduuids, index);
        string who = "primaryowner";
        if(mode == "slave")
        {
            if(llListFindList(owners, [id]) != -1) who = "secondaryowner";
            else if(id == llGetOwner() && isowner(id) == FALSE) who = "slave";
        }

        if(arguments == "")
        {
            llMessageLinked(LINK_SET, IT_PLUGIN_INFOREQUEST, who, commanduuid);
        }
        else
        {
            llMessageLinked(LINK_SET, IT_PLUGIN_COMMAND, who + "," + (string)commanduuid, arguments);
        }
    }

    changed(integer change)
    {
        if(change & CHANGED_INVENTORY)
        {
            integer n = llGetListLength(commands);
            while(~--n)
            {
                if(llGetInventoryType(llList2String(commandscript, n)) != INVENTORY_SCRIPT)
                {
                    commands = llDeleteSubList(commands, n, n);
                    commanddescription = llDeleteSubList(commanddescription, n, n);
                    commandscript = llDeleteSubList(commandscript, n, n);
                    commanduuids = llDeleteSubList(commanduuids, n, n);
                    commandslaveallowed = llDeleteSubList(commandslaveallowed, n, n);
                    commandinteractor = llDeleteSubList(commandinteractor, n, n);
                }
            }
        }
    }
}
