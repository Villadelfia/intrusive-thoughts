# Intrusive Thoughts
## License:
This project is licensed under the GNU Affero GPL v3. I, Hana Nova, am the sole contributor to this project. Any external contributions will only be accepted with a waiver handing over all rights to the contributed code back to the project owner.

This does not mean you can just use this code without making your changes public, in fact you must make them public for free. But it does mean that I will not include your changes in this main repository without signing a contributor agreement.

## Instructions:

Create a cube and put one copy of every script in the Slave directory into it. Then add as many rlv relay client scripts as you need device support. Make sure to check global.lsl for the expected name of this client script. Add as many transferrable animations as you want into it. Reset all the scripts. This is your slave device.

Create a hud with a root prim that is the menu button and prims named "+", "++", "-", "--", "sit", "objectify", "lock", "relay", and "reset" linked to it. Then add one copy of every script in the Master directory into it, plus as many relay client scripts you need. Add the "!config" notecard, plus as many notecards as you want 'appliers' for your subs, examples of these are in the Configuration NC directory. Reset the scripts. This is your controller device.

Create an invisible prim named "ball" and drop the contents of the Ball directory into it. Then drop this ball into your controller device. Your controller device is now complete.

Make two invisible prims, and drop one of the scripts in the Translator directory in each. One will be a universal translator while the other one will be tuned to one slave device.

## Other scripts:

The leashhandle script can be dropped in the linked prim of a leash holder that should be the anchor for the leash particles.

The furniture script can be dropped in furniture for objectification needs.