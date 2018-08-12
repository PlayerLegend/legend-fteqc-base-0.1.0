/*
  Copyright 2018 Joshua D. Sawyer

  Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

  3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

bool playermove__do_step( entity tgt, float stepheight, vector gdir )
{
  vector step_vel = tgt.velocity - gdir * (tgt.velocity * gdir);
  vector step_dir = normalize( step_vel );

  //    check if tgt hit a wall
  tracebox( tgt.origin, tgt.mins, tgt.maxs, tgt.origin + step_dir, FALSE, tgt );

  if( trace_fraction >= 1.0 )
    {
      return FALSE;
    }
  
  vector step_org = tgt.origin - gdir * stepheight;

  //    check if tgt can go up
  tracebox( tgt.origin, tgt.mins, tgt.maxs, step_org, FALSE, tgt );

  if( trace_fraction < 1.0 )
    {
      return FALSE;
    }

  //    check if tgt can go forward after going up
  tracebox( step_org, tgt.mins, tgt.maxs, step_org + step_dir, FALSE, tgt );

  if( trace_fraction < 1.0 )
    {
      return FALSE;
    }
  
  //    place tgt down on top of the step
  vector test_vec = trace_endpos;
  tracebox( test_vec, tgt.mins, tgt.maxs, test_vec + stepheight * gdir, FALSE, tgt );
  
  tgt.origin = trace_endpos;

  if( tgt.velocity * gdir > 0 )
    {
      tgt.velocity = step_vel;
    }

  return TRUE;
}

bool playermove__jump( entity tgt, state_phys_vars_t * phys_state, vector gdir )
{
  if( input_buttons & BUTTONFL__JUMP )
    //    jump
    {
      print(ftos(time));
      print(" Vel\n");
      float upspeed = -gdir * tgt.velocity;
      if( upspeed < 0 )
	{
	  tgt.velocity = tgt.velocity - gdir * upspeed;
	}

      /*if( upspeed < phys_state->jumpspeed )
	{
	  float add_upspeed = phys_state->jumpspeed - upspeed;
	  tgt.velocity = tgt.velocity - gdir * add_upspeed;
	  print(ftos(add_upspeed));
	  print(" VEL\n");
	  }*/

      tgt.velocity = tgt.velocity - gdir * phys_state->jumpspeed;
      
      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

void playermove__air_accelerate( entity tgt, state_phys_vars_t * phys_state, float move_time, float wishspeed, vector wishdir, vector gdir )
{
  tgt.velocity = tgt.velocity + move_time * phys_state->gravity * gdir;

  float wishspeed_cap = wishspeed < phys_state->maxspeed ? wishspeed : phys_state->maxspeed;
  float currentspeed = tgt.velocity * wishdir;
  float need_speed = wishspeed_cap - currentspeed;

  if( need_speed <= 0 )
    {
      return;
    }
  
  float accelspeed = phys_state->accelerate * wishspeed * move_time;

  if( accelspeed > need_speed )
    {
      accelspeed = need_speed;
    }
  
  tgt.velocity = tgt.velocity + accelspeed * wishdir;
}

void playermove__ground_accelerate( entity tgt, state_phys_vars_t * phys_state, float move_time, float wishspeed, vector wishdir, vector gdir )
//    why does the friction feel wrong?
{
  vector vert_vel = (gdir * tgt.velocity) * gdir;
  vector horiz_vel = tgt.velocity - vert_vel;

  if( horiz_vel * horiz_vel > 1 )
    //    friction
    {
      float horiz_speed = vlen( horiz_vel );
      vector lead_pos = tgt.origin + 16 * normalize( horiz_vel );
      float down_size = tgt.mins * gdir;
      
      traceline( lead_pos, lead_pos - (down_size + 1) * gdir, FALSE, tgt );
      
      float vel_antiscale = frametime * phys_state->friction;
      if( trace_fraction >= 1.0 )
	//    not on an edge
	{
	  vel_antiscale = vel_antiscale * phys_state->edgefriction;
	}
      
      if( horiz_speed < phys_state->stopspeed ) // note: in the qw pmove code, it's speed *including* the vertical component, not just horiz_speed
	{
	  vel_antiscale = vel_antiscale * phys_state->stopspeed;
	}
      else
	{
	  vel_antiscale = vel_antiscale * horiz_speed;
	}

      float vel_scale = horiz_speed > vel_antiscale ?
	(horiz_speed - vel_antiscale) / horiz_speed : 0;
      
      tgt.velocity = vert_vel + horiz_vel * vel_scale;
    }
  else
    {
      tgt.velocity = tgt.velocity - horiz_vel;
    }

  if( wishspeed > phys_state->maxspeed )
    {
      wishspeed = phys_state->maxspeed;
    }

  float apply_speed = wishspeed - tgt.velocity * wishdir;
  if( apply_speed > 0 )
    {
      tgt.velocity = tgt.velocity + wishdir * min( apply_speed, phys_state->accelerate * move_time * wishspeed );
    }
  
  tgt.velocity = tgt.velocity + move_time * phys_state->gravity * gdir;
}

bool playermove__checkbottom( entity tgt, vector gdir )
{
  float dist = 2;
  tracebox( tgt.origin, tgt.mins, tgt.maxs, tgt.origin + dist * gdir, FALSE, tgt );
  if( trace_fraction < 1.0 )
    {
      return TRUE;
    }
  else
    {
      return FALSE;
    }
}

