//
//  GCD_Helper.h
//  ickStreamProto
//
//  Created by Jörg Schwieder on 10.07.12.
//  Copyright (c) 2012 Du!Business GmbH. All rights reserved.
//

#ifndef ickStreamProto_GCD_Helper_h
#define ickStreamProto_GCD_Helper_h

#include <dispatch/dispatch.h>


void dispatch_sync_init(void);

void * dispatch_get_ickStream_main_key(void);

static inline void dispatch_sync_safe(dispatch_queue_t queue, dispatch_block_t block)
{
    if (dispatch_get_specific(dispatch_get_ickStream_main_key())) {
        //if (queue == dispatch_get_current_queue()) {
        block();
    } else {
        dispatch_sync(queue, block);
    }
}

static inline int dispatch_is_main_queue() {
    if (dispatch_get_specific(dispatch_get_ickStream_main_key()))
        return 1;
    return 0;
}


#endif
