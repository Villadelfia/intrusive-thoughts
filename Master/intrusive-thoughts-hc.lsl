// The Haute Cuisine part of IT is intentionally more complex and a bit hidden
// compared to all of the regular functions. It's meant for advanced users.
// This includes even things like IT not locking when the pred has an active
// prey. Because of its advanced nature and the requirement of modding and setup
// all the scripts involved in the subsystem are included with modify permissions
// but they will require setting up a local repository of the IT codebase from
// https://github.com/Villadelfia/intrusive-thoughts so that #include directives
// will work.
//
// Where in the normal vore subsystem the carrier is just called 'carrier', in
// the haute cuisine system we support multiple carriers, which are scanned for
// in inventory change change events and on boot. Any object which is named
// like 'hccarrier-name' is treated as a valid carrier and it is the
// responsibility of the modder to verify that it indeed is one.
//
// In this name, name is the name that shall be used in the commands for the hc
// subsystem, this name cannot contain spaces or dashes.
//
// Unlike in the regular vore system, the carrier itself is not responsible for
// capturing and restricting the prey. This is delegated to the hccapture object.
//
// The general workflow for eating someone using hc thus becomes:
//  - Check if there is a locked avatar. If not, cancel.
//  - Check if the requested carrier exists. If not, cancel.
//  - Check if the requested carrier is already rezzed. If not, do so.
//  - Rez the hccapture object and inform it of three things (and only three things):
//    - Who to capture by uuid.
//    - Which carrier to request more information from by uuid.
//    - Which offset to float beneath the pred.
//  - At this point, the hc subsystem is only responsible for ferrying commands
//    to the carriers and capturers and to check whether they still exist. If not,
//    it shall update its internal lists. The carriers and capturers will use their
//    description fields to communicate all the needed data to the hud to facilitate
//    bookkeeping.
//  - Everything else is interrogated between the carriers and capturers and is
//    documented in those scripts.

#include <IT/globals.lsl>
#include <IT/LibNRI.lsl>

integer configured = FALSE;
key lockedavatar = NULL_KEY;
string lockedname = "";
key pendingCaptureTarget = NULL_KEY;
string pendingCarrierTarget = "";
string pendingRezName = "";

// The carriers list is a list of 5-tuples:
//  - full object name.
//  - uuid of currently rezzed instance of the carrier.
//  - current z-offset under pred.
//  - current z-scale.
//  - comma-delimited list of uuid's currently known to be following said carrier.
#define CARRIER_STRIDE 5
list carriers = [];
integer carrierLength = 0;

string carrierNameForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return "";
    return llList2String(carriers, (idx*CARRIER_STRIDE));
}

key carrierKeyForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return NULL_KEY;
    return llList2Key(carriers, (idx*CARRIER_STRIDE)+1);
}

float carrierOffsetForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return -1.0;
    return llList2Float(carriers, (idx*CARRIER_STRIDE)+2);
}

float carrierZScaleForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return -1.0;
    return llList2Float(carriers, (idx*CARRIER_STRIDE)+3);
}

list carrierCarryingForIndex(integer idx) {
    if(idx * CARRIER_STRIDE >= carrierLength) return [];
    return llParseString2List(llList2String(carriers, (idx*CARRIER_STRIDE)+4), [","], []);
}

captureTarget(string cName, key tAvatar) {
    // If the carrier doesn't exist, early return.
    integer cIdx = llListFindList(carriers, [cName]);
    if(cIdx == -1) return;
    cIdx /= CARRIER_STRIDE;

    // If the carrier wasn't rezzed out yet, do so.
    // Otherwise rez the second stage.
    key cKey = carrierKeyForIndex(cIdx);
    if(cKey == NULL_KEY) rezFirstStage(cName, tAvatar);
    else                 rezSecondStage(cName, tAvatar);
}

