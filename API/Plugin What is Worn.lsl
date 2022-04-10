#define IT_PLUGIN_REGISTER    -8000 // PLUGIN -> IT
#define IT_PLUGIN_RESPONSE    -8001 // IT -> PLUGIN
#define IT_PLUGIN_OWNERSAY    -8002 // PLUGIN -> IT
#define IT_PLUGIN_INFOREQUEST -8003 // IT -> PLUGIN
#define IT_PLUGIN_COMMAND     -8004 // IT -> PLUGIN
#define IT_PLUGIN_ALLOWSLAVE  -8005 // PLUGIN -> IT
#define IT_PLUGIN_ACK         -8006 // IT -> PLUGIN
#define IT_PLUGIN_LOCK        -8007 // IT -> PLUGIN
#define IT_PLUGIN_OBJECT      -8008 // IT -> PLUGIN
#define IT_PLUGIN_DESCRIPTION -8009 // PLUGIN -> IT

string type;
string chatcommand = "wiw";
integer retryct = 0;
key assigneduuid = NULL_KEY;

string lockedname = "";
key lockedkey = NULL_KEY;

default
{
    state_entry()
    {
        llSleep(5.0);
        llMessageLinked(LINK_SET, IT_PLUGIN_REGISTER, llGetScriptName(), chatcommand);
        llSetTimerEvent(30.0);
    }

    timer()
    {
        llMessageLinked(LINK_SET, IT_PLUGIN_REGISTER, llGetScriptName(), chatcommand);
    }

    attach(key id)
    {
        if(id)
        {
            lockedname = "";
            lockedkey = NULL_KEY;
        }
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
        // Register response.
        if(num == IT_PLUGIN_RESPONSE)
        {
            list args = llParseString2List(str, [","], []);
            type = (string)args[0];

            // We only support master.
            if(type == "slave")
            {
                llRemoveInventory(llGetScriptName());
                return;
            }

            // If we're being targeted by the call.
            if((string)args[1] == llGetScriptName() && (string)args[2] == chatcommand)
            {
                assigneduuid = id;

                // If the command was taken, try again with a number appended.
                if(assigneduuid == NULL_KEY)
                {
                    chatcommand = "wiw" + (string)retryct;
                    ++retryct;
                    llMessageLinked(LINK_SET, IT_PLUGIN_REGISTER, llGetScriptName(), chatcommand);
                }

                // Otherwise, give a short description of the command.
                else
                {
                    llMessageLinked(LINK_SET, IT_PLUGIN_DESCRIPTION, "See what your locked avatar is wearing", assigneduuid);
                }
            }
        }

        // The system wants plugin information.
        else if(num == IT_PLUGIN_INFOREQUEST)
        {
            // If not aimed at us, return.
            if(id != assigneduuid) return;

            // Otherwise, respond.
            string text = "What is worn plugin: With a locked avatar, click [%APPCOMMAND%" + llEscapeURL(" get") + " here] or type %COMMAND% get to get everything they are wearing.";
            llMessageLinked(LINK_SET, IT_PLUGIN_OWNERSAY, text, assigneduuid);
        }

        // The system wants us to execute a command.
        else if(num == IT_PLUGIN_COMMAND)
        {
            // If not aimed at us, return.
            key uuid = (key)llList2String(llParseString2List(str, [","], []), 1);
            if(uuid != assigneduuid) return;

            if((string)id == "get" && lockedname != "")
            {
                llMessageLinked(LINK_SET, IT_PLUGIN_OWNERSAY, lockedname + " is wearing:", assigneduuid);
                string prefix = llToLower(llGetSubString(lockedname, 0, 1));
                list data;
                list uuids = llGetAttachedList(lockedkey);
                string uuid;
                integer n = llGetListLength(uuids);
                while(~--n)
                {
                    uuid = llList2Key(uuids, n);
                    data = llGetObjectDetails(uuid, [OBJECT_NAME, OBJECT_CREATOR]);
                    llMessageLinked(LINK_SET, IT_PLUGIN_OWNERSAY, "» " + (string)data[0] + " ([secondlife:///app/chat/1/" + prefix + "@detach:" + uuid + "=force take off]) « by secondlife:///app/agent/" + (string)((key)data[1]) + "/about", assigneduuid);
                }
            }
        }

        // If an avatar is locked.
        else if(num == IT_PLUGIN_LOCK)
        {
            lockedname = str;
            lockedkey = id;
        }
    }
}
