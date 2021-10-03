/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

//
//    Quake 1 BSP hull sizes
//

const vector VEC_HULL_MIN = '-16 -16 -24';
const vector VEC_HULL_MAX = '16 16 32';

//
//    general typedefs
//

typedef float bool;

//
//    general flags
//

enum
  {
    FL_Null = 0,
    FL_1 = 1,
    FL_2 = 2,
    FL_3 = 4,
    FL_4 = 8,
    FL_5 = 16,
    FL_6 = 32,
    FL_7 = 64,
    FL_8 = 128,
  };

typedef int flags;

//
//    general time constants
//

const float TIME__SHORT = 0.05;
const float TIME__WORLD_READY = 5 * TIME__SHORT;
const float TIME__PLAYERS_READY = 7 * TIME__SHORT;

//
//    model indexes
//

float MODEL__PLAYER;
float MODEL__SOLDIER;
float MODEL__GRENADE;
float MODEL__VIEWMODEL_AXE;

//
//    sendentity
//

enum
  {
    SENDENT__PLAYER,

    PLAYER_SENDFL__FRAME_INFO = FL_1, // data that changes frequently
    PLAYER_SENDFL__SPAWN_INFO = FL_2, // data that changes infrequently
    PLAYER_SENDFL__NEW_ENT    = FL_7, // will automatically be set on new entities
  };

//
//    networked stats
//
#warning todo
enum
  {
    STAT_MIN = 25,
    STAT_ANIM_FRAME_LEN,
  };

//
//    player physics
//

struct state_phys_vars{
  float gravity;
  float stepheight;
  float friction;
  float edgefriction;
  float accelerate;
  float stopspeed;
  float maxspeed;
  float jumpspeed;
};

typedef struct state_phys_vars state_phys_vars_t;

struct phys_vars{
  state_phys_vars_t ground;
  state_phys_vars_t water;
  state_phys_vars_t air;
};

typedef struct phys_vars phys_vars_t;

phys_vars_t default_phys_vars =
  { // the compiler doesn't like keyed lists
    { // ground
      800, // gravity
      22,  // stepheight
      4,   // friction
      2,   // edge friction
      10,  // accelerate
      100, // stopspeed
      260, // maxspeed
      270  // jumpspeed
    },
    { // water
      800, // gravity
      22,  // stepheight
      4,   // friction
      2,   // edge friction
      10,  // accelerate
      100, // stopspeed
      150, // maxspeed
      270  // jumpspeed
    },
    { // air
      800, // gravity
      22,  // stepheight
      0,   // friction
      0,   // edge friction
      10,  // accelerate
      100, // stopspeed
      30,  // maxspeed
      270  // jumpspeed
    }
  };

.phys_vars_t * phys_vars;

//
//    triggers
//

.string target;

.string targetname;

.entity_array_t target_list;

struct trigger_event{
  entity activator;
  entity first_trigger;
  entity last_trigger;
  entity current_trigger;
  entity current_target;
};

typedef struct trigger_event trigger_event_t;

.float trigger_flags;

.int( trigger_event_t event ) trigger_action;

enum
  {
    TRIGGERFL__IS_TRIGGER = FL_1,
    TRIGGERFL__READY = FL_2,
  };

//
//    Buttons
//

enum
  {
    BUTTONFL__ATTACK = FL_1,
    BUTTONFL__JUMP = FL_2,
  };

//
//    Damage
//

typedef int damagefl_t;

enum
  {
    DAMAGEFL__NORMAL = FL_1,
  };

enum
  {
    DAMAGESRC__UNKNOWN,
    DAMAGESRC__AXE,
    DAMAGESRC__SHOTGUN,
  };

struct damage_info_t
{
  entity target;
  float amount;
  entity inflictor;
  entity attacker;
  damagefl_t flags;
  float src;
  bool collect;
};

float	DEAD_NO				= 0;
float	DEAD_DYING			= 1;
float	DEAD_DEAD			= 2;
float	DEAD_RESPAWNABLE		= 3;


//
//    Misc
//

.float time_when_ready;


//
//    Math
//

const float DEG2RAD = M_PI / 180;
const float RAD2DEG = 1 / DEG2RAD;
