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

struct weapon_cli_t
{
  entity holder;
  struct weapon_def_t * weapon;
  float time_when_ready;
};

struct weapon_def_t
{
  string name;
  string model;
  int max_ammo;

  int target_slot;

  bool( weapon_cli_t * cli ) wield;
  bool( weapon_cli_t * cli ) begin;
  bool( weapon_cli_t * cli ) frame;
  void( weapon_cli_t * cli ) end;
  bool( weapon_cli_t * cli ) holster;
};

.bool weapon_frame_held;
.bool weapon_frame_active;
.float next_weapon_impulse;

.weapon_cli_t * current_weapon_cli;
.weapon_def_t * current_weapon_def;

.void_array_t held_weapons;
.int current_weapon_slot;

.string weaponmodel; // doesn't do anything in CSQC, but it's here so the common_qc code compiles

//
//    Buttons
//

.float held_buttons;
.float released_buttons;
.float pressed_buttons;

//
//    Damage
//

.void( damage_info_t * killing_damage ) die;
.void( damage_info_t * pain_damage ) pain;

struct
{
  int count;
  int alloc;
  damage_info_t * data;
}
  g_collect_damage_array;

//
//    Gamemode
//

float deathmatch;
float coop;
