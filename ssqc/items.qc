float (entity Retriever, float AmmoType) TeamFortress_GetMaxAmmo;
float (entity Retriever, float WeaponType) TeamFortress_CanGetWeapon;
void (entity Retriever, entity Items) TeamFortress_AddBackpackItems;
float IsFeigned(entity ent);

void (entity p) TeamFortress_SetSpeed;

void () tfgoal_touch;

void () SUB_regen = {
    self.model = self.mdl;
    self.solid = SOLID_TRIGGER;
    FO_Sound(self, CHAN_VOICE, "items/itembk2.wav", 1, ATTN_NORM);
    setorigin(self, self.origin);
};

void () noclass = {
    dprint("noclass spawned at");
    dprint(vtos(self.origin));
    dprint("\n");
    remove(self);
};

void () q_touch = {
    local string s;

    if (other.classname != "player")
        return;

    if (other.health <= 0)
        return;

    self.mdl = self.model;
    FO_Sound(other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd(other, "bf\n");
    self.solid = SOLID_NOT;
    other.items = other.items | IT_QUAD;
    self.model = string_null;
    other.super_time = 1;
    other.super_damage_finished = self.cnt;
    s = ftos(rint(other.super_damage_finished - time));
    bprint(PRINT_LOW, other.netname, " recovered a Quad with ", s,
           " seconds remaining!\n");
    activator = other;
    SUB_UseTargets();
};

void (float timeleft) DropQuad = {
    local entity item;

    item = spawn();
    item.origin = self.origin - '0 0 24';
    item.velocity_z = 300;
    item.velocity_x = -100 + random() * 200;
    item.velocity_y = -100 + random() * 200;
    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    item.noise = "items/damage.wav";
    FO_SetModel(item, "progs/quaddama.mdl");
    setsize(item, VEC_HULL_MIN, VEC_HULL_MAX);
    item.cnt = time + timeleft;
    item.touch = q_touch;
    item.nextthink = time + timeleft;
    item.think = SUB_Remove;
};

void () r_touch = {
    local string s;

    if (other.classname != "player")
        return;

    if (other.health <= 0)
        return;

    self.mdl = self.model;
    FO_Sound(other, CHAN_VOICE, self.noise, 1, ATTN_NORM);
    stuffcmd(other, "bf\n");
    self.solid = 0;
    other.items = other.items | IT_INVISIBILITY;
    self.model = string_null;
    other.invisible_time = 1;
    other.invisible_finished = self.cnt;
    s = ftos(rint(other.invisible_finished - time));
    bprint(PRINT_LOW, other.netname, " recovered a Ring with ", s,
           " seconds remaining!\n");
    activator = other;
    SUB_UseTargets();
};

void (float timeleft) DropRing = {
    local entity item;

    item = spawn();
    item.origin = self.origin - '0 0 24';
    item.velocity_z = 300;
    item.velocity_x = -100 + random() * 200;
    item.velocity_y = -100 + random() * 200;
    item.flags = FL_ITEM;
    item.solid = SOLID_TRIGGER;
    item.movetype = MOVETYPE_TOSS;
    item.noise = "items/inv1.wav";
    FO_SetModel(item, "progs/invisibl.mdl");
    setsize(item, VEC_HULL_MIN, VEC_HULL_MAX);
    item.cnt = time + timeleft;
    item.touch = r_touch;
    item.nextthink = time + timeleft;
    item.think = SUB_Remove;
};

void () PlaceItem = {
    local float oldz;

    self.mdl = self.model;
    self.flags = FL_ITEM;
    self.solid = SOLID_TRIGGER;
    self.movetype = MOVETYPE_TOSS;
    self.velocity = '0 0 0';
    self.origin_z = self.origin_z + 6;
    oldz = self.origin_z;

    if (!droptofloor()) {
        dprint("Bonus item fell out of level at ");
        dprint(vtos(self.origin));
        dprint("\n");
        dremove(self);
        return;
    }
};

void () StartItem = {
    self.nextthink = time + 0.2;
    self.think = PlaceItem;
};

float (entity e, float healamount, float ignore) T_Heal = {
    if (e.health <= 0)
        return (0);

    if (!ignore && (e.health >= e.max_health)) {

        if (e.leg_damage) {
            e.leg_damage = e.leg_damage - ceil(e.health / 20);
            if (e.leg_damage < 1)
                e.leg_damage = 0;

            TeamFortress_SetSpeed(e);
            return (1);
        } else
            return (0);
    }
    healamount = ceil(healamount);
    e.health = e.health + healamount;

    if (!ignore && (e.health >= e.max_health))
        e.health = e.max_health;

    if (e.health > 250)
        e.health = 250;

    if (e.leg_damage) {

        if (e.health > 95)
            e.leg_damage = 0;
        else
            e.leg_damage = e.leg_damage - ceil((e.health / 20));

        if (e.leg_damage < 1)
            e.leg_damage = 0;

        TeamFortress_SetSpeed(e);
    }
    return (1);
};

#define H_ROTTEN	1
#define H_MEGA		2

.float healamount, healtype;

void () health_touch;
void () item_megahealth_rot;

void () item_health = {
    if (CheckExistence() == FALSE) {
        dremove(self);
        return;
    }
    self.touch = health_touch;
    if (self.spawnflags & H_ROTTEN) {
        precache_model("maps/b_bh10.bsp");
        precache_sound("items/r_item1.wav");
        FO_SetModel(self, "maps/b_bh10.bsp");
        self.noise = "items/r_item1.wav";
        self.healamount = 15;
        self.healtype = 0;
    } else if (self.spawnflags & H_MEGA) {
        precache_model("maps/b_bh100.bsp");
        precache_sound("items/r_item2.wav");
        FO_SetModel(self, "maps/b_bh100.bsp");
        self.noise = "items/r_item2.wav";
        self.healamount = 100;
        self.healtype = 2;
    } else {
        precache_model("maps/b_bh25.bsp");
        precache_sound("items/health1.wav");
        FO_SetModel(self, "maps/b_bh25.bsp");
        self.noise = "items/health1.wav";
        self.healamount = 25;
        self.healtype = 1;
    }
    setsize(self, '0 0 0', '32 32 56');
    StartItem();
};

void () health_touch = {
    local float medi;
    local string s;

    if (other.classname != "player")
        return;
    if (IsFeigned(other))
        return;
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING))
        return;
    if (cb_prematch == 1)
        return;
    medi = 0;
    if (self.healtype == 2) {
        if (!(other.tfstate & 16)) {
            if (other.health >= 250) {
                return;
            }
            if (!T_Heal(other, self.healamount, 1)) {
                return;
            }
        }
    } else {
        if (!T_Heal(other, self.healamount, 0)) {
            if (FO_WeaponsMask(other) & WEAP_MEDIKIT) {
                if (other.ammo_medikit < other.maxammo_medikit) {
                    other.ammo_medikit =
                        other.ammo_medikit + self.healamount;
                    if (other.ammo_medikit > other.maxammo_medikit) {
                        other.ammo_medikit = other.maxammo_medikit;
                    }
                    s = ftos(self.healamount);
                    sprint(other, PRINT_LOW, "You gather ", s,
                           " medikit ammo\n");
                    FO_Sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
                    stuffcmd(other, "bf\n");
                    self.model = string_null;
                    self.solid = 0;
                    if (deathmatch != 2) {
                        if (deathmatch) {
                            self.nextthink = time + 20;
                        }
                        self.think = SUB_regen;
                    }
                    activator = other;
                    SUB_UseTargets();
                }
            }
            return;
        }
    }
    if ((other.tfstate & 16) && (self.healamount > 80)) {
        sprint(other, PRINT_MEDIUM,
               "You have been healed of your infection");
        other.tfstate = other.tfstate - (other.tfstate & 16);
    } else {
        s = ftos(self.healamount);
        sprint(other, PRINT_LOW, "You receive ", s, " health\n");
    }
    FO_Sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd(other, "bf\n");
    self.model = string_null;
    self.solid = 0;
    if (self.healtype == 2) {
        other.items = other.items | IT_SUPERHEALTH;
        self.nextthink = time + 5;
        self.think = item_megahealth_rot;
        self.owner = other;
    } else if (deathmatch != 2) {
        if (deathmatch)
            self.nextthink = time + 20;
        self.think = SUB_regen;
    }
    activator = other;
    SUB_UseTargets();
};

