# simpleAuras


<img width="508" height="322" alt="image" src="https://github.com/user-attachments/assets/15338563-4fbd-454c-9609-3d95f0214cc0" />


## Known Issues
Learning, Duration and icon display is bugged at the moment, it doesn't properly track them.
please use my casts only for now till i have the time to fix it (sorry - a lot going on at work irl atm).


## Console Commands:
/sa or /sa show or /sa hide - Show/hide simpleAuras Settings

/sa refresh X - Set refresh rate. (1 to 10 updates per second. Default: 5)

### SuperWoW commands:
/sa update X - force aura durations updates (1 = learn aura durations. Default: 0)

/sa learn X Y - manually set duration Y of spellID X cast by current target.

/sa showlearned X - shows new AuraDurations learned in chat (1 = show. Default: 0)

/sa delete 1 - Delete all learned AuraDurations of your target (or use 'all' instead of 1 to delete all durations).


## Settings (/sa)
<img width="814" height="600" alt="image" src="https://github.com/user-attachments/assets/8f27947f-8477-41ec-8507-e41ec7af0008" />


### Overview
Shows all existing auras.

- [+] / Add Aura: Creates a new, blank aura.
- [i] / Import: Opens a window to import one or multiple auras from a text string.
- [e] / Export: Exports all your auras into a single text string.
- v / ^: Sort aura priority (higher in the list = will be shown over other auras below)
- Movable Auras: While in settings, you can move any visible aura by holding down `Ctrl`+`Alt`+`Shift` keys and dragging it.


### Aura-Editor
Shows the currently edited aura only.

Enabled/Disabled:
- A master toggle at the top of the editor to quickly turn an aura on or off. Disabled auras are highlighted in red in the main list.

My Casts only:
- Only tracks your own casts of edited aura.

Aura/Spellname Name:
- Name of the aura to track (has to be exactly the same name)


Icon/Texture:
- Color: Basecolor of the aura.
- Autodetect: Gets icon from buff.
- Browse: Choose a texture.
- Scale: Basescale of 1 is 48x48px.
- x/y pos: Position from center of the screen.
- Show Duration*/Stacks*: Shows Duration in the center of the icon/texture, stacks are under that.


Conditions:
- Unit: Which unit the aura is on.
- Type: is it a buff or a debuff.
- Low Duration Color*: If the auracolor should change at or below "lowduration"
- Low Duration in secs*: Allways active, changes durationcolor to red if at or below, also changes color if activated.
- In/Out of Combat: When aura should be shown
- In Raid / In Party: Restricts the aura to only be active when you are in a raid or party (but not a raid).

Buff/Debuff:
- Invert: Activate to show aura if not found.
- Dual: Mirrors the aura (if xpos = -150, then it will show a mirrored icon/texture at xpos 150).

Cooldown:
- Always: Shows Cooldown Icon if it's on CD or not.
- No CD: Show when not on CD.
- CD: Show when on CD.


Other:
- [c] / Copy: Copies the aura.
- [e] / Export: Exports only the current aura into a text string.
- Delete: Deletes the aura after confirmation.

\* = For these functions to work on targets SuperWoW is REQUIRED!


## SuperWoW Features
If SuperWoW is installed, simpleAuras will automatically learn unkown durations of most of **your own** auras with the first cast (needs to run out to be accurate).

Some Spells aren't properly tracked because they use different names during apply and fade or don't trigger the event used to track them (Enlighten -> Enlightened and Weakened Soul for example).

In those cases, use "/sa learn X Y" to manually set duration Y for aura with ID X.

## Special Thanks / Credits
- Torio ([SuperCleveRoidMacros](https://github.com/jrc13245/SuperCleveRoidMacros))
- [MPOWA](https://github.com/MarcelineVQ/ModifiedPowerAuras) (Textures)
