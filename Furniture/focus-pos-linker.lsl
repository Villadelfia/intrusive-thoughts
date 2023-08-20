key linkTarget;

default
{
    state_entry()
    {
        llListen(-1443216791, "", NULL_KEY, "");
    }

    listen(integer channel, string name, key id, string message)
    {
        if(llGetOwnerKey(id) != llGetOwner()) return;
        linkTarget = (key)message;
        llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
    }

    run_time_permissions(integer perm)
    {
        if(perm & PERMISSION_CHANGE_LINKS)
        {
            llRegionSay(-1443216792, "OK");
            // Give it enough time to actually set the params.
            llSetLinkPrimitiveParams(LINK_THIS, [PRIM_COLOR, ALL_SIDES, ZERO_VECTOR, 0.0, PRIM_TEXTURE, ALL_SIDES, "8dcd4a48-2d37-4909-9f78-f7a9eb4ef903", <1.0, 1.0, 0.0>, ZERO_VECTOR, 0.0, PRIM_ALPHA_MODE, ALL_SIDES, PRIM_ALPHA_MODE_BLEND, 0]);
            llSleep(0.5);
            llCreateLink(linkTarget, FALSE);
            llRemoveInventory(llGetScriptName());
        }
        else
        {
            llOwnerSay("Please accept the permission.");
            llRequestPermissions(llGetOwner(), PERMISSION_CHANGE_LINKS);
        }
    }
}
