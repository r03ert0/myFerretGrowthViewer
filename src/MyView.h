/* MyView */

#import <Cocoa/Cocoa.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>

#import "Trackball.h"

typedef struct
{
    float x,y,z;
}float3D;
typedef struct
{
    int a,b,c;
}int3D;
typedef struct
{
    int np;
    int nt;
    float3D *p;
    int3D *t;
}Mesh;

@interface MyView : NSOpenGLView
{
	int		counter;
	Mesh	*trajectory;

	Trackball	*m_trackball;
	float		m_rotation[4];	// The main rotation
	float		m_tbRot[4];	// The trackball rotation
    
    float P;
    
    NSTimer *timer;
    int flagSaveImages;
}
-(void)initTrajectory;
-(void)animate:(NSTimer*)theTimer;

-(void)savePicture:(NSString *)filename;
-(void)spin:(char*)path nframes:(int)nframes;

-(void)setStandardRotation:(int)tag;
-(void)addRotation:(float)value toAxis:(int)axis;
-(IBAction)startStop:(id)sender;
-(IBAction)saveImages:(id)sender;
-(IBAction)setTime:(id)sender;

int msh_importPlyMeshData(Mesh *mesh, char *path);
void trajectory_draw(Mesh *tr,float time,int flag);
void trajectory_lines_draw(Mesh *tr,float time);

@end
