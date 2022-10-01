# Ray Core

<img src="/doc/RayCore.png" alt="Ray Core Architecture" width="360"/>

## Surface Stage
  ### BVH Unit
  Traverse BVH structure to find the possible hit leaves.
  
  ### Ray Unit
  Find the closest hit between the current ray and all possible primitives.
  
  ### Hit Unit
  Do intersection test between the current ray one and primitive. You can configure the number of hit units to increase the intersection test rate.

## Shadow Stage
  ### BVH Unit
  Traverse BVH structure to find the possible hit leaves.
  
  ### Ray Unit
  Find the first hit between the light ray and all possible primitives.
  
  ### Hit Unit
  Do intersection test between the current ray one and primitive. You can configure the number of hit units to increase the intersection test rate.

## Shade Stage
  ### Reflection Ray
  Compute reflection ray and feed back to Surface stage.

  ### Refraction Ray
  Compute refraction ray and feed back to Surface stage.

  ### Color Combine
  Combine the current color from reflection/refraction with previous color.

  ### Final Color
  Output final color when there is no more reflection/refraction ray.
