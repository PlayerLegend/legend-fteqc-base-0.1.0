/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
/*
    custom-globals.qc<server_qc>

    Definitions used by this codebase, like fteextensions.qc
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


//
//    global arrays
//

struct {
  entity_array_t single;
  entity_array_t coop;
  entity_array_t deathmatch;
  entity_array_t all;
} g_spawns;

//
//    weapons
//

struct weapon_object{
  int id;
  string name;
  string model;
  int max_ammo;

  int target_slot;

  bool( entity holder ) wield;
  bool( entity holder ) begin;
  bool( entity holder ) frame;
  void( entity holder ) end;
  bool( entity holder ) holster;
};

.bool weapon_frame_active;
.float next_weapon_impulse;

typedef struct weapon_object weapon_object_t;

#define NULL_weapon_object_t (weapon_object_t){ 0, "NULL_WEAPON", 0, 0, 0, __NULL__, __NULL__, __NULL__, __NULL__, __NULL__ }

struct weapon_info{
  entity owner;
  weapon_object_t * weapon;
  int time_when_ready;
};

typedef struct weapon_info weapon_info_t;

.weapon_info_t * current_weapon_info;

#define NULL_weapon_info_t (weapon_info_t){ world, __NULL__, 0, 0 }

void_array_t g_weapon_objects_array;
.void_array_t held_weapons;
.int current_weapon_slot;

enum
  {
    WEAPONID__AXE,
    WEAPONID__SHOTGUN,
    MAX_WEAPONID,
  };

.string weaponmodel; // doesn't do anything in CSQC, but it's here so the common_qc code compiles

//
//    Buttons
//

.float held_buttons;
.float released_buttons;
.float pressed_buttons;
