#import "MyView.h"

@implementation MyView
- (void)setStandardRotation:(int)view
{
    m_rotation[0] = m_tbRot[0] = 0.0;
    m_rotation[1] = m_tbRot[1] = 0.0;
    m_rotation[2] = m_tbRot[2] = 1.0;
    m_rotation[3] = m_tbRot[3] = 0.0;
    
    switch(view)
    {
        case 1:m_rotation[0]=270;	m_rotation[1]=1;m_rotation[2]=0; break; //sup
        case 4:m_rotation[0]= 90;	break; //frn
        case 5:m_rotation[0]=  0;	break; //tmp
        case 6:m_rotation[0]=270;	break; //occ
        case 7:m_rotation[0]=180;	break; //med
        case 9:m_rotation[0]= 90;	m_rotation[1]=1;m_rotation[2]=0; break; //cau
    }
    [self setNeedsDisplay:YES];
}

- (id)initWithFrame:(NSRect)frame
{
    GLuint attribs[] = 
    {
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAWindow,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFAColorSize, 24,
            NSOpenGLPFAAlphaSize, 8,
            NSOpenGLPFADepthSize, 24,
            NSOpenGLPFAStencilSize, 8,
            NSOpenGLPFAAccumSize, 0,
            0
    };

    NSOpenGLPixelFormat* fmt = [[NSOpenGLPixelFormat alloc] initWithAttributes: (NSOpenGLPixelFormatAttribute*) attribs];
    
    self = [super initWithFrame:frame pixelFormat:[fmt autorelease]];
    if (!fmt)	NSLog(@"No OpenGL pixel format");
    [[self openGLContext] makeCurrentContext];
    
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_SMOOTH);
	trajectory=nil;
    
    // init trackball.
    m_trackball = [[Trackball alloc] init];
    m_rotation[0] = m_tbRot[0] = 0.0;
    m_rotation[1] = m_tbRot[1] = 1.0;
    m_rotation[2] = m_tbRot[2] = 0.0;
    m_rotation[3] = m_tbRot[3] = 0.0;
	
	[self setStandardRotation:4];
    
    [self initTrajectory];
    
    flagSaveImages=0;
		
    return self;
}
-(void) getPixels:(unsigned char*)baseaddr width:(long)w height:(long)h rowbyte:(long)rb
{
    glReadPixels(0,0,w,h,GL_RGBA,GL_UNSIGNED_BYTE,baseaddr);
}
-(void)saveImage:(NSString*)filename
{
    NSRect	frame=[self bounds];
    NSBitmapImageRep *bmp=[[[NSBitmapImageRep alloc]
							initWithBitmapDataPlanes:NULL
							pixelsWide:frame.size.width
							pixelsHigh:frame.size.height
							bitsPerSample:8
							samplesPerPixel:4
							hasAlpha:YES
							isPlanar:NO
							colorSpaceName:NSCalibratedRGBColorSpace
							bytesPerRow:0
							bitsPerPixel:0] autorelease];
    NSImage *im;
    unsigned char *baseaddr=[bmp bitmapData];
    
    [self getPixels:baseaddr width:frame.size.width height:frame.size.height rowbyte:[bmp bytesPerRow]];
    
    im = [[[NSImage alloc] init] autorelease];
    [im addRepresentation:bmp];
   // [im setFlipped:YES];
    //[im lockFocusOnRepresentation:bmp];
    [im unlockFocus];
    
	[[im TIFFRepresentation] writeToFile:filename atomically:YES];
}
- (void)drawRect:(NSRect)rect
{
    float	aspectRatio,zoom=11;
    float   i;
    
	[self update];

    // init projection
        glViewport(0, 0, (GLsizei) rect.size.width, (GLsizei) rect.size.height);
		//glClearColor(27/255.0,41/255.0,38/255.0, 1);
		glClearColor(0,0,0, 1);
        glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT+GL_STENCIL_BUFFER_BIT);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        aspectRatio = (float)rect.size.width/(float)rect.size.height;
        glOrtho(-aspectRatio*zoom, aspectRatio*zoom, zoom,-zoom, -100.0, 100.0);

    // prepare drawing
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        gluLookAt (0,0,+10, 0,0,0, 0,1,0); // eye,center,updir
        glRotatef(m_tbRot[0],m_tbRot[1], m_tbRot[2], m_tbRot[3]);
        glRotatef(m_rotation[0],m_rotation[1],m_rotation[2],m_rotation[3]);

        if(trajectory)
		{
            if(P==0)
                i=0;
            else
                i=2*log(P)/log(2.0);
            if(i<0)
                i=0;
            printf("P: %g, i: %g, counter: %i\n",P,i,counter);
            
            glPolygonMode( GL_FRONT_AND_BACK, GL_FILL );
            trajectory_draw(trajectory,i,1);
            
            /*
            glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
            trajectory_draw(trajectory,i,0);
             */
            //trajectory_lines_draw(trajectory,i);
            
            // save image
            if(0)
            {
                NSString	*path=[NSString stringWithFormat:@"/Users/roberto/Desktop/model%03i.tif",counter];
                [self saveImage:path];
            }
		}

    [[self openGLContext] flushBuffer];
}
-(void)animate:(NSTimer*)theTimer
{
	//if(counter%10==0) [self save];

	counter++;
    
    P+=0.1;
    if(P>32)
        P=0;
    
    char    *thepath="/Users/roberto/trajectory/pictures/iter";

    [self display];
    if(flagSaveImages)
        [self savePicture:[NSString stringWithFormat:@"%s.%03i.jpg",thepath,counter]];
        
    /*
    m_tbRot[0]+=360.0/2000.0;
    m_tbRot[1]=0;
    m_tbRot[2]=1;
    m_tbRot[3]=0;
    */
}
- (void)mouseDown:(NSEvent *)e
{
	[m_trackball  start:[e locationInWindow] sender:self];
}
-(void) mouseUp:(NSEvent *)e
{
    // Accumulate the trackball rotation
    // into the current rotation.
    [m_trackball add:m_tbRot toRotation:m_rotation];

    m_tbRot[0]=0;
    m_tbRot[1]=1;
    m_tbRot[2]=0;
    m_tbRot[3]=0;
}
-(void) mouseDragged:(NSEvent *)e
{
	[m_trackball rollTo:[e locationInWindow] sender:self];
	[self setNeedsDisplay:YES];
}
-(void)addRotation:(float)value toAxis:(int)axis
{
	float	tmp[4]={0,0,0,0};
	tmp[axis]=1;
	tmp[0]=value;
	[m_trackball add:tmp toRotation:m_rotation];
	[self setNeedsDisplay:YES];
}
- (void)rotateBy:(float *)r
{
    m_tbRot[0] = r[0];
    m_tbRot[1] = r[1];
    m_tbRot[2] = r[2];
    m_tbRot[3] = r[3];
}
#pragma mark -
void inverse4x4(float b[16],float a[16])
{
	float d=	-a[0]*a[5]*a[10]*a[15]+a[0]*a[5]*a[11]*a[14]
	+a[0]*a[9]*a[6]*a[15]-a[0]*a[9]*a[7]*a[14]
	-a[0]*a[13]*a[6]*a[11]+a[0]*a[13]*a[7]*a[10]
	+a[4]*a[1]*a[10]*a[15]-a[4]*a[1]*a[11]*a[14]
	-a[4]*a[9]*a[2]*a[15]+a[4]*a[9]*a[3]*a[14]
	+a[4]*a[13]*a[2]*a[11]-a[4]*a[13]*a[3]*a[10]
	-a[8]*a[1]*a[6]*a[15]+a[8]*a[1]*a[7]*a[14]
	+a[8]*a[5]*a[2]*a[15]-a[8]*a[5]*a[3]*a[14]
	-a[8]*a[13]*a[2]*a[7]+a[8]*a[13]*a[3]*a[6]
	+a[12]*a[1]*a[6]*a[11]-a[12]*a[1]*a[7]*a[10]
	-a[12]*a[5]*a[2]*a[11]+a[12]*a[5]*a[3]*a[10]
	+a[12]*a[9]*a[2]*a[7]-a[12]*a[9]*a[3]*a[6];
	
	b[0]=-(a[5]*a[10]*a[15]-a[5]*a[11]*a[14]-a[9]*a[6]*a[15]+a[9]*a[7]*a[14]+a[13]*a[6]*a[11]-a[13]*a[7]*a[10])/d;
	b[1]=(a[1]*a[10]*a[15]-a[1]*a[11]*a[14]-a[9]*a[2]*a[15]+a[9]*a[3]*a[14]+a[13]*a[2]*a[11]-a[13]*a[3]*a[10])/d;
	b[2]=-(a[1]*a[6]*a[15]-a[1]*a[7]*a[14]-a[5]*a[2]*a[15]+a[5]*a[3]*a[14]+a[13]*a[2]*a[7]-a[13]*a[3]*a[6])/d;
	b[3]=(a[1]*a[6]*a[11]-a[1]*a[7]*a[10]-a[5]*a[2]*a[11]+a[5]*a[3]*a[10]+a[9]*a[2]*a[7]-a[9]*a[3]*a[6])/d;
	
	b[4]=(a[4]*a[10]*a[15]-a[4]*a[11]*a[14]-a[8]*a[6]*a[15]+a[8]*a[7]*a[14]+a[12]*a[6]*a[11]-a[12]*a[7]*a[10])/d;
	b[5]=(-a[0]*a[10]*a[15]+a[0]*a[11]*a[14]+a[8]*a[2]*a[15]-a[8]*a[3]*a[14]-a[12]*a[2]*a[11]+a[12]*a[3]*a[10])/d;
	b[6]=-(-a[0]*a[6]*a[15]+a[0]*a[7]*a[14]+a[4]*a[2]*a[15]-a[4]*a[3]*a[14]-a[12]*a[2]*a[7]+a[12]*a[3]*a[6])/d;
	b[7]=(-a[0]*a[6]*a[11]+a[0]*a[7]*a[10]+a[4]*a[2]*a[11]-a[4]*a[3]*a[10]-a[8]*a[2]*a[7]+a[8]*a[3]*a[6])/d;
	
	b[8]=-(a[4]*a[9]*a[15]-a[4]*a[11]*a[13]-a[8]*a[5]*a[15]+a[8]*a[7]*a[13]+a[12]*a[5]*a[11]-a[12]*a[7]*a[9])/d;
	b[9]=-(-a[0]*a[9]*a[15]+a[0]*a[11]*a[13]+a[8]*a[1]*a[15]-a[8]*a[3]*a[13]-a[12]*a[1]*a[11]+a[12]*a[3]*a[9])/d;
	b[10]=(-a[0]*a[5]*a[15]+a[0]*a[7]*a[13]+a[4]*a[1]*a[15]-a[4]*a[3]*a[13]-a[12]*a[1]*a[7]+a[12]*a[3]*a[5])/d;
	b[11]=-(-a[0]*a[5]*a[11]+a[0]*a[7]*a[9]+a[4]*a[1]*a[11]-a[4]*a[3]*a[9]-a[8]*a[1]*a[7]+a[8]*a[3]*a[5])/d;
	
	b[12]=(a[4]*a[9]*a[14]-a[4]*a[10]*a[13]-a[8]*a[5]*a[14]+a[8]*a[6]*a[13]+a[12]*a[5]*a[10]-a[12]*a[6]*a[9])/d;
	b[13]=(-a[0]*a[9]*a[14]+a[0]*a[10]*a[13]+a[8]*a[1]*a[14]-a[8]*a[2]*a[13]-a[12]*a[1]*a[10]+a[12]*a[2]*a[9])/d;
	b[14]=-(-a[0]*a[5]*a[14]+a[0]*a[6]*a[13]+a[4]*a[1]*a[14]-a[4]*a[2]*a[13]-a[12]*a[1]*a[6]+a[12]*a[2]*a[5])/d;
	b[15]=(-a[0]*a[5]*a[10]+a[0]*a[6]*a[9]+a[4]*a[1]*a[10]-a[4]*a[2]*a[9]-a[8]*a[1]*a[6]+a[8]*a[2]*a[5])/d;
}
void v_m(double *r,double *v,float *m)
{
	// v=1x3
	// m=4x4
	// r=1x3
	r[0]=v[0]*m[0*4+0]+v[1]*m[1*4+0]+v[2]*m[2*4+0] + m[3*4+0];
	r[1]=v[0]*m[0*4+1]+v[1]*m[1*4+1]+v[2]*m[2*4+1] + m[3*4+1];
	r[2]=v[0]*m[0*4+2]+v[1]*m[1*4+2]+v[2]*m[2*4+2] + m[3*4+2];
}
double norm3D(float3D a)
{
    double	xx;
    
    xx= sqrt(pow(a.x,2)+pow(a.y,2)+pow(a.z,2));
    return(xx);
}
double dot3D(float3D a, float3D b)
{
    double xx;
    
    xx=a.x*b.x + a.y*b.y + a.z*b.z;
    return(xx);
}