void () item_megahealth_rot = {
    other = self.owner;
    if (other.health > other.max_health) {
        other.health = other.health - 1;
        self.nextthink = time + 1;
        return;
    }
    other.items = other.items - (other.items & IT_SUPERHEALTH);
    if (self.classname == "medikit_rot") {
        dremove(self);
        return;
    }
    if (deathmatch != 2) {
        self.nextthink = time + 20;
        self.think = SUB_regen;
    }
};

void () armor_touch = {
    local float type;
    local float value;
    local float bit;
    local string s;

    if (other.health <= 0)
        return;
    if (other.classname != "player")
        return;
    if (IsFeigned(other))
        return;
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING))
        return;
    if (cb_prematch == 1)
        return;
    if (self.classname == "item_armor1") {
        type = 0.300;
        value = 100;
        bit = IT_ARMOR1;
    } else {
        if (self.classname == "item_armor2") {
            type = 0.600;
            value = 150;
            bit = IT_ARMOR2;
        } else {
            type = 0.800;
            value = 200;
            bit = IT_ARMOR3;
        }
    }
    if ((other.armortype * other.armorvalue) >= (type * value)) {
        if (other.playerclass == 9) {
            if (other.ammo_cells >= other.maxammo_cells) {
                return;
            }
        } else {
            return;
        }
    }
    if ((other.armor_allowed * other.maxarmor) <= (type * value)) {
        if (other.armor_allowed == other.armortype) {
            if (other.maxarmor == other.armorvalue) {
                if (other.playerclass == 9) {
                    if (other.ammo_cells >= other.maxammo_cells) {
                        return;
                    }
                } else {
                    return;
                }
            }
        }
    }
    if (type > other.armor_allowed) {
        type = other.armor_allowed;
        if (type == 0.300) {
            bit = 8192;
        } else {
            if (type == 0.600) {
                bit = 16384;
            } else {
                if (type == 0.800) {
                    bit = 32768;
                }
            }
        }
    }
    sprint(other, PRINT_LOW, "You got armor\n");
    if (value > other.maxarmor) {
        if ((other.playerclass == 9) &&
            (other.ammo_cells < other.maxammo_cells)) {
            s = ftos((value - other.maxarmor));
            sprint(other, PRINT_LOW, s, " metal\n");
            other.ammo_cells = other.ammo_cells + (value - other.maxarmor);
            if (other.ammo_cells > other.maxammo_cells) {
                other.ammo_cells = other.maxammo_cells;
            }
        }
        value = other.maxarmor;
    }
    if ((other.armortype * other.armorvalue) < (type * value)) {
        other.armortype = type;
        other.armorvalue = value;
        other.items =
            (other.items - (other.items & ((IT_ARMOR1 | IT_ARMOR2) | IT_ARMOR3))) + bit;
    }
    if (self.armorclass > 0) {
        other.armorclass = self.armorclass;
    }
    self.solid = 0;
    self.model = string_null;
    if (deathmatch != 2) {
        self.nextthink = time + 20;
    }
    if (coop) {
        self.nextthink = time + 40;
    }
    self.think = SUB_regen;
    FO_Sound(other, CHAN_ITEM, "items/armor1.wav", 1, 1);
    stuffcmd(other, "bf\n");
    activator = other;
    SUB_UseTargets();
}

