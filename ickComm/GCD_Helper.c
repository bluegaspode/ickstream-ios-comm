//
//  GCD_Helper.c
//  ickComm
//
//  Created by Jörg Schwieder on 25.02.14.
//  Copyright (c) 2014 ickStream GmbH. All rights reserved.
//

#include <stdio.h>
#include "GCD_Helper.h"
#include <dispatch/dispatch.h>

static void * ickStream_main_queue_context = "com.ickStream.main.queue";

void dispatch_sync_init() {
    dispatch_queue_set_specific(dispatch_get_main_queue(), ickStream_main_queue_context, ickStream_main_queue_context, NULL);
}

void * dispatch_get_ickStream_main_key() {
    return ickStream_main_queue_context;
}



