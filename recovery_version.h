#ifndef __RECOVERY_VERSION_H__
#define __RECOVERY_VERSION_H__

#include "recovery_autogenerate.h"
/* define in makefile
 * GIT_COMMIT_INFO
 * major.minor.revision-gX
 * major:main version number, increase when there are significant changes
 * minor:minor version number, increase when there is an increase in functionality or features
 * revision:revised version number, increase when there are bug fixes or minor modifications
*/
#define PLAIN_VERSION   "V1.0.1"
#define _CONS(str1,str2)    str1 #str2
#define CONS(A,B)           _CONS(A,B)
#define RECOVERY_VERSION_STRING CONS(PLAIN_VERSION, GIT_COMMIT_INFO)

#endif  /* __RECOVERY_VERSION_H__ */