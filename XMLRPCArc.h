//
//  XMLRPCArc.h
//  XMLRPC
//
//  Created by Scott Little on 5/8/15.
//
//

#if __has_feature(objc_arc)
#define	RETAIN(x)		(x)
#define RELEASE(x)		(x)
#define AUTORELEASE(x)	(x)
#define DEALLOC(x)
#else
#define	RETAIN(x)		[(x) retain]
#define RELEASE(x)		[(x) release]
#define AUTORELEASE(x)	[(x) autorelease]
#define DEALLOC(x)		[(x) dealloc]
#endif
