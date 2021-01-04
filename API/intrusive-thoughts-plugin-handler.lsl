#include <IT/globals.lsl>

key primary = NULL_KEY;
list owners = [];
integer publicaccess = FALSE;
integer groupaccess = FALSE;
string mode = "";
string prefix = "";
list commands = [];
list commandscript = [];
list commanduuids = [];
list commandslaveallowed = [];
list commandinteractor = [];

default
{
    state_entry()
    {
        if(llGetScriptName() != "Intrusive Thoughts Plugin Handler") llRemoveInventory(llGetScriptName());
        prefix = llGetSubString(llGetUsername(llGetOwner()), 0, 1);
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        if(num == S_API_STARTED) mode = "slave";
        else if(num == M_API_CONFIG_DONE) mode = "master";
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
            if(llListFindList(commands, [(string)id]) == -1)
            {
                new = llGenerateKey();
                commands += [(string)id];
                commandscript += [str];
                commanduuids += [new];
                commandslaveallowed += [FALSE];
                if(mode == "master") commandinteractor += [llGetOwner()];
                else                 commandinteractor += [primary];
            }
            llMessageLinked(LINK_SET, IT_PLUGIN_RESPONSE, mode + "," + str + "," + (string)id, new);
        }
        else if(num == IT_PLUGIN_OWNERSAY)
        {
            integer idx = llListFindList(commanduuids, [id]);
            if(idx != -1)
            {
                ownersay(llList2Key(commandinteractor, idx), str);
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
            llMessageLinked(LINK_SET, IT_PLUGIN_LOCK, str, id);
        }
        else if(num == M_API_CAM_OBJECT)
        {
            llMessageLinked(LINK_SET, IT_PLUGIN_OBJECT, str, id);
        }
    }

    attach(key id)
    {
        if(id == NULL_KEY) mode = "";
    }

    listen(integer c, string n, key id, string m)
    {
        // We haven't started up yet.
        if(mode == "") return;

        // Filter on allowed users.
        id = llGetOwnerKey(id);
        if(mode == "master" && id != llGetOwner()) return;
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
            ownersay(id, "List of plugins:");
            ownersay(id, " ");
            integer n = llGetListLength(commands);
            while(~--n)
            {
                string c = llList2String(commands, n);
                if(mode == "slave")
                {
                    if(id != llGetOwner() || isowner(id) == TRUE || llList2Integer(commandslaveallowed, n) == TRUE)
                    {
                        ownersay(id, "[secondlife:///app/chat/1/" + prefix + llEscapeURL(c) + " " + c + "]");
                    }
                }
                else
                {
                    ownersay(id, "[secondlife:///app/chat/1/" + llEscapeURL(c) + " " + c + "]");
                }
            }
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
                    commandscript = llDeleteSubList(commandscript, n, n);
                    commanduuids = llDeleteSubList(commanduuids, n, n);
                    commandslaveallowed = llDeleteSubList(commandslaveallowed, n, n);
                    commandinteractor = llDeleteSubList(commandinteractor, n, n);
                }
            }
        }
    }
}