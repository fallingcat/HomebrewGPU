# Ray Core
Ray core is a 3 stages pipeline design which allows different threads to be processed at the same time on different stage. The 3 stages are :
  - Surface stage : This stage process the ray from camera and find the closest hit of the ray then pass the hit information to next stage.
  - Shadow stage : This stage cast a ray from closest hit position to light source to find the first hit. If there is any hit then this thread is under shadow. It will pass the shadow information to next stage.
  - Shade stage: This stage will use the closest hit information to decide if it's the final color or reflection/refraction will occur. If reflection/refraction occurs, it will cast a reflection/refraction ray and pass the data back to surface stage.

<img src="/doc/RayCore.png" alt="Ray Core Architecture" width="360"/>

## Surface Stage
  ### BVH Unit
  Traverse BVH structure to find the possible leaves for hit test.
  
  ### Ray Unit
  Find the closest hit between the current ray and all possible primitives.
  
  ### Hit Unit
  Do intersection test between the current ray and one primitive. You can configure the number of hit units to increase the intersection test rate.

## Shadow Stage
  ### BVH Unit
  Traverse BVH structure to find the possible hit leaves.
  
  ### Ray Unit
  Find the first hit between the light ray and all possible primitives.
  
  ### Hit Unit
  Do intersection test between the current ray and one primitive. You can configure the number of hit units to increase the intersection test rate.

## Shade Stage
  ### Reflection Ray
  Compute reflection ray and feed back to Surface stage.

  ### Refraction Ray
  Compute refraction ray and feed back to Surface stage.

  ### Color Combine
  Combine the current color from reflection/refraction with previous color.

  ### Final Color
  Output final color when there is no more reflection/refraction ray.