void () item_armor1 = {
    if (CheckExistence() == FALSE) {
        dremove(self);
        return;
    }
    self.touch = armor_touch;
    precache_model("progs/armor.mdl");
    FO_SetModel(self, "progs/armor.mdl");
    self.skin = 0;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () item_armor2 = {
    if (CheckExistence() == FALSE) {
        dremove(self);
        return;
    }
    self.touch = armor_touch;
    precache_model("progs/armor.mdl");
    FO_SetModel(self, "progs/armor.mdl");
    self.skin = 1;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () item_armorInv = {
    if (CheckExistence() == FALSE) {
        dremove(self);
        return;
    }
    self.touch = armor_touch;
    precache_model("progs/armor.mdl");
    FO_SetModel(self, "progs/armor.mdl");
    self.skin = 2;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void (entity p) bound_other_ammo = {
    if (p.ammo_shells > TeamFortress_GetMaxAmmo(p, 256)) {
        p.ammo_shells = TeamFortress_GetMaxAmmo(p, 256);
    }
    if (p.ammo_nails > TeamFortress_GetMaxAmmo(p, 512)) {
        p.ammo_nails = TeamFortress_GetMaxAmmo(p, 512);
    }
    if (p.ammo_rockets > TeamFortress_GetMaxAmmo(p, 1024)) {
        p.ammo_rockets = TeamFortress_GetMaxAmmo(p, 1024);
    }
    if (p.ammo_cells > TeamFortress_GetMaxAmmo(p, 2048)) {
        p.ammo_cells = TeamFortress_GetMaxAmmo(p, 2048);
    }
    if (p.ammo_medikit > p.maxammo_medikit) {
        p.ammo_medikit = p.maxammo_medikit;
    }
    if (p.armorvalue > p.maxarmor) {
        p.armorvalue = p.maxarmor;
    }
    if (p.no_grenades_1 > p.max_grenades_1) {
        p.no_grenades_1 = p.max_grenades_1;
    }
    if (p.no_grenades_2 > p.max_grenades_2) {
        p.no_grenades_2 = p.max_grenades_2;
    }
};

float (float w) RankForWeapon = {
    if (w == WEAP_LIGHTNING)
        return 1;
    if (w == WEAP_ROCKET_LAUNCHER)
        return 2;
    if (w == WEAP_SUPER_NAILGUN)
        return 3;
    if (w == WEAP_GRENADE_LAUNCHER)
        return 4;
    if (w == WEAP_SUPER_SHOTGUN)
        return 5;
    if (w == WEAP_NAILGUN)
        return 6;
    return 7;
};

void () ammo_touch;

void (entity ritem, entity act) Respawn_Item = {
    local entity oldself;

    oldself = self;
    self = ritem;
    self.model = string_null;
    self.solid = 0;

    if (deathmatch != 2)
        self.nextthink = time + 30;
    else if (coop && (ritem.touch == ammo_touch))
        self.nextthink = time + 45;

    self.think = SUB_regen;
    activator = act;
    SUB_UseTargets();
    self = oldself;
};

void () weapon_touch = {
    local float hadammo;
    local float new;
    local float old;
    local float leave;
    float other_weapons_carried = FO_WeaponsMask(other);
    new = 0;

    if (!(other.flags & 8))
        return;
    if (IsFeigned(other))
        return;
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING))
        return;
    if (cb_prematch == 1)
        return;

    if ((deathmatch == 2) || coop) {
        leave = 1;
    } else {
        leave = 0;
    }
    if (self.classname == "weapon_nailgun") {
        if (leave && (other_weapons_carried & WEAP_NAILGUN)) {
            return;
        }
        if (!TeamFortress_CanGetWeapon(other, WEAP_NAILGUN)) {
            return;
        }
        hadammo = other.ammo_nails;
        new = WEAP_NAILGUN;
        other.ammo_nails = other.ammo_nails + 30;
    } else {
        if (self.classname == "weapon_supernailgun") {
            if (leave && (other_weapons_carried & WEAP_SUPER_NAILGUN)) {
                return;
            }
            if (!TeamFortress_CanGetWeapon(other, WEAP_SUPER_NAILGUN)) {
                return;
            }
            hadammo = other.ammo_rockets;
            new = WEAP_SUPER_NAILGUN;
            other.ammo_nails = other.ammo_nails + 30;
        } else {
            if (self.classname == "weapon_supershotgun") {
                if (leave && (other_weapons_carried & WEAP_SUPER_SHOTGUN)) {
                    return;
                }
                if (!TeamFortress_CanGetWeapon(other, WEAP_SUPER_SHOTGUN)) {
                    return;
                }
                hadammo = other.ammo_rockets;
                new = WEAP_SUPER_SHOTGUN;
                other.ammo_shells = other.ammo_shells + 5;
            } else {
                if (self.classname == "weapon_rocketlauncher") {
                    if (leave && (other_weapons_carried & WEAP_ROCKET_LAUNCHER)) {
                        return;
                    }
                    if (!TeamFortress_CanGetWeapon(other, WEAP_ROCKET_LAUNCHER)) {
                        return;
                    }
                    hadammo = other.ammo_rockets;
                    new = WEAP_ROCKET_LAUNCHER;
                    other.ammo_rockets = other.ammo_rockets + 5;
                } else {
                    if (self.classname == "weapon_grenadelauncher") {
                        if (leave && (other_weapons_carried & WEAP_GRENADE_LAUNCHER)) {
                            return;
                        }
                        if (!TeamFortress_CanGetWeapon(other, WEAP_GRENADE_LAUNCHER)) {
                            return;
                        }
                        hadammo = other.ammo_rockets;
                        new = WEAP_GRENADE_LAUNCHER;
                        other.ammo_rockets = other.ammo_rockets + 5;
                    } else {
                        if (self.classname == "weapon_lightning") {
                            if (leave && (other_weapons_carried & WEAP_LIGHTNING)) {
                                return;
                            }
                            if (!TeamFortress_CanGetWeapon(other, WEAP_LIGHTNING)) {
                                return;
                            }
                            hadammo = other.ammo_rockets;
                            new = WEAP_LIGHTNING;
                            other.ammo_cells = other.ammo_cells + 15;
                        } else {
                            objerror("weapon_touch: unknown classname");
                        }
                    }
                }
            }
        }
    }
    sprint(other, PRINT_LOW, "You got the ", self.netname, "\n");
    FO_Sound(other, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    stuffcmd(other, "bf\n");
    bound_other_ammo(other);
    if (leave)
        return;
    Respawn_Item(self, other);
};

void () weapon_supershotgun = {
    if (CheckExistence() == FALSE) {
        dremove(self);
        return;
    }
    precache_model("progs/g_shot.mdl");
    FO_SetModel(self, "progs/g_shot.mdl");
    self.weapon = WEAP_SUPER_SHOTGUN;
    self.netname = "Double-barrelled Shotgun";
    self.touch = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () weapon_nailgun = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    precache_model("progs/g_nail.mdl");
    FO_SetModel(self, "progs/g_nail.mdl");
    self.weapon = 512;
    self.netname = "nailgun";
    self.touch = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () weapon_supernailgun = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    precache_model("progs/g_nail2.mdl");
    FO_SetModel(self, "progs/g_nail2.mdl");
    self.weapon = 1024;
    self.netname = "Super Nailgun";
    self.touch = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () weapon_grenadelauncher = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    precache_model("progs/g_rock.mdl");
    FO_SetModel(self, "progs/g_rock.mdl");
    self.weapon = 3;
    self.netname = "Grenade Launcher";
    self.touch = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () weapon_rocketlauncher = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    precache_model("progs/g_rock2.mdl");
    FO_SetModel(self, "progs/g_rock2.mdl");
    self.weapon = 3;
    self.netname = "Rocket Launcher";
    self.touch = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void () weapon_lightning = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    precache_model("progs/g_light.mdl");
    FO_SetModel(self, "progs/g_light.mdl");
    self.weapon = 3;
    self.netname = "Thunderbolt";
    self.touch = weapon_touch;
    setsize(self, '-16 -16 0', '16 16 56');
    StartItem();
};

void (entity pe_player, float pf_grenade_type, float pf_grenade_count) PrintFoundGrenade = {
    if (!pf_grenade_count)
        return;

    string buf = sprintf("You found %s%s %s%s\n",
            pf_grenade_count > 1 ? " " : "a ",
            FO_GrenDesc(pf_grenade_type)->name,
            pf_grenade_type == GREN_CALTROP ? "cannister" : "grenade",
            pf_grenade_count > 1 ? "s" : "");
    sprint(pe_player, PRINT_HIGH, buf);
};

float () GetGrenadePossibility = {
    if (random() < 0.500)
        return 0;

    float index = -1;
    switch (disable_resup_gren) {
        case 0: index = random() < 0.5 ? 0 : 1; break;
        case 1: index = 1; break;
        case 2: index = 0; break;
        default:
                return 0;
    }

    FO_GrenInfo* gt = FO_PlayerGren(other, index);
    if (gt->id == GREN_NONE)
        return 0;

    if (index == 0 && other.no_grenades_1 < other.max_grenades_1)
        other.no_grenades_1 += 1;
    else if (index == 1 && other.no_grenades_2 < other.max_grenades_2)
        other.no_grenades_2 += 1;
    else
        return 0;

    PrintFoundGrenade(other, gt->id, 1);
    return 1;
}

void () ammo_touch = {
    local float gotgren;
    local float gotbox;

    if (other.classname != "player") {
        return;
    }
    if (other.health <= 0) {
        return;
    }
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING)) {
        return;
    }
    if (cb_prematch == 1) {
        return;
    }
    gotgren = 0;
    gotbox = 0;
    if (self.weapon == 1) {
        if (other.ammo_shells >= TeamFortress_GetMaxAmmo(other, 256)) {
            return;
        }
        other.ammo_shells = other.ammo_shells + self.aflag;
        gotbox = 1;
    }
    if (self.weapon == 2) {
        if (other.ammo_nails >= TeamFortress_GetMaxAmmo(other, 512)) {
            return;
        }
        other.ammo_nails = other.ammo_nails + self.aflag;
        gotbox = 1;
    } else {
        if (self.weapon == 3) {
            gotgren = GetGrenadePossibility();
            if (other.ammo_rockets >= TeamFortress_GetMaxAmmo(other, 1024)) {
                gotbox = 0;
            } else {
                gotbox = 1;
                other.ammo_rockets = other.ammo_rockets + self.aflag;
            }
        } else {
            if (self.weapon == 4) {
                if (other.ammo_cells >=
                    TeamFortress_GetMaxAmmo(other, 2048)) {
                    return;
                }
                other.ammo_cells = other.ammo_cells + self.aflag;
                gotbox = 1;
            }
        }
    }
    if (!gotbox && !gotgren) {
        return;
    }
    FO_Sound(other, CHAN_ITEM, "weapons/lock4.wav", 1, 1);
    stuffcmd(other, "bf\n");
    if (gotbox) {
        bound_other_ammo(other);
        sprint(other, PRINT_LOW, "You got the ", self.netname, "\n");
    }
    Respawn_Item(self, other);
};

