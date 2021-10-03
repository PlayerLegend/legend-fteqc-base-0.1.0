$cd id1/models/soldier3
$origin 0 -6 24
$base base		
$skin skin

$frame stand1 stand2 stand3 stand4 stand5 stand6 stand7 stand8

$frame death1 death2 death3 death4 death5 death6 death7 death8
$frame death9 death10

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11

$frame load1 load2 load3 load4 load5 load6 load7 load8 load9 load10 load11

$frame pain1 pain2 pain3 pain4 pain5 pain6

$frame painb1 painb2 painb3 painb4 painb5 painb6 painb7 painb8 painb9 painb10
$frame painb11 painb12 painb13 painb14

$frame painc1 painc2 painc3 painc4 painc5 painc6 painc7 painc8 painc9 painc10
$frame painc11 painc12 painc13

$frame run1 run2 run3 run4 run5 run6 run7 run8

$frame shoot1 shoot2 shoot3 shoot4 shoot5 shoot6 shoot7 shoot8 shoot9

$frame prowl_1 prowl_2 prowl_3 prowl_4 prowl_5 prowl_6 prowl_7 prowl_8
$frame prowl_9 prowl_10 prowl_11 prowl_12 prowl_13 prowl_14 prowl_15 prowl_16
$frame prowl_17 prowl_18 prowl_19 prowl_20 prowl_21 prowl_22 prowl_23 prowl_24

.float action_finished;

const float soldier_anim_rate = walker_frametime;
const string soldier_model = "progs/soldier.mdl";

bool soldier_can_see_entity( entity ent )
{
  traceline( self.origin, ent.origin, FALSE, self );

  return trace_ent == self.enemy;
}

bool soldier_can_see_enemy()
{
  if( !self.enemy )
    {
      return FALSE;
    }

  return soldier_can_see_entity( self.enemy );
}

entity soldier_find_enemy()
{
  entity found;

  for( found = world; ; found = find( found, classname, "player" ) )
    {
      if( found == world )
	{
	  break;
	}
      
      if( !soldier_can_see_entity( found ) )
	{
	  continue;
	}
    };

  return found;
}

//    shooting

const float soldier_shot_time = soldier_anim_rate * 9;

void soldier_action_look_at_enemy()
{
  self.angles_y += walker_frametime * 8 * anglediff( walker_angle_to_point( self.enemy.origin ), self.angles_y );
}

void soldier_sub_shoot()
{
  print("Shot\n");
}

.float soldier_target_last_attacked;

void soldier_action_attack()
{
  soldier_sub_shoot();
  self.angles_y += walker_frametime * 8 * anglediff( walker_angle_to_point( self.enemy.origin ), self.angles_y );
  self.action_finished = time;
  walker_anim_start( soldier_anim_rate, $shoot1 );
  self.walker_action = soldier_action_look_at_enemy;
  self.enemy.soldier_target_last_attacked = time;
}

//    walking

const float soldier_walk_time = soldier_anim_rate * 8;

bool soldier_can_walk_to_enemy()
{
  if( !soldier_can_see_enemy() )
    {
      return FALSE;
    }

  vector v = self.enemy.origin - self.origin;

  float div = 1.0 / 5.0;

  vector pos;

  for( float f = div; f <= 1.0 - div; f += div )
    {
      pos = self.origin + v * f;
      traceline( pos, pos + self.mins_z * '0 0 2.5', FALSE, self );
      if( trace_fraction == 1.0 )
	{
	  return FALSE;
	}
    }

  return TRUE;
}

void soldier_action_walk_go()
{
  self.angles_y += walker_frametime * 180 * walker_check_forward( 100, self.angles_y, 30 );

  if( soldier_can_walk_to_enemy() )
    {
      print(ftos(time));
      print(" track\n");
      self.angles_y += walker_frametime * 4 * anglediff( walker_angle_to_point( self.enemy.origin ), self.angles_y );      
    }
  else
    {
      self.angles_y += walker_frametime * 0.5 *  anglediff( walker_angle_to_point( self.enemy.origin ), self.angles_y );  
    }
  
  self.walker_moveangle = self.angles_y;
  self.walker_speed = 100;
}