float3D cross3D(float3D a, float3D b)
{
    float3D	xx;
    
    xx.x = a.y*b.z - a.z*b.y;
    xx.y = -b.z*a.x + b.x*a.z; // SIGNS WERE INVERTED BEFORE!!!
    xx.z = a.x*b.y - a.y*b.x;
    return(xx);
}
float3D sub3D(float3D a, float3D b)
{
    float3D xx;
    
    xx.x=a.x-b.x;
    xx.y=a.y-b.y;
    xx.z=a.z-b.z;
    return(xx);
}
float3D add3D(float3D a, float3D b)
{
    float3D xx;
    
    xx.x=a.x+b.x;
    xx.y=a.y+b.y;
    xx.z=a.z+b.z;
    return(xx);
}
float3D sca3D(float3D a, float b)
{
    float3D	xx;
    
    xx.x = a.x*b;
    xx.y = a.y*b;
    xx.z = a.z*b;
    return(xx);
}
void printmat(float *M)
{
    printf("%.2f %.2f %.2f %.2f\n%.2f %.2f %.2f %.2f\n%.2f %.2f %.2f %.2f\n%.2f %.2f %.2f %.2f\n",
           M[0],M[1],M[2],M[3],
           M[4],M[5],M[6],M[7],
           M[8],M[9],M[10],M[11],
           M[12],M[13],M[14],M[15]);
}
void trajectory_draw(Mesh *tr,float time,int flag)
{
	int			a[3];
	float3D     v[3];
	int			i,j;
	double		d;
    float		M[16],invM[16],I[16]={0,0,-1,0, 0,1,0,0, 1,0,0,0, 0,0,-10,1};
	double		eye[3]={0,0,10},eye2[3];
	float3D     v1,v2,n;
    Mesh        m0,m1;
    int         t0,t1;
    float       dt;
    float       *col;
    int         *ne;
	
    if(time>=10)
        time=9.999;
    
    t0=(int)time;
    t1=t0+1;
    dt=time-t0;
    
    m0=tr[t0];
    m1=tr[t1];
    
    glGetFloatv(GL_MODELVIEW_MATRIX,M);
    //printmat(M);
	inverse4x4(invM,M);
    v_m(eye2,eye,I);//M);//invM);
    
    col=(float*)calloc(m0.np,sizeof(float));
    ne=(int*)calloc(m0.np,sizeof(float));
    
    glBegin(GL_TRIANGLES);
    
    // flat shading
    if(0)
	for(i=0;i<m0.nt;i++)
	{
		a[0]=m0.t[i].a;
		a[1]=m0.t[i].b;
		a[2]=m0.t[i].c;
		
		for(j=0;j<3;j++)
            v[j]=add3D(sca3D(m0.p[a[j]],1-dt),sca3D(m1.p[a[j]],dt));
        
		// lighting
        v1=sub3D(v[1],v[0]);
		v1=sca3D(v1,1/norm3D(v1));
		v2=sub3D(v[2],v[0]);
		v2=sca3D(v2,1/norm3D(v2));
		n=cross3D(v1,v2);
		n=sca3D(n,1/norm3D(n));
		v1=*(float3D*)eye2;
		v1=sca3D(v1,1/norm3D(v1));
		d=fabs(dot3D(v1,n));
        
		if(flag==1)
            glColor3f(d,d,d);
        else
            glColor3f(0,0,0);
		
		for(j=0;j<3;j++)
			glVertex3f(v[j].x,v[j].y,v[j].z);
	}

    // soft shading
    if(1)
    {
        for(i=0;i<m0.nt;i++)
        {
            a[0]=m0.t[i].a;
            a[1]=m0.t[i].b;
            a[2]=m0.t[i].c;
            
            for(j=0;j<3;j++)
                v[j]=add3D(sca3D(m0.p[a[j]],1-dt),sca3D(m1.p[a[j]],dt));
            
            // lighting
            v1=sub3D(v[1],v[0]);
            v1=sca3D(v1,1/norm3D(v1));
            v2=sub3D(v[2],v[0]);
            v2=sca3D(v2,1/norm3D(v2));
            n=cross3D(v1,v2);
            n=sca3D(n,1/norm3D(n));
            v1=*(float3D*)eye2;
            v1=sca3D(v1,1/norm3D(v1));
            d=fabs(dot3D(v1,n));
            
            col[a[0]]+=d;
            col[a[1]]+=d;
            col[a[2]]+=d;
            ne[a[0]]+=1;
            ne[a[1]]+=1;
            ne[a[2]]+=1;
        }
        for(i=0;i<m0.np;i++)
            col[i]=col[i]/(float)ne[i];
        for(i=0;i<m0.nt;i++)
        {
            a[0]=m0.t[i].a;
            a[1]=m0.t[i].b;
            a[2]=m0.t[i].c;

            for(j=0;j<3;j++)
            {
                v[j]=add3D(sca3D(m0.p[a[j]],1-dt),sca3D(m1.p[a[j]],dt));
                if(flag==1)
                    glColor3f(col[a[j]],col[a[j]],col[a[j]]);
                else
                {
                    glColor3f(0,0,0);
                    v[j].x*=1.001;
                    v[j].y*=1.001;
                    v[j].z*=1.001;
                }
                glVertex3f(v[j].x,v[j].y,v[j].z);
            }
        }
    }
    glEnd();
    
    free(col);
}
void trajectory_lines_draw(Mesh *tr,float time)
{
    int			i,j;
    float		M[16],invM[16];
    double		eye[3]={0,0,1},eye2[3];
    int         np=tr[0].np;
    float   black[]={0,0,0};
    
    glPolygonMode( GL_FRONT_AND_BACK, GL_LINE );
    glGetFloatv(GL_MODELVIEW_MATRIX,M);
    inverse4x4(invM,M);
    v_m(eye2,eye,invM);
    
    glBegin(GL_LINES);
    for(i=0;i<np;i+=10)
    {
        glColor3fv(black);
        for(j=0;j<10;j++)
        {
            glVertex3f(tr[j].p[i].x,tr[j].p[i].y,tr[j].p[i].z);
            glVertex3f(tr[j+1].p[i].x,tr[j+1].p[i].y,tr[j+1].p[i].z);
        }
    }
    glEnd();
}