void () item_shells = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = ammo_touch;
    if (self.spawnflags & 1) {
        precache_model("maps/b_shell1.bsp");
        FO_SetModel(self, "maps/b_shell1.bsp");
        self.aflag = 40;
    } else {
        precache_model("maps/b_shell0.bsp");
        FO_SetModel(self, "maps/b_shell0.bsp");
        self.aflag = 20;
    }
    self.weapon = 1;
    self.netname = "shells";
    setsize(self, '0 0 0', '32 32 56');
    StartItem();
};

void () item_spikes = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = ammo_touch;
    if (self.spawnflags & 1) {
        precache_model("maps/b_nail1.bsp");
        FO_SetModel(self, "maps/b_nail1.bsp");
        self.aflag = 50;
    } else {
        precache_model("maps/b_nail0.bsp");
        FO_SetModel(self, "maps/b_nail0.bsp");
        self.aflag = 25;
    }
    self.weapon = 2;
    self.netname = "nails";
    setsize(self, '0 0 0', '32 32 56');
    StartItem();
};

void () item_rockets = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = ammo_touch;
    if (self.spawnflags & 1) {
        precache_model("maps/b_rock1.bsp");
        FO_SetModel(self, "maps/b_rock1.bsp");
        self.aflag = 10;
    } else {
        precache_model("maps/b_rock0.bsp");
        FO_SetModel(self, "maps/b_rock0.bsp");
        self.aflag = 5;
    }
    self.weapon = 3;
    self.netname = "rockets";
    setsize(self, '0 0 0', '32 32 56');
    StartItem();
};