void playermove__slide( entity tgt, phys_vars_t * phys_v, float move_time, float wishspeed, vector wishdir, vector gdir )
{
  float iter_max = 10;
  float iter = 0;
  float time_diff;
  vector hit_normal;
  float stepheight = phys_v->air.stepheight;
  vector next_org;
  float move_frac;
  //setorigin( tgt, tgt.origin + tgt.velocity * move_time );
  //return;
  
  if( playermove__checkbottom( tgt, gdir ) )
    //    on ground
    {
      if( !playermove__jump( tgt, &phys_v->ground, gdir ) )
	{
	  playermove__ground_accelerate( tgt, &phys_v->ground, move_time, wishspeed, wishdir, gdir );
	  stepheight = phys_v->ground.stepheight;
	}
    }
  else
    //    in air
    //    *** todo: in water
    {
      playermove__air_accelerate( tgt, &phys_v->air, move_time, wishspeed, wishdir, gdir );
    }
      
  while( move_time > 0 )
    {
      //    check what will be hit
      tracebox( tgt.origin, tgt.mins, tgt.maxs, tgt.origin + tgt.velocity*move_time, FALSE, tgt );
      next_org = trace_endpos;
      move_frac = trace_fraction;
      hit_normal = trace_plane_normal;
      
      //    determine the time until the hit
      time_diff = move_time * move_frac;
      
      //    move to the hit
      tgt.origin = next_org;
      move_time = move_time - time_diff;

      //    apply the hit to the target's velocity
      if( move_frac < 1.0 )
	{
	  if( !playermove__do_step( tgt, stepheight, gdir ) )
	    {
	      tgt.velocity = tgt.velocity - hit_normal * (tgt.velocity * hit_normal);
	    }
	}

      if( tgt.velocity == '0 0 0' )
	{
	  break;
	}
      
      //    count iterations
      iter += 1;
      if( iter > iter_max )
	{
	  print("Warning: Iteration break in physics ");
	  print(ftos(move_time));
	  print("\n");
	  break;
	}
    }

  setorigin( tgt, tgt.origin );
}
/*
  void playermove__slide( entity tgt, phys_vars_t * phys_v, float move_time, float wishspeed, vector wishdir, vector gdir )
  {
  float iter_max = 10;
  float iter = 0;
  float time_diff;
  vector hit_normal;
  float stepheight;
  vector next_org;
  float move_frac;
  //setorigin( tgt, tgt.origin + tgt.velocity * move_time );
  //return;
  
  while( move_time > 0 )
    {
      //    check what will be hit
      tracebox( tgt.origin, tgt.mins, tgt.maxs, tgt.origin + tgt.velocity*move_time, FALSE, tgt );
      next_org = trace_endpos;
      move_frac = trace_fraction;
      hit_normal = trace_plane_normal;
      
      //    determine the time until the hit
      time_diff = move_time * trace_fraction;

      //    accelerate up until the hit
      if( playermove__checkbottom( tgt, gdir ) )
	//    on ground
	{
	  playermove__ground_accelerate( tgt, &phys_v->ground, time_diff, wishspeed, wishdir, gdir );
	  stepheight = phys_v->ground.stepheight;
	}
      else
	//    in air
	//    *** todo: in water
	{
	  playermove__air_accelerate( tgt, &phys_v->air, time_diff, wishspeed, wishdir, gdir );
	  //playermove__ground_accelerate( tgt, &phys_v->air, time_diff, wishspeed, wishdir, gdir );
	  stepheight = phys_v->air.stepheight;
	}
      
      //    move to the hit
      tgt.origin = next_org;
      move_time = move_time - time_diff;

      //    apply the hit to the target's velocity
      if( move_frac < 1.0 && !playermove__do_step( tgt, stepheight, gdir ) )
	{
	  tgt.velocity = tgt.velocity - hit_normal * (tgt.velocity * hit_normal);
	}

      if( tgt.velocity == '0 0 0' )
	{
	  break;
	}
      
      //    count iterations
      iter += 1;
      if( iter > iter_max )
	{
	  print("Warning: Iteration break in physics ");
	  print(ftos(move_time));
	  print("\n");
	  break;
	}
    }

  setorigin( tgt, tgt.origin );
  }*/

void playermove( entity tgt, float move_time, phys_vars_t * phys_v )
{
  vector move_angles = input_angles;
  move_angles_x = 0;
  move_angles_z = 0;
  makevectors( move_angles );

  vector wishvel = input_movevalues_x * v_forward + input_movevalues_y * v_right + input_movevalues_z * v_up;
  float wishspeed = vlen( wishvel );
  vector wishdir = normalize( wishvel );//wishvel / wishspeed;

  if( phys_v == __NULL__ )
    {
      if( tgt.phys_vars != __NULL__ )
	{
	  phys_v = tgt.phys_vars;
	}
      else
	{
	  phys_v = &default_phys_vars;
	}
    }

  vector gdir = tgt.gravitydir != '0 0 0' ? tgt.gravitydir : global_gravitydir;

  playermove__slide( tgt, phys_v, move_time, wishspeed, wishdir, gdir );
}


void run_player_physics( entity tgt )
{
  entity oldself = self;
  self = tgt;

  playermove( tgt, input_timelength, __NULL__ );
  
  self = oldself;
}