void soldier_action_walk_start()
{  
  self.action_finished = time + soldier_walk_time;
  walker_anim_start( soldier_anim_rate, $run1 );
  self.walker_action = soldier_action_walk_go;
  self.walker_action();
}

//    pain

.float dead_shots;
.float last_flinch;

void soldier_die( damage_info_t * damage )
{
  entity old = self;
  self = damage->target;

  float count;
  float aframe;

  if( random() < 0.5 )
    {
      count = 10;
      aframe = $death1;
    }
  else
    {
      count = 11;
      aframe = $deathc1;
    }
  
  self.dead_shots++;
  
  self.velocity += damage->amount * normalize(self.origin - damage->inflictor.origin);// + '0 0 0.7' * (time - self.last_damage) * cvar( "sv_gravity" );
  //self.angles_y += 30 * 2 * (random() - 0.5);
  
  if( self.dead_shots > 2 )
    {
      self.velocity += damage->amount * normalize(self.origin - damage->inflictor.origin);// + '0 0 0.7' * (time - self.last_damage) * cvar( "sv_gravity" );
      self.angles_y = anglemod( self.angles_y );
      
      self.angles_y += anglediff( damage->attacker.angles_y + 180 + 10 * 2 * (random() - 0.5), self.angles_y );

      self.last_flinch = time;
      
      if( random() > 0.05 )
	{
	  count -= 1;
	  aframe += 1;
	}
    }

  if( self.health < -500 )
    {
      //self.solid = SOLID_NOT;
    }
      
  
  self.action_finished = time + soldier_anim_rate * count;
  walker_anim_start( soldier_anim_rate, aframe );  

  self.walker_speed = 0;
  self.walker_action = __NULL__;
  
  self = old;

  print("die\n");
}

void soldier_pain( damage_info_t * damage )
{
  float frame;
  float count;

  entity old = self;
  self = damage->target;
  
  switch( distinct_random( 4 ) )
    {
    case 4:
      frame = $pain1;
      count = 6;
      break;

    case 3:
      frame = $painb1;
      count = 14;
      break;

    case 2:
      frame = $painc1;
      count = 13;
      break;
      
    default:
      print("no pain\n");
      self = old;
      return;
    }

  self.walker_speed = 0;
  self.walker_action = __NULL__;
  self.action_finished = time + soldier_anim_rate * count;
  walker_anim_start( soldier_anim_rate, frame );
  print("started\n");

  self = old;
}
  
//    choose

bool soldier_should_choose()
{
  return time >= self.action_finished;
}

void soldier_choose()
{
  print("choose\n");
  
  self.enemy = soldier_find_enemy();
  
  self.walker_speed = 0;

  if( self.health <= 0 )
    {
      self.think = __NULL__;
      self.velocity_x = 0;
      self.velocity_y = 0;
      self.solid = SOLID_NOT;
    }
  else if( ((random() > 0.2 && time - self.enemy.soldier_target_last_attacked > 1) ||
       (random() > 0.6)) &&
      soldier_can_see_enemy() )
    {
      self.walker_action = soldier_action_attack;
    }
  else
    {
      self.walker_action = soldier_action_walk_start;
    }
}

//    spawn

void soldier_physical_setup()
{
  self.walker_accel = 3;
  setsize( self, VEC_HULL_MIN, VEC_HULL_MAX );
  setmodel( self, soldier_model );
  self.solid = SOLID_SLIDEBOX;
  self.movetype = MOVETYPE_WALK;
  self.customphysics = walker_physics;
  setorigin( self, self.origin );
}

void soldier_ai_setup()
{
  self.walker_should_choose = soldier_should_choose;
  self.walker_choose = soldier_choose;
  self.think = walker_think;
  self.nextthink = time + random();
}

void soldier_health_setup()
{
  self.takedamage = DAMAGE_AIM;
  self.health = 100;
  self.pain = soldier_pain;
  self.die = soldier_die;
  self.dead_shots = 0;
}

void monster_army()
{
  soldier_physical_setup();
  soldier_ai_setup();
  soldier_health_setup();
  print("SPAWNED\n");
}