void () item_cells = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = ammo_touch;
    if (self.spawnflags & 1) {
        precache_model("maps/b_batt1.bsp");
        FO_SetModel(self, "maps/b_batt1.bsp");
        self.aflag = 12;
    } else {
        precache_model("maps/b_batt0.bsp");
        FO_SetModel(self, "maps/b_batt0.bsp");
        self.aflag = 6;
    }
    self.weapon = 4;
    self.netname = "cells";
    setsize(self, '0 0 0', '32 32 56');
    StartItem();
};

void () item_weapon = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = ammo_touch;
    if (self.spawnflags & 1) {
        if (self.spawnflags & 8) {
            precache_model("maps/b_shell1.bsp");
            FO_SetModel(self, "maps/b_shell1.bsp");
            self.aflag = 40;
        } else {
            precache_model("maps/b_shell0.bsp");
            FO_SetModel(self, "maps/b_shell0.bsp");
            self.aflag = 20;
        }
        self.weapon = 1;
        self.netname = "shells";
    }
    if (self.spawnflags & 4) {
        if (self.spawnflags & 8) {
            precache_model("maps/b_nail1.bsp");
            FO_SetModel(self, "maps/b_nail1.bsp");
            self.aflag = 40;
        } else {
            precache_model("maps/b_nail0.bsp");
            FO_SetModel(self, "maps/b_nail0.bsp");
            self.aflag = 20;
        }
        self.weapon = 2;
        self.netname = "spikes";
    }
    if (self.spawnflags & 2) {
        if (self.spawnflags & 8) {
            precache_model("maps/b_rock1.bsp");
            FO_SetModel(self, "maps/b_rock1.bsp");
            self.aflag = 10;
        } else {
            precache_model("maps/b_rock0.bsp");
            FO_SetModel(self, "maps/b_rock0.bsp");
            self.aflag = 5;
        }
        self.weapon = 3;
        self.netname = "rockets";
    }
    setsize(self, '0 0 0', '32 32 56');
    StartItem();
};