rezFirstStage(string cName, key tAvatar) {
    // If the carrier doesn't exist, early return.
    integer cIdx = llListFindList(carriers, [cName]);
    if(cIdx == -1) return;
    cIdx /= CARRIER_STRIDE;

    // Save what we expect to be rezzed.
    pendingCaptureTarget = tAvatar;
    pendingCarrierTarget = cName;
    pendingRezName = cName;

    // Send it. We rez it with Start Param 1 so that the carrier can be inert
    // when rezzed manually.
    llRezAtRoot(pendingRezName, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
}

rezSecondStage(key cName, key tAvatar) {
    // If the carrier doesn't exist, early return.
    integer cIdx = llListFindList(carriers, [cName]);
    if(cIdx == -1) return;
    cIdx /= CARRIER_STRIDE;

    // Save what we expect to be rezzed.
    pendingCaptureTarget = tAvatar;
    pendingCarrierTarget = cName;
    pendingRezName = "hccapture";

    // Send it. We rez it with Start Param 1 so that the capturer can be inert
    // when rezzed manually.
    llRezAtRoot(pendingRezName, llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 1);
}

checkCarriers() {
    // Pre-populate with self
    if(carriers == []) {
        carriers += ["hccarrier-objectify", llGetOwner(), -1.0, -1.0, ""];
    }

    // Check if there's any new carriers...
    integer i = 0;
    integer l = llGetInventoryNumber(INVENTORY_OBJECT);
    for(i = 0; i < l; ++i) {
        // Check every object if it's the correct name, and is not listed yet.
        string oName = llGetInventoryName(INVENTORY_OBJECT, i);
        if(nriStringStartsWith(oName, "hccarrier-") && llListFindList(carriers, [oName]) == -1) {
            // Check if it has the correct amount of elements.
            list elements = llParseString2List(oName, ["-"], []);
            if(llGetListLength(elements) == 2) {
                // Add it to the list.
                carriers += [oName, NULL_KEY, 0.0, 0.0, ""];
            }
        }
    }
    carrierLength = llGetListLength(carriers);

    // Check if there's carriers missing from inventory...
    l = carrierLength / CARRIER_STRIDE;
    while(~--l) {
        string cName = carrierNameForIndex(l);
        if(cName != "hccarrier-objectify" && llGetInventoryType(cName) != INVENTORY_OBJECT) {
            // If it's both missing, and we don't have a residual copy rezzed, purge it.
            key cKey = carrierKeyForIndex(l);
            list cCarrying = carrierCarryingForIndex(l);
            if(cKey == NULL_KEY && cCarrying == []) {
                carriers = llDeleteSubList(carriers, l * CARRIER_STRIDE, ((l+1)*CARRIER_STRIDE)-1);
            }
        }
    }
    carrierLength = llGetListLength(carriers);

    // Check if all non-null uuids are still present.
    l = carrierLength / CARRIER_STRIDE;
    for(i = 0; i < l; ++i) {
        key cKey = carrierKeyForIndex(i);
        if(cKey != llGetOwner() && cKey != NULL_KEY && llList2Vector(llGetObjectDetails(cKey, [OBJECT_POS]), 0) == ZERO_VECTOR) {
            carriers = llListReplaceList(carriers, [NULL_KEY, -1.0, -1.0, ""], (i*CARRIER_STRIDE)+1, (i*CARRIER_STRIDE)+4);
        }

        // For just ourselves, we do check if the capturers are around.
        if(cKey == llGetOwner()) {
            integer madeChange = FALSE;
            list cCarrying = carrierCarryingForIndex(l);
            integer j = llGetListLength(cCarrying);
            while(~--j) {
                key cCapturer = (key)llList2String(cCarrying, j);
                if(llList2Vector(llGetObjectDetails(cCapturer, [OBJECT_POS]), 0) == ZERO_VECTOR) {
                    cCarrying = llDeleteSubList(cCarrying, j, j);
                    madeChange = TRUE;
                }
            }

            if(madeChange) {
                carriers = llListReplaceList(carriers, [llDumpList2String(cCarrying, ",")], (i*CARRIER_STRIDE)+4, (i*CARRIER_STRIDE)+4);
            }
        }
    }
}

reflowCarriers() {
    // Reflow all the carriers under the pred.
    float runningOffset = 5.0;
    integer i = 0;
    integer l = carrierLength / CARRIER_STRIDE;
    for(i = 0; i < l; ++i) {
        // Check all carriers and see if they exist.
        key cKey = carrierKeyForIndex(i);
        list cAABB = llGetBoundingBox(cKey);
        if(cKey != llGetOwner() && cAABB != []) {
            // Calculate their size and where they should be.
            vector cCurSize = llList2Vector(cAABB, 1) - llList2Vector(cAABB, 0);
            float cCurZ = cCurSize.z;
            float cPrevZ = carrierZScaleForIndex(i);
            float cCurOffset = runningOffset + (cCurZ / 2.0);
            float cPrevOffset = carrierOffsetForIndex(i);
            // Communicate and save the new offset and size if it changed.
            if(cCurZ != cPrevZ || cCurOffset != cPrevOffset) {
                carriers = llListReplaceList(carriers, [cCurOffset, cCurZ], (i*CARRIER_STRIDE)+2, (i*CARRIER_STRIDE)+3);
                llRegionSayTo(cKey, MANTRA_CHANNEL, "hc_zoffset " + (string)cCurOffset);
            }
            // Add this z-size to the running start point.
            runningOffset += cCurZ;
        }
    }
}

key getAvatarFromCapturer(key uuid) {
    // Check if we have the capturer uuid recorded.
    integer l = carrierLength / CARRIER_STRIDE;
    integer i = 0;
    for(i = 0; i < l; ++i) {
        list cCarrying = carrierCarryingForIndex(i);
        integer k = llGetListLength(cCarrying);
        while(~--k) {
            // If we do, make some further checks to get the avatar from it.
            key cCapturer = (key)llList2String(cCarrying, k);
            if(cCapturer == uuid) {
                // By contract, the description of a capturer is a CSV.
                //  - The first element is the uuid of the carrier it's following.
                //  - The second element is the uuid of the avatar that should be sitting on it.
                //  - The third element is the seat index.
                //  - More might be added in the future, but that's the contract that we expect.
                list details = llParseString2List(llList2String(llGetObjectDetails(uuid, [OBJECT_DESC]), 0), [","], []);

                // So reject if it's not enough.
                if(llGetListLength(details) < 2) return NULL_KEY;

                // Get the carrier and avatar uuid.
                key what = (key)llList2String(details, 0);
                key who = (key)llList2String(details, 1);

                // Verify we know the carrier and verify the avatar is actually seated right.
                if(llListFindList(carriers, [what]) == -1) return NULL_KEY;
                if(llList2Key(llGetObjectDetails(who, [OBJECT_ROOT]), 0) != who) return NULL_KEY;

                // And finally return it.
                return who;
            }
        }
    }
    return NULL_KEY;
}

default {
    state_entry() {
        llListen(HC_CHANNEL, "", NULL_KEY, "");
        llListen(MANTRA_CHANNEL, "", NULL_KEY, "");
        llListen(COMMAND_CHANNEL, "", NULL_KEY, "");
    }

    attach(key id) {
        if(id == NULL_KEY) llSetTimerEvent(0.0);
    }

    object_rez(key id) {
        string name = llList2String(llGetObjectDetails(id, [OBJECT_NAME]), 0);
        if(name != pendingRezName) return;

        // Handle 2nd stage of capture.
        if(name == "hccapture") {
            // What are we capturing for?
            integer cIdx = llListFindList(carriers, [pendingCarrierTarget]);
            if(cIdx == -1) {
                pendingCaptureTarget = NULL_KEY;
                pendingCarrierTarget = "";
                pendingRezName = "";
                return;
            }
            cIdx /= CARRIER_STRIDE;

            // Tell the capturer what to follow, and who to capture.
            key cKey = carrierKeyForIndex(cIdx);
            llRegionSayTo(id, MANTRA_CHANNEL, "hc_capture " + (string)pendingCaptureTarget + " " + (string)cKey);
            pendingCaptureTarget = NULL_KEY;
            pendingCarrierTarget = "";
            pendingRezName = "";

            // If the cKey happens to be us, aka we are objectifiying the target, the capturer will be contacting us.
            // So we don't handle it differently here.
        }

        // Handle 1st stage of capture.
        else if(llListFindList(carriers, [name]) != -1) {
            // What carrier did we just rez?
            integer cIdx = llListFindList(carriers, [name]);
            if(cIdx == -1) {
                pendingCaptureTarget = NULL_KEY;
                pendingCarrierTarget = "";
                pendingRezName = "";
                return;
            }
            cIdx /= CARRIER_STRIDE;

            // Store the key.
            carriers = llListReplaceList(carriers, [id], (idx*CARRIER_STRIDE)+1, (idx*CARRIER_STRIDE)+1);

            // Place it.
            reflowCarriers();

            // Do the second stage.
            rezSecondStage(key pendingCarrierTarget, key pendingCaptureTarget);
        }
    }

    listen(integer c, string n, key id, string m) {
        if(!configured) return;

        if(c == HC_CHANNEL) {
            // This channel is how chat gets broadcast.
            id = getAvatarFromCapturer(id);
            if(id == NULL_KEY) return;
            llSetObjectName("secondlife:///app/agent/" + (string)id + "/about");
            llSay(0, m);
            llSetObjectName(master_base);
        } else if(c == MANTRA_CHANNEL) {
            // Handle mantra.
            // This is where the carriers will inform us of their state.
            // Namely which people are in the carrier.
            // Carriers can also cause something to be worn from the #RLV folder.
            //
            // HUD -> carrier:
            // - hc_zoffset <z>
            //   Set z-offset below self to float.
            // - hc_freeze <0/1>
            //   Freeze/unfreeze the carrier.
            // - hc_release
            //   Release all avatars following carrier.
            // - hc_ccmd <...>
            //   Send a command to the carrier, free to interpret by carrier.
            // - hc_transfer <carrier_uuid>
            //   Transfers ALL capturers from this carrier to another.
            // - hc_reassign_idx <capturer_uuid> <seat_idx>
            //   Transfer given capturer to given seat index. Swap occupant if taken.
            // - hc_reassign_carrier <capturer_uuid> <carrier_uuid>
            //   Transfer given capturer to different carrier.
            // - hc_swap_capturers <capturer_uuid_a> <capturer_uuid_b>
            //   Swaps the two given capturers. Capturer A will always be native to the carrier,
            //   Capturer B may or may not be native. If non-native, the same command will be
            //   sent to the remote carrier with swapped arguments.
            //
            // Carrier -> Avatar Wearing HUD:
            // - hc_cstatus <capture_csv>
            //   Capture_csv is a comma-separated list of capturers that are bound to the carrier.
            // - hc_volume <volume_in_m³>
            //   The approximate volume in m³ of all following capturers. The HUD does nothing
            //   with this data, but worn vore bellies can do something with it.
            // - hc_cwear <rlv_subfolder>
            //   Causes "#RLV/~IT/<carrier_name>" to be taken off recursively, then
            //   "#RLV/~IT/<carrier_name>/<rlv_subfolder>" to be worn.
            //   By default this is "#RLV/~IT/<carrier_name>/on" when rezzing and
            //   "#RLV/~IT/<carrier_name>/off" when derezzing, but the carrier script can be
            //   modified to add more states.
            //
            // HUD -> Capturer:
            // - hc_capture <avatar_uuid> <carrier_uuid>
            //   Capture given avatar on given carrier.
            // - hc_animate <animation_name>
            //   Play given animation on occupant if it exists.
            // - hc_release
            //   Release occupant.
            //
            // Capturer -> Carrier:
            // - hc_request_follow
            //   Asks carrier for a seat link to follow.
            // - hc_is_releasing
            //   Inform carrier that the capturer is releasing its victim. Strictly not needed since
            //   the carrier actively scans, but improves speed of the system.
            // - hc_take_seat <seat_idx>
            //   Take the given seat.
            //
            // Carrier -> Capturer:
            // - hc_give_seat <seat_idx> <seat_uuid>
            //   Assign seat to capturer. Will be sent when requested, but can also be sent when a
            //   swap is requested. This command unblinds the victim.
            // - hc_release
            //   Release occupant. This command unblinds the victim.
            // - hc_unfollow
            //   Inform capturer that its seat is no longer reserved for it. Capturer should start
            //   a short timer where it waits for a carrier to send a hc_give_seat command. If it
            //   doesn't get an assignment in time, it will release the occupant. This command is
            //   ignored if the sender isn't the current carrier. This command will blind the victim
            //   until released or given a new seat.
        } else if(c == COMMAND_CHANNEL) {
            if(llGetOwnerKey(id) != llGetOwner()) return;
            if(nriParseCommand(m, "hc", "!") == "!") return;
            // Handle hc commands.
            // Available commands are:
            //  - /1hc status
            //    List all available carriers and the names of everyone in those carriers.
            //  - /1hc capture <carrier name>
            //    Capture the locked avatar in the named carrier.
            //  - /1hc release <username>
            //    Release named user.
            //  - /1hc release <carrier name>
            //    Release everyone in listed carrier.
            //  - /1hc release all
            //    Release everyone.
            //  - /1hc transfer <username> to <carrier>
            //    Transfers named person to the named carrier.
            //  - /1hc transfer <carrier a> to <carrier b>
            //    Moves everyone in carrier a to carrier b.
            //  - /1hc command <carrier name> <command>
            //    Send command to named carrier. Every carrier can choose how to use these commands.
            //  - /1hc freeze
            //    Prevent all carriers from moving until the same command is used again.
            //  - /1hc animate <username> with <animation>
            //    Play named animation on username, if it is present in the capturer.
            //  - /1hc swap <username a> with <username b/index>
            //    Swaps the seat of username a with that of username b. Even if on different carriers.
            //    If index is given instead, swap with whoever is on that numbered seat on the same carrier,
            //    or just moves there if it's not occupied.
        }
    }

    link_message(integer sender_num, integer num, string str, key id) {
        if(num == M_API_CONFIG_DONE) {
            llSetTimerEvent(5.0);
            configured = TRUE;
        } else if(num == M_API_CONFIG_DATA) {
            configured = FALSE;
        } else if(num == M_API_LOCK) {
            lockedavatar = id;
            lockedname = str;
        }
    }

    timer() {
        llSetTimerEvent(0.0);
        if(!configured) return;
        checkCarriers();
        reflowCarriers();
        llSetTimerEvent(5.0);
    }
}
