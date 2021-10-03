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
    entry.qc<client_qc>

    Entry functions go here
*/
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

entity vmodel_ent;
float last_vmodel_frame;
float next_vmodel_frame;

void CSQC_Init( float apiver, string enginename, float enginever )
{
  registercvar( "v_track_scale", "10" );
  registercvar( "v_track_rate", "5" );
  
  //set_model_indexes();
}

float velocity_roll_slosh;

vector player_view_velocity;
vector player_view_accel;
vector player_interp_velocity;
vector player_interp_accel;
vector view_origin;
vector camera_angles;

vector camera_forward;
vector camera_right;
vector camera_up;

vector view_forward;
vector view_right;
vector view_up;

vector flat_view_forward;
vector flat_view_right;
vector flat_view_up;

vector master_view_angles;

void update_view_vectors()
{
  makevectors( [0, master_view_angles_y, 0] );

  flat_view_forward = v_forward;
  flat_view_up = v_up;
  flat_view_right = v_right;
  
  makevectors( master_view_angles );

  view_forward = v_forward;
  view_up = v_up;
  view_right = v_right;
  
  makevectors( camera_angles );

  camera_forward = v_forward;
  camera_up = v_up;
  camera_right = v_right;
}

vector laser_screen_pos()
{
  traceline( self.origin, self.origin + view_forward * 8192, FALSE, self );

  return project( trace_endpos );
}

void drawbox( float width, vector min, vector max, vector rgb, float alpha )
{
  drawline( width, min, [min_x, max_y], rgb, alpha );
  drawline( width, [min_x, max_y], max, rgb, alpha );
  drawline( width, max, [max_x, min_y], rgb, alpha );
  drawline( width, [max_x, min_y], min, rgb, alpha );
}

void draw_x( float width, vector min, vector max, vector rgb, float alpha )
{
  drawline( 3, min, max, rgb, alpha );
  drawline( 3, [min_x, max_y, 0], [max_x, min_y, 0], rgb, alpha );
}

void draw_laser()
{
  vector screen_pos = laser_screen_pos();

  float laser_rad = 5;

  vector rgb = '0 1 0';
  float alpha = 0.8;

  drawbox( 1, screen_pos - laser_rad * '1 1 0', screen_pos + laser_rad * '1 1 0', rgb, alpha );
  draw_x( 1, screen_pos - 0.7*laser_rad * '1 1 0', screen_pos + 0.7*laser_rad * '1 1 0', rgb, alpha );

  //drawfill( screen_pos - laser_rad * '1 1 0', 2 * laser_rad * '1 1 0', '1 1 0', 1 );
}

vector get_velocity_weapon_sway()
{
  /*
  static vector sway_accel, sway_ammount;
  static vector player_last_velocity;

  vector player_accel = (self.velocity - player_last_velocity) / frametime;

  const float weapon_sway_max = 4;

  const float phys_speed = 5;
  const float phys_weight = 2;
  const float accel_decay = 4;
  const float return_speed = 2;
  const vector use_velocity = player_accel - v_forward * (player_accel * v_forward);
 
  vector change_accel = (weapon_sway_max * use_velocity / 100) - accel_decay*sway_accel - return_speed*sway_ammount;
 
  vector accel_dir = normalize( sway_accel );

  sway_accel = bound_vector_max( sway_accel + phys_speed * frametime * change_accel, weapon_sway_max - accel_dir*sway_ammount );
  
  sway_ammount = bound_vector_max( sway_ammount + phys_speed * phys_weight * frametime * sway_accel, weapon_sway_max );

  player_last_velocity = self.velocity;
  
  return sway_ammount;*/

  return (player_interp_velocity) * frametime;
}

vector get_rotation_weapon_sway()
{
  const float weapon_sway_max = 8;
  
  static float last_angle, sway_accel, sway_ammount;

  const float phys_speed = 5;
  const float phys_weight = 2;
  const float accel_decay = 2;
  const float return_speed = 2;

  float sway_min = bound_float( sway_ammount - weapon_sway_max, -weapon_sway_max, 0 );
  float sway_max = bound_float( weapon_sway_max - sway_ammount, 0, weapon_sway_max );

  float change_accel = anglediff( master_view_angles_y, last_angle ) - accel_decay*sway_accel - return_speed*sway_ammount;
  
  sway_accel = bound_float( sway_accel + phys_speed * phys_weight * frametime * change_accel, sway_min, sway_max );

  sway_ammount = bound_float( sway_ammount + phys_speed * frametime * sway_accel, -weapon_sway_max, weapon_sway_max );
  
  last_angle = master_view_angles_y;

  return view_right * sway_ammount;
}

void update_viewmodel()
{
  //    spawn
  if( vmodel_ent == world )
    {
      vmodel_ent = spawn();
      vmodel_ent.drawmask = MASK_ENGINE;
    }
    
  //    origin
  setorigin( vmodel_ent, getviewprop( VF_ORIGIN ) /*- get_velocity_weapon_sway()*/ - get_rotation_weapon_sway() );
    
  //    angles
  vmodel_ent.angles = [ -master_view_angles_x, master_view_angles_y, master_view_angles_z ];

  //    model
  vmodel_ent.modelindex = getstatf( STAT_WEAPONMODELI );

  //    frame
  next_vmodel_frame = getstatf( STAT_WEAPONFRAME );
  if( fabs( next_vmodel_frame - last_vmodel_frame ) > 1 )
    {
      last_vmodel_frame = next_vmodel_frame;
    }
}