void () key_touch = {
    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;
    if (other.items & self.items)
        return;
    if (IsFeigned(other))
        return;
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING))
        return;
    if (cb_prematch == 1)
        return;
    sprint(other, PRINT_LOW, "You got the ", self.netname, "\n");
    FO_Sound(other, CHAN_ITEM, self.noise, 1, 1);
    stuffcmd(other, "bf\n");
    other.items = other.items | self.items;
    if (!coop) {
        self.solid = 0;
        self.model = string_null;
    } else {
        if (coop && self.deadflag) {
            dremove(self);
            return;
        }
    }
    activator = other;
    SUB_UseTargets();
};

void () key_setsounds = {
    if (world.worldtype == 0) {
        precache_sound("misc/medkey.wav");
        self.noise = "misc/medkey.wav";
    }
    if (world.worldtype == 1) {
        precache_sound("misc/runekey.wav");
        self.noise = "misc/runekey.wav";
    }
    if (world.worldtype == 2) {
        precache_sound2("misc/basekey.wav");
        self.noise = "misc/basekey.wav";
    }
};

void () item_key1 = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    if (world.worldtype == 0) {
        precache_model("progs/w_s_key.mdl");
        FO_SetModel(self, "progs/w_s_key.mdl");
        self.netname = "silver key";
    } else {
        if (world.worldtype == 1) {
            precache_model("progs/m_s_key.mdl");
            FO_SetModel(self, "progs/m_s_key.mdl");
            self.netname = "silver runekey";
        } else {
            if (world.worldtype == 2) {
                precache_model2("progs/b_s_key.mdl");
                FO_SetModel(self, "progs/b_s_key.mdl");
                self.netname = "silver keycard";
            }
        }
    }
    key_setsounds();
    self.touch = key_touch;
    self.items = IT_KEY1;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    StartItem();
};

void () item_key2 = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    if (world.worldtype == 0) {
        precache_model("progs/w_g_key.mdl");
        FO_SetModel(self, "progs/w_g_key.mdl");
        self.netname = "gold key";
    }
    if (world.worldtype == 1) {
        precache_model("progs/m_g_key.mdl");
        FO_SetModel(self, "progs/m_g_key.mdl");
        self.netname = "gold runekey";
    }
    if (world.worldtype == 2) {
        precache_model2("progs/b_g_key.mdl");
        FO_SetModel(self, "progs/b_g_key.mdl");
        self.netname = "gold keycard";
    }
    key_setsounds();
    self.touch = key_touch;
    self.items = IT_KEY2;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    StartItem();
};

