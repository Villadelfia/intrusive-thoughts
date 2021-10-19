// To make your own carrier, you will have to create your own handler. The API script will handle making the
// victim sit down and locking it to that position. It will also handle releasing.
//
// You are responsible for providing the sit targets and handling the animations, as well as ALL other RLV
// restrictions.
//
// These are the RLV restrictions that you will NOT have to handle:
//  - @unsit=n
//  - @tplocal=n
//  - @tplm=n
//  - @tploc=n
//  - @tplure_sec=n
//  - Redirected chat to the Master HUD.

#define IT_CARRIER_REGISTER  -8500
#define IT_CARRIER_ACID      -8501
#define IT_CARRIER_ACID_MAX  -8502
#define IT_CARRIER_APPLY_RLV -8503

setup()
{
    // First you must set up the sit target(s).
    llSitTarget(<0.0, 0.0, 0.001>, ZERO_ROTATION);

    // Notify the API script that your seats are ready and on which links there are seats.
    list sitTargetLinks = [0];
    llMessageLinked(LINK_SET, IT_CARRIER_REGISTER, llDumpList2String(sitTargetLinks, ","), (key)"");

    // Do any kind of setup you need to do for your own purposes here.
    // An example would be setting up audio.
}

default
{
    // Your carrier will be rezzed when it is used. You are responsible for letting the carrier
    // script know that you are ready to go.
    state_entry()
    {
        llSetTimerEvent(0.0);
        setup();
    }

    on_rez(integer start_param)
    {
        llSetTimerEvent(0.0);
        setup();
    }

    // The changed event will be raised when an avatar sits on the carrier. You should keep track
    // of this and play animations and do other things as appropriate.
    changed(integer change)
    {
        if(change & CHANGED_LINK)
        {
            if(llAvatarOnSitTarget())
            {
                // Do stuff like starting animations.

                // Apply your chosen RLV restrictions.
                llMessageLinked(LINK_SET, IT_CARRIER_APPLY_RLV, "@shownametags=n|@shownearby=n|@showhovertextall=n|@showworldmap=n|@showminimap=n|@showloc=n", llAvatarOnSitTarget());

                // Likely, you will want to have a timer to handle things like looking at the carrier.
                llSetTimerEvent(0.5);
            }
            else
            {
                // Generally, when the last sitter stands up, the carrier will be deleted immediately.
                // However, in multi-sit carriers, this can happen and you should take care to record
                // if someone stands up.
            }
        }
    }

    // There are two possible calls you can get via linked message.
    link_message(integer sender_num, integer num, string str, key id )
    {
        if(num == IT_CARRIER_ACID)
        {
            // Level will be a number between 0 and 100, starting at 40 controlled via the acid buttons on the HUD.
            // You may use this number as you wish.
            integer level = (integer)str;
        }
        else if(num == IT_CARRIER_ACID_MAX)
        {
            // This gets called when the HUD user clicks acid + when the acid is at the maximum level.
            // You can act on this as you desire.
        }
    }

    // You are free to use the timer for your own uses.
    timer()
    {
        if(llAvatarOnSitTarget())
        {
            // As mentioned above, you may want to handle things like looking at the carrier on a loop.
            llMessageLinked(LINK_SET, IT_CARRIER_APPLY_RLV, "@setcam_focus:" + (string)llGetKey() + ";0;0/1/0=force", llAvatarOnSitTarget());
        }
        else
        {
            llSetTimerEvent(0.0);
        }
    }
}