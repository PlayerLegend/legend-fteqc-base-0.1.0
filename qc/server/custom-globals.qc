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

struct weapon_cli{
  entity holder;
  struct weapon_def * weapon;
  int time_when_ready;
};

typedef struct weapon_cli weapon_cli_t;

struct weapon_def{
  string name;
  string model;
  int max_ammo;

  int target_slot;

  bool( struct weapon_cli * cli ) wield;
  bool( struct weapon_cli * cli ) begin;
  bool( struct weapon_cli * cli ) frame;
  void( struct weapon_cli * cli ) end;
  bool( struct weapon_cli * cli ) holster;
};

.bool weapon_frame_active;
.float next_weapon_impulse;

typedef struct weapon_def weapon_def_t;

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