void () sigil_touch = {
    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;
    if (IsFeigned(other))
        return;
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING))
        return;
    if (cb_prematch == 1)
        return;

    FO_Sound(other, CHAN_ITEM, self.noise, 1, ATTN_NORM);
    stuffcmd(other, "bf\n");
    self.solid = SOLID_NOT;
    self.model = string_null;
    serverflags = serverflags | (self.spawnflags & 15);
    self.classname = "";
    activator = other;
    SUB_UseTargets();
};

void () powerup_touch = {
    if (other.classname != "player")
        return;
    if (other.health <= 0)
        return;
    if (IsFeigned(other))
        return;
    if ((other.tfstate & TFSTATE_CANT_MOVE) || (other.tfstate & TFSTATE_AIMING))
        return;
    if (cb_prematch == 1)
        return;

    sprint(other, PRINT_LOW, "You got the ");
    sprint(other, PRINT_LOW, self.netname);
    sprint(other, PRINT_LOW, "\n");
    if (deathmatch) {
        self.mdl = self.model;
        if ((self.classname == "item_artifact_invulnerability")
            || (self.classname == "item_artifact_invisibility"))
            self.nextthink = time + 60 * 5;
        else
            self.nextthink = time + 60;
        self.think = SUB_regen;
    } else {
        if (coop) {
            self.mdl = self.model;
            if ((self.classname == "item_artifact_invulnerability")
                || (self.classname == "item_artifact_invisibility"))
                self.nextthink = time + 120 * 5;
            else
                self.nextthink = time + 120;
            self.think = SUB_regen;
        }
    }
    FO_Sound(other, CHAN_VOICE, self.noise, 1, 1);
    stuffcmd(other, "bf\n");
    self.solid = 0;
    other.items = other.items | self.items;
    self.model = string_null;
    if (self.classname == "item_artifact_envirosuit") {
        other.rad_time = 1;
        other.radsuit_finished = time + 30;
    }
    if (self.classname == "item_artifact_invulnerability") {
        other.invincible_time = 1;
        other.invincible_finished = time + 30;
    }
    if (self.classname == "item_artifact_invisibility") {
        other.invisible_time = 1;
        other.invisible_finished = time + 30;
    }
    if (self.classname == "item_artifact_super_damage") {
        other.super_time = 1;
        other.super_damage_finished = time + 30;
    }
    activator = other;
    SUB_UseTargets();
};

void () item_artifact_invulnerability = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = powerup_touch;
    precache_model("progs/invulner.mdl");
    precache_sound("items/protect.wav");
    precache_sound("items/protect2.wav");
    precache_sound("items/protect3.wav");
    self.noise = "items/protect.wav";
    FO_SetModel(self, "progs/invulner.mdl");
    self.effects = self.effects | EF_RED;
    self.netname = "Pentagram of Protection";
    self.items = IT_INVULNERABILITY;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    StartItem();
};

void () item_artifact_envirosuit = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = powerup_touch;
    precache_model("progs/suit.mdl");
    precache_sound("items/suit.wav");
    precache_sound("items/suit2.wav");
    self.noise = "items/suit.wav";
    FO_SetModel(self, "progs/suit.mdl");
    self.netname = "Biosuit";
    self.items = IT_SUIT;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    StartItem();
};

void () item_artifact_invisibility = {
    if (CheckExistence() == 0) {
        dremove(self);
        return;
    }
    self.touch = powerup_touch;
    precache_model("progs/invisibl.mdl");
    precache_sound("items/inv1.wav");
    precache_sound("items/inv2.wav");
    precache_sound("items/inv3.wav");
    self.noise = "items/inv1.wav";
    FO_SetModel(self, "progs/invisibl.mdl");
    self.netname = "Ring of Shadows";
    self.items = IT_INVISIBILITY;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    StartItem();
};

void () item_artifact_super_damage = {
    if (CheckExistence() == FALSE) {
        dremove(self);
        return;
    }
    self.touch = powerup_touch;
    precache_model("progs/quaddama.mdl");
    precache_sound("items/damage.wav");
    precache_sound("items/damage2.wav");
    precache_sound("items/damage3.wav");
    self.noise = "items/damage.wav";
    FO_SetModel(self, "progs/quaddama.mdl");
    self.effects = self.effects | EF_BLUE;
    self.netname = "Quad Damage";
    self.items = IT_QUAD;
    setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
    StartItem();
};

