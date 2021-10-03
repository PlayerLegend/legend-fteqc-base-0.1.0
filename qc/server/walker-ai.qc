float walker_lookangle;
.float walker_moveangle;
.float walker_speed;
.float walker_accel;
const float walker_frametime = 0.1;

.void() walker_frame_setup;
.bool() walker_should_choose;
.void() walker_choose;
.void() walker_action;
.float walker_anim_rate;
.float walker_anim_start_time;
.float walker_anim_first_frame;
.float walker_turn_suggestion;
.float last_distinct_random;

int distinct_random( float range )
{
  int ret;

  do
    {
      ret = rint( random() * range );
    }
  while( ret == self.last_distinct_random );

  self.last_distinct_random = ret;

  print(ftos(self.last_distinct_random));
  print(" RANDOM\n");

  return ret;
}

vector walker_angle2vec( float angle )
{
  return '1 0 0'*cos( angle * DEG2RAD ) + '0 1 0'*sin( angle * DEG2RAD );
}

float walker_angle_to_point( vector point )
{
  vector v = point - self.origin;
  vector a = vectoangles( v );
  return a_y;
}

float walker_test_dir( vector vec )
{
  traceline( self.origin, self.origin + vec, FALSE, self );

  if( trace_fraction < 1.0 )
    {
      return trace_fraction;
    }

  vector v;
  float f;
  
  for( f = 0; f <= 1.0; f += 1.0 / 4.0 )
    {
      v = f*vec;
      traceline( self.origin + v, self.origin + v + self.mins_z*'0 0 1' - '0 0 22', FALSE, self );
      te_lightning1( self, self.origin + v, self.origin + v + self.mins_z*'0 0 1' - '0 0 22' );
      
      if( trace_fraction == 1.0 )
	{
	  return 0;//f;
	}
    }

  return 1.0;
}

float walker_check_forward( float dist, float angle, float anglewidth )
{
  vector
    dir1 = walker_angle2vec( angle + anglewidth ),
    dir2 = walker_angle2vec( angle - anglewidth );

  float
    test1 = walker_test_dir( dist * dir1 ),
    test2 = walker_test_dir( dist * dir2 );

  if( test1 == test2 && test1 != 0.0 )
    {
      if( test1 == 1.0 )
	{
	  return 0;
	}
      else
	{
	  return 2 * (random() - 0.5); // random offset
	}
    }

  float ret = (test1 > test2) ? 1 - test2 : test1 - 1;
  
  if( test1 == 0 || test2 == 0 )
    {
      if( ret < 0 )
	{
	  self.walker_turn_suggestion = -1.0;
	}
      else
	{
	  self.walker_turn_suggestion = 1.0;
	}
    }
  else
    {
      self.walker_turn_suggestion -= self.walker_turn_suggestion * 2 * walker_frametime;
      self.walker_turn_suggestion += (ret - self.walker_turn_suggestion) * walker_frametime;
    }
  
  return ret + 3 * self.walker_turn_suggestion;
}

void walker_physics()
{
  tracebox( self.origin, self.mins, self.maxs, self.origin - '0 0 1', FALSE, self );
  
  if( trace_fraction == 1.0 )
    {
      self.velocity -= frametime * '0 0 1' * cvar( "sv_gravity" );
    }

  vector hit_normal;
  float move_time = frametime;
  float iter = 0;
  float move_fraction;
  
  while( move_time > 0.1 * frametime &&
	 iter < 10 )
    {
      tracebox( self.origin, self.mins, self.maxs, self.origin + move_time * self.velocity, FALSE, self );

      self.origin = trace_endpos;

      move_fraction = trace_fraction;
      
      if( move_fraction < 1.0 )
	{
	  hit_normal = trace_plane_normal;
	  if( !playermove__do_step( self, 22, '0 0 -1' ) )
	    {      
	      self.velocity -= hit_normal * (self.velocity * hit_normal);
	    }
	  else
	    {
	      setorigin( self, self.origin );
	    }
	}
      
      move_time -= move_time * move_fraction;

      iter++;
    }

  setorigin( self, self.origin );
  
  if( self.think && time > self.nextthink )
    {
#warning This is a hack to get thinks working when customphysics is used
      self.think();
    }
}

void walker_applyvel()
{
  vector dir = walker_angle2vec( self.walker_moveangle );

  float add = self.walker_speed - bound_float( dir * self.velocity, 0, self.walker_speed );

  vector fric_vel = self.velocity;// - self.velocity * (self.velocity * dir);
  fric_vel_z = 0;
  fric_vel *= -self.walker_accel;

  self.velocity +=
    walker_frametime * ( dir * add * self.walker_accel
			 + fric_vel );

  /*tracebox( self.origin, self.mins, self.maxs, self.origin - '0 0 2', FALSE, self );

  if( trace_fraction == 1.0 )
    {
      self.velocity -= walker_frametime * '0 0 0.9' * cvar( "sv_gravity" );
    }
  else if( self.velocity_z < 0 )
    {
      self.velocity_z = 0;
      }*/
}

void walker_anim_set_frame()
{
  self.frame = ((time - self.walker_anim_start_time) / self.walker_anim_rate) + self.walker_anim_first_frame;
}

void walker_anim_start( float rate, float first_frame )
{
  self.walker_anim_rate = rate;
  self.walker_anim_first_frame = first_frame;
  self.walker_anim_start_time = time;
  self.frame = first_frame;
}

void walker_think()
{
  if( self.walker_frame_setup )
    {
      self.walker_frame_setup();
    }
  
  if( self.walker_should_choose() )
    {
      self.walker_choose();
    }

  if( !self.think )
    {
      return;
    }

  if( self.walker_action )
    {
      self.walker_action();
    }
  
  walker_applyvel();

  walker_anim_set_frame();

  self.nextthink = time + walker_frametime;
}