-(IBAction)startStop:(id)sender
{
    if([sender intValue])
    {
        printf("start\n");
        P=0;
        counter=0;
        [timer setFireDate:[NSDate date]];
        [sender setTitle:@"Stop"];
    }
    else
    {
        printf("stop\n");
        [timer setFireDate:[NSDate distantFuture]];
        [sender setTitle:@"Start"];
    }
}
-(IBAction)saveImages:(id)sender
{
    if([sender intValue])
    {
        printf("save images\n");
        flagSaveImages=1;
        [sender setTitle:@"Do Not"];
    }
    else
    {
        printf("do not save images\n");
        flagSaveImages=0;
        [sender setTitle:@"Save Images"];
    }
}

- (void) savePicture:(NSString *)filename
{
    NSRect				bounds=[self bounds];
	int					i,j,W=bounds.size.width,H=bounds.size.height;
    NSData				*bmp2;
	NSBitmapImageRep	*bmp=[[NSBitmapImageRep alloc]
                              initWithBitmapDataPlanes:NULL
                              pixelsWide:W
                              pixelsHigh:H
                              bitsPerSample:8
                              samplesPerPixel:4
                              hasAlpha:YES
                              isPlanar:NO
                              colorSpaceName:NSDeviceRGBColorSpace
                              bytesPerRow:4*bounds.size.width
                              bitsPerPixel:0];
    unsigned char		*baseaddr=[bmp bitmapData],b[4];
    
    [self getPixels:baseaddr width:W height:H rowbyte:4*W];
	
	// flip
	for(i=0;i<bounds.size.width;i++)
		for(j=0;j<bounds.size.height/2;j++)
		{
			b[0]=baseaddr[4*(j*W+i)+0];
			b[1]=baseaddr[4*(j*W+i)+1];
			b[2]=baseaddr[4*(j*W+i)+2];
			b[3]=baseaddr[4*(j*W+i)+3];
			baseaddr[4*(j*W+i)+0]=baseaddr[4*((H-1-j)*W+i)+0];
			baseaddr[4*(j*W+i)+1]=baseaddr[4*((H-1-j)*W+i)+1];
			baseaddr[4*(j*W+i)+2]=baseaddr[4*((H-1-j)*W+i)+2];
			baseaddr[4*(j*W+i)+3]=baseaddr[4*((H-1-j)*W+i)+3];
			baseaddr[4*((H-1-j)*W+i)+0]=b[0];
			baseaddr[4*((H-1-j)*W+i)+1]=b[1];
			baseaddr[4*((H-1-j)*W+i)+2]=b[2];
			baseaddr[4*((H-1-j)*W+i)+3]=b[3];
		}
    
	bmp2=[bmp representationUsingType:NSJPEGFileType
						   properties:[NSDictionary dictionaryWithObject:[NSDecimalNumber numberWithFloat:0.8] forKey:NSImageCompressionFactor]];
	[bmp2 writeToFile:filename atomically:YES];
	[bmp release];
}
-(void)spin:(char*)thepath nframes:(int)nframes
{
	int		i;
	
	[self display];
	for(i=0;i<nframes;i++)
	{
		NSAutoreleasePool	*pool=[NSAutoreleasePool new];
		[self savePicture:[NSString stringWithFormat:@"%s.%03i.jpg",thepath,i]];
        
		m_tbRot[0]+=360.0/(float)nframes;
		m_tbRot[1]=0;
		m_tbRot[2]=1;
		m_tbRot[3]=0;
		
		//zoom-=0.005;
		[self display];
		[pool drain];
	}
}
void laplace_smooth(Mesh *m, float lambda)
{
    float3D *p,*p1,p2;
    int3D   *t;
    int np,nt;
    int *ne;
    int i;
    
    np=m->np;
    nt=m->nt;
    p=m->p;
    t=m->t;
    
    ne=(int*)calloc(np,sizeof(int));

    // compute number of neighbours in each 3d mesh
    for(i=0;i<nt;i++)
    {
        ne[t[i].a]+=2;
        ne[t[i].b]+=2;
        ne[t[i].c]+=2;
    }
    
    p1=(float3D*)calloc(np,sizeof(float3D));
    
    for(i=0;i<nt;i++)
    {
        p1[t[i].a]=add3D(p1[t[i].a],add3D(p[t[i].b],p[t[i].c]));
        p1[t[i].b]=add3D(p1[t[i].b],add3D(p[t[i].c],p[t[i].a]));
        p1[t[i].c]=add3D(p1[t[i].c],add3D(p[t[i].a],p[t[i].b]));
    }
    for(i=0;i<np;i++)
    {
        p2=sca3D(p1[i],1/(float)ne[i]);
        p[i]=add3D(sca3D(p[i],1-lambda),sca3D(p2,lambda));
    }
    
    free(ne);
    free(p1);
}
-(void)initTrajectory
{
    int i,j,k;
    int np,nt;
    float3D *p0,*p1;

    // init trajectory vector
    trajectory=(Mesh*)calloc(11,sizeof(Mesh));
    
    // load raw timepoints
    msh_importPlyMeshData(&(trajectory[0]),"/Users/roberto/trajectory/P0-F23_as_F01.ply");
    msh_importPlyMeshData(&(trajectory[2]),"/Users/roberto/trajectory/P2-F25_as_F01.ply");
    msh_importPlyMeshData(&(trajectory[4]),"/Users/roberto/trajectory/P4-F06_as_F01.ply");
    msh_importPlyMeshData(&(trajectory[6]),"/Users/roberto/trajectory/P8-F10_as_F01.ply");
    msh_importPlyMeshData(&(trajectory[8]),"/Users/roberto/trajectory/P16-F15_as_F01.ply");
    msh_importPlyMeshData(&(trajectory[10]),"/Users/roberto/trajectory/P32-F16_as_F01.ply");
    
    // init interpolated timepoints
    np=trajectory[0].np;
    nt=trajectory[0].nt;
    for(i=1;i<11;i+=2)
    {
        trajectory[i].np=trajectory[0].np;
        trajectory[i].nt=trajectory[0].nt;
        trajectory[i].p=(float3D*)calloc(np,sizeof(float3D));
        trajectory[i].t=(int3D*)calloc(nt,sizeof(int3D));
        for(j=0;j<nt;j++)
            trajectory[i].t[j]=trajectory[0].t[j];
    }
    

    // new points: midpoint
    for(i=1;i<11;i+=2)
    {
        p0=trajectory[i-1].p;
        p1=trajectory[i+1].p;
        
        for(j=0;j<np;j++)
            trajectory[i].p[j]=sca3D(add3D(p0[j],p1[j]),0.5);
    }
        
    // old points: weighted average. For point j: (1/8)p[j-1]+(3/4)p[j]+(1/8)p[j+1]
    for(i=2;i<10;i+=2)
    {
        p0=trajectory[i-1].p;
        p1=trajectory[i+1].p;
        for(j=0;j<np;j++)
            trajectory[i].p[j]=add3D(add3D(sca3D(p0[j],1/8.0),sca3D(trajectory[i].p[j],3/4.0)),sca3D(p1[j],1/8.0));
    }
    
    // Smooth transformation in time and space
    float3D tr0[11],tr1[11];
    float   w;
    int niter=10;
    for(k=0;k<niter;k++)
    {
        // smooth vertex trajectories
        for(i=0;i<np;i++)
        {
            for(j=0;j<11;j++)
                tr0[j]=trajectory[j].p[i];
            for(j=0;j<11;j++)
            {
                tr1[j]=(float3D){0,0,0};
                w=0;
                if(j-1>=0)
                {
                    tr1[j]=add3D(tr1[j],sca3D(tr0[j-1],1/8.0));
                    w+=1/8.0;
                }
                tr1[j]=add3D(tr1[j],sca3D(tr0[j],3/4.0));
                w+=3/4.0;
                if(j+1<11)
                {
                    tr1[j]=add3D(tr1[j],sca3D(tr0[j+1],1/8.0));
                    w+=1/8.0;
                }
                tr1[j]=sca3D(tr1[j],1/w);
            }
            for(j=0;j<11;j++)
                trajectory[j].p[i]=tr1[j];
        }

        // smooth mesh (laplacian smooth)
        for(j=0;j<11;j++)
            laplace_smooth(&(trajectory[j]),0.2);
    }
    
    // Init timer
    timer=[[NSTimer	timerWithTimeInterval:0.01
                                   target:self
                                 selector:@selector(animate:)
                                 userInfo:nil
                                  repeats:YES] retain];
    //[timer setFireDate:[NSDate distantFuture]];
    [timer setFireDate: [NSDate distantFuture]];
    [[NSRunLoop currentRunLoop] addTimer:timer  forMode:NSDefaultRunLoopMode];
    
    save_growth_curves(trajectory);

}
float triangle_area(float3D p0, float3D p1, float3D p2)
{
    float   a,b,c;    // side lengths
    float   s;        // semiperimeter
    float   area;
    
    a=norm3D(sub3D(p0,p1));
    b=norm3D(sub3D(p1,p2));
    c=norm3D(sub3D(p2,p0));
    s=(a+b+c)/2.0;
    
    if(s*(s-a)*(s-b)*(s-c)<0)
        area=0;
    else
        area=sqrt(s*(s-a)*(s-b)*(s-c));
    
    return area;
}
void save_growth_curves(Mesh *tr)
{
    int i,j;
    FILE *f;
    float3D *p;
    int3D *t=tr[0].t;
    float   *v,a;
    
    v=(float*)calloc(tr[0].np*11,sizeof(float));
    
    for(i=0;i<tr[0].nt;i++)
    {
        for(j=0;j<11;j++)
        {
            p=tr[j].p;
            a=triangle_area(p[t[i].a],p[t[i].b],p[t[i].c]);
            v[t[i].a*11+j]+=a;
            v[t[i].b*11+j]+=a;
            v[t[i].c*11+j]+=a;
        }
    }
    f=fopen("/Users/roberto/Desktop/growth_curves.txt","w");
    for(i=0;i<tr[0].np;i++)
    {
        for(j=0;j<11;j++)
            fprintf(f,"%g\t",v[i*11+j]);
        fprintf(f,"\n");
    }
    fclose(f);
    free(v);
}
int msh_importPlyMeshData(Mesh *mesh, char *path)
{
    FILE	*f;
    int		i,x;
    char	str[512],str1[256],str2[256];
    
    printf("Loading mesh %s\n",path);
    
    f=fopen(path,"r");
    if(f==NULL){printf("ERROR: Cannot open file\n");return 1;}
    
    // READ HEADER
    mesh->np=mesh->nt=0;
    do
    {
        fgets(str,511,f);
        sscanf(str," %s %s %i ",str1,str2,&x);
        if(strcmp(str1,"element")==0&&strcmp(str2,"vertex")==0)
            mesh->np=x;
        else
            if(strcmp(str1,"element")==0&&strcmp(str2,"face")==0)
                mesh->nt=x;
    }
    while(strcmp(str1,"end_header")!=0 && !feof(f));
    if(mesh->np*mesh->nt==0)
    {
        printf("ERROR: Bad Ply file header format\n");
        return 1;
    }
    (*mesh).p = (float3D*)calloc((*mesh).np,sizeof(float3D));
    (*mesh).t = (int3D*)calloc((*mesh).nt,sizeof(int3D));
    // READ VERTICES
    if(mesh->p==NULL){printf("ERROR: Not enough memory for mesh vertices\n");return 1;}
    for(i=0;i<mesh->np;i++)
    {
        fgets(str,512,f);
        sscanf(str," %f %f %f ",&((*mesh).p[i].x),&((*mesh).p[i].y),&((*mesh).p[i].z));
    }
    printf("Read %i vertices\n",mesh->np);
    
    // READ TRIANGLES
    if(mesh->t==NULL){printf("ERROR: Not enough memory for mesh triangles\n"); return 1;}
    for(i=0;i<mesh->nt;i++)
        fscanf(f," 3 %i %i %i ",&((*mesh).t[i].a),&((*mesh).t[i].b),&((*mesh).t[i].c));
    printf("Read %i triangles\n",mesh->nt);
    
    fclose(f);
    
    return 0;
}
-(IBAction)setTime:(id)sender
{
    P=[sender floatValue];
    
    [self setNeedsDisplay:YES];
}
@end