void update_interp_offset()
{
  vector last_interp_ofs = self.org_interp_ofs;
  vector last_interp_velocity = player_interp_velocity;
  
  if( self.org_interp_time > 0 && vlen_is_greater( self.org_interp_ofs, 1 ) )
    {
      float origin_time_diff = bound( 0, self.org_interp_time, frametime );
      self.org_interp_ofs -= self.org_interp_ofs * origin_time_diff / self.org_interp_time;
      self.org_interp_time -= origin_time_diff;
    }

  last_interp_velocity = player_interp_velocity;
  player_interp_velocity = (self.org_interp_ofs - last_interp_ofs) / frametime;

  player_interp_accel = (player_interp_velocity - last_interp_velocity) / frametime;
}

void calc_view_accel()
{
  static vector last_player_velocity;

  vector player_accel = (self.velocity - last_player_velocity) / frametime;

  player_view_velocity = self.velocity + player_interp_velocity;

  player_view_accel = player_accel + player_interp_accel;
  
  last_player_velocity = self.velocity;
}

void set_view_origin()
{
  update_interp_offset();

  calc_view_accel();
    
  view_origin = self.origin;

  //view_origin += '0 0 1' * getstatf( STAT_VIEWHEIGHT );
  //view_origin += camera_right * (camera_right * view_forward) * getstatf( STAT_VIEWHEIGHT ) / 2;
  view_origin += camera_up * getstatf( STAT_VIEWHEIGHT ) / 2;
  view_origin += '0 0 1' * getstatf( STAT_VIEWHEIGHT ) / 2;

  view_origin += self.org_interp_ofs;

  //view_origin += 100 * (view_up * sin( -camera_angles_x * DEG2RAD ));

  setviewprop( VF_ORIGIN, view_origin );
}

void even_out_roll()
{
  float cut = (self.flags & FL_ONGROUND) ? 6 : 1;
  
  master_view_angles_z += 70 * frametime * bound_float( anglediff( 0, master_view_angles_z ), -cut, cut );
}

void set_view_angles()
{
  vector diff = anglediff3( master_view_angles, camera_angles );

  float mul;
  
  mul = 1 + vlen( diff ) / cvar("v_track_scale");
  //mul = 1;

  camera_angles += mul * cvar("v_track_rate") * frametime * diff;

  float velocity_roll_new = self.velocity != '0 0 0' ? view_right * self.velocity / 1000 : 0;
  velocity_roll_slosh = velocity_roll_slosh + 10 * frametime * ( velocity_roll_new - velocity_roll_slosh );
  setviewprop( VF_ANGLES, camera_angles + '0 0 20' * velocity_roll_slosh );
}

bool get_player_self()
{
  self = findfloat( world, entnum, player_localentnum );

  if( self == world )
    {
      cprint( "self is world\n" );
      return FALSE;
    }
  else
    {
      return TRUE;
    }
}

void CSQC_UpdateView( float width, float height, float menushown )
{
  clearscene();

  if( !get_player_self() )
    {
      return;
    }

  master_view_angles = view_angles;

  even_out_roll();
  
  update_view_vectors();

  set_view_angles();

  set_view_origin();
  
  update_viewmodel();
  
  setviewprop( VF_DRAWENGINESBAR, 0 );	
  setviewprop( VF_DRAWCROSSHAIR, 0 );
  
  drawfill( '0 0 0', [width, height, 0], '1 1 0', 1, 0 );
  
  addentities( MASK_ENGINE );

  renderscene();

  draw_laser();
}

/*
vector vectoangles2( vector v )
{
  v = normalize( v );
  vector ret;

  ret_x = asin( v_z ) * RAD2DEG;
  //ret_x = 0;

  if( v_x == 0 )
    {
      ret_y = 90;
    }
  else
    {
      ret_y = atan( v_y / v_x ) * RAD2DEG;
    }

  if( v_x < 0 )
    {
      ret_y += 180;
    }

  ret_y = anglemod( ret_y );

  ret_z = 0;

  return ret;
  }*/

void rotate_view_about_axis( vector axis, float radians )
{
  vector rotate = rotate_about_axis( view_forward, axis, radians );
  vector new_angles = vectoangles( rotate, view_up );
  new_angles_x = -new_angles_x;
  master_view_angles = new_angles;
}

/*float CSQC_InputEvent(float evtype, float scanx, float chary, float devid)
{
  float ignore = 1, apply = 0;
  update_view_vectors();
  switch( evtype )
    {
    case IE_MOUSEDELTA:
      //rotate_view_about_axis( scanx * camera_up + chary * camera_right, (fabs( chary ) + fabs( scanx )) * cvar( "sensitivity" ) / 3000 );
      return ignore;
    default:
      return apply;
    }
    }*/

 /*void CSQC_Input_Frame()
{
  put_angles = master_view_angles;
  }*/

/*void CSQC_WorldLoaded()
{
  
}*/

void CSQC_Ent_Update( float isnew )
{
  float type = readbyte(); // entity type
  float flags = readbyte(); // sendflags
  float sendtime = readfloat(); // server time when sent
  
  switch( type )
    {
    case SENDENT__PLAYER:
      recvent__player( isnew, sendtime, flags );
      break;
    default:
      error( "Unknown entity type! oh noes! panic!" );
    }

  self.last_sendtime = sendtime;
  self.last_recvtime = time;
}

void CSQC_Ent_Remove()
{
  print("Removed\n");
  remove( self );
}

/*void CSQC_Parse_Event()
{
  
}*/
