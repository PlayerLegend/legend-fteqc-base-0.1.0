bool enemy_is_visible;
vector angles_to_enemy;
bool hit_wall;

.void() simple_choose_action;
.void() simple_action;
.float simple_last_frame;
.float turn_speed;
.float walk_dir;
.float walk_speed;
.float walk_accel;

float simple_ai_frametime;

void test_enemy_visible()
{
  traceline( self.origin, self.enemy.origin, FALSE, self );
  enemy_is_visible = (trace_ent == self.enemy);
}

void determine_angles_to_enemy()
{
  angles_to_enemy = vectoangles( self.enemy.origin - self.origin );
}

bool is_facing_enemy( float angle_limit )
{
  return fabs( anglemod( self.angles_y - angles_to_enemy_y ) ) < angle_limit;
}

void turn_to_enemy( float deg_per_sec )
{
  float diff = anglediff( self.angles_y, angles_to_enemy_y );

  if( diff > deg_per_sec )
    {
      diff = deg_per_sec;
    }
  if( diff < -deg_per_sec )
    {
      diff = deg_per_sec;
    }

  self.angles_y += diff;
}

vector angle_offset( float angle )
{
  return '0 1 0' * cos( angle ) + '1 0 0' * sin( angle );
}

bool can_move( float angle )
{
  float test_dist = self.mins*self.mins + self.maxs*self.maxs;
  vector norm_ofs = angle_offset( angle );
  vector ofs = test_dist * norm_ofs;
  
  tracebox( self.origin, self.mins, self.maxs, self.origin + ofs, FALSE, self );

  if( trace_fraction < 1.0 )
    {
      return FALSE;
    }

  traceline( self.origin + ofs, self.origin + ofs + self.mins_z*'0 0 2', FALSE, self );

  if( trace_fraction == 1.0 )
    {
      return FALSE;
    }

  return TRUE;
}

void apply_movement( float max_speed, float accel )
{
  vector velangle = vectoangles( self.velocity );
  
  if( !can_move( velangle_y ) )
    {
      self.velocity_x = 0;
      self.velocity_y = 0;
      hit_wall = TRUE;
      return;
    }

  
  self.velocity += frametime * accel * angle_offset( self.walk_dir );

  float speed = vlen( self.velocity );

  if( speed > max_speed )
    {
      self.velocity = (max_speed / speed) * self.velocity;
    }
}

void simple_ai_frame()
{
  //    determine this creature's frametime
  simple_ai_frametime = time - self.simple_last_frame;

  self.simple_last_frame = time;

  //    perform per-frame tests
  test_enemy_visible();
  determine_angles_to_enemy();

  if( self.simple_choose_action )
    {
      self.simple_choose_action();
    }

  if( self.simple_action )
    {
      self.simple_action();
    }

  //    apply movement  
  apply_movement( self.walk_speed, self.walk_accel );
}