void () BackpackTouch = {
    local string s;
    local float maxg, giveg;

    if (other.classname != "player" || IsFeigned(other))
        return;
    if (other.health <= 0)
        return;
    if (other.button0)
        return;

    other.ammo_shells = other.ammo_shells + self.ammo_shells;
    other.ammo_nails = other.ammo_nails + self.ammo_nails;
    other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
    other.ammo_cells = other.ammo_cells + self.ammo_cells;
    if (drop_grenpack && other.playerclass != PC_SCOUT) {

        // give grenade type 1
        maxg = other.max_grenades_1;
        if ((other.no_grenades_1 + self.no_grenades_1) >= maxg)
            giveg = maxg - other.no_grenades_1;
        else
            giveg = self.no_grenades_1;
        other.no_grenades_1 = other.no_grenades_1 + giveg;
        PrintFoundGrenade(other, FO_PlayerGren(other, 0)->id, giveg);

        // give grenade type 2
        maxg = other.max_grenades_2;
        if ((other.no_grenades_2 + self.no_grenades_2) >= maxg)
            giveg = maxg - other.no_grenades_2;
        else
            giveg = self.no_grenades_2;
        other.no_grenades_2 = other.no_grenades_2 + giveg;
        PrintFoundGrenade(other, FO_PlayerGren(other, 1)->id, giveg);

    }
    bound_other_ammo(other);
    sprint(other, PRINT_LOW, "You get ");
    if (self.ammo_shells) {
        s = ftos(self.ammo_shells);
        sprint(other, PRINT_LOW, s, " shells  ");
    }
    if (self.ammo_nails) {
        s = ftos(self.ammo_nails);
        sprint(other, PRINT_LOW, s, " nails ");
    }
    if (self.ammo_rockets) {
        s = ftos(self.ammo_rockets);
        sprint(other, PRINT_LOW, s, " rockets  ");
    }
    if (self.ammo_cells) {
        s = ftos(self.ammo_cells);
        sprint(other, PRINT_LOW, s, " cells  ");
    }
    if ((self.armorvalue && (other.playerclass == 9)) &&
        (other.ammo_cells < other.maxammo_cells) && !standardizedeathammo) {
        s = ftos(self.armorvalue);
        sprint(other, PRINT_LOW, s, " metal  ");
        other.ammo_cells = other.ammo_cells + self.armorvalue;
        if (other.ammo_cells > other.maxammo_cells) {
            other.ammo_cells = other.maxammo_cells;
        }
    }
    sprint(other, PRINT_LOW, "\n");
    FO_Sound(other, CHAN_AUTO, "weapons/lock4.wav", 1, ATTN_NORM);
    stuffcmd(other, "bf\n");
    dremove(self);
    self = other;
};

void () DropBackpack = {
    if (cb_prematch == 1)
        return;

    if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets + self.ammo_cells)) {
        if (!(drop_grenpack && (self.no_grenades_1 + self.no_grenades_2)))
            return;
    }

    newmis = spawn();
    newmis.origin = self.origin - '0 0 24';

	if(standardizedeathammo)
	{
		newmis.ammo_shells = deathammo_shells;
		newmis.ammo_nails = deathammo_nails;
		newmis.ammo_rockets = deathammo_rockets;
		newmis.ammo_cells = deathammo_cells;
	}
	else
	{
		newmis.ammo_shells = self.ammo_shells;
		newmis.ammo_nails = self.ammo_nails;
		newmis.ammo_rockets = self.ammo_rockets;
		newmis.ammo_cells = self.ammo_cells;
	}
	
    if (drop_grenpack) {
        if (drop_gren1 == -1)
            newmis.no_grenades_1 = self.no_grenades_1;
        else if (drop_gren1 > 0) {
            if (self.no_grenades_1 <= drop_gren1)
                newmis.no_grenades_1 = self.no_grenades_1;
            else
                newmis.no_grenades_1 = drop_gren1;
        }
        if (drop_gren2 == -1)
            newmis.no_grenades_2 = self.no_grenades_2;
        else if (drop_gren2 > 0) {
            if (self.no_grenades_2 <= drop_gren2)
                newmis.no_grenades_2 = self.no_grenades_2;
            else
                newmis.no_grenades_2 = drop_gren2;
        }
    }

    newmis.armorvalue = self.armorvalue;

    newmis.velocity_z = 300;
    newmis.velocity_x = -100 + random() * 200;
    newmis.velocity_y = -100 + random() * 200;

    newmis.flags = FL_ITEM;
    newmis.solid = SOLID_TRIGGER;
    newmis.movetype = MOVETYPE_TOSS;
    
	if(splitbackpackmodels)
		FO_SetModel(newmis, "progs/deathbag.mdl");
	else
		FO_SetModel(newmis, "progs/backpack.mdl");
		
    setsize(newmis, '-16 -16 0', '16 16 56');
    newmis.touch = BackpackTouch;
    newmis.classname = "backpack";

    newmis.nextthink = time + 120;
    newmis.think = SUB_Remove;
};
