typedef struct path_node
{
  struct path_node ** node_list;
  int node_count;
  float distance;
  vector origin;
}
  path_node;

typedef struct path_chain
{
  struct path_node ** node_list;
  int node_count;
}
  path_node;

bool node_can_see( path_node * node, entity ent )
{
  traceline( node->origin, ent.origin, FALSE, ent );

  return trace_frac == 1.0;
}

struct path_node * get_closer_node( path_chain * chain, entity target ) // chain must have at least one node
{
  path_node * node = chain->node_list[chain->node_count - 1];

  path_node * test_node;

  int chain_max = chain->count - 1;

  bool is_new;

  path_node * closest_node;
  float closest_dist;
  float dist;
  float dist_vec;
  
  for( int n = 0; n < node->node_count; n++ )
    {
      test_node = node->node_list + n;

      is_new = true;
      for( int c = 0; c < chain_max; c++ )
	{
	  if( chain->node_list[c] == test_node )
	    {
	      is_new = false;
	    }
	}
      
      if( !is_new )
	{
	  continue;
	}

      dist_vec
    }
}
