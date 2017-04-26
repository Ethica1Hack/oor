/*
 *
 * Copyright (C) 2011, 2015 Cisco Systems, Inc.
 * Copyright (C) 2015 CBA research group, Technical University of Catalonia.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at:
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#include "util.h"
#include "oor_log.h"



static inline int
convert_hex_char_to_byte (char val)
{
    val = (char)toupper (val);

    switch (val){
    case '0':
        return (0);
    case '1':
        return (1);
    case '2':
        return (2);
    case '3':
        return (3);
    case '4':
        return (4);
    case '5':
        return (5);
    case '6':
        return (6);
    case '7':
        return (7);
    case '8':
        return (8);
    case '9':
        return (9);
    case 'A':
        return (10);
    case 'B':
        return (11);
    case 'C':
        return (12);
    case 'D':
        return (13);
    case 'E':
        return (14);
    case 'F':
        return (15);
    default:
        return (-1);
    }
}

int
convert_hex_string_to_bytes(char *hex, uint8_t *bytes, int bytes_len)
{
    int         ctr = 0;
    char        hex_digit[2];
    int         partial_byte[2] = {0,0};

    while (hex[ctr] != '\0' && ctr <= bytes_len * 2) {
        ctr++;
    }
    if (hex[ctr] != '\0' && ctr != bytes_len * 2) {
        return (BAD);
    }

    for (ctr = 0; ctr < bytes_len; ctr++) {
        hex_digit[0] = hex[ctr * 2];
        hex_digit[1] = hex[ctr * 2 + 1];
        partial_byte[0] = convert_hex_char_to_byte(hex_digit[0]);
        partial_byte[1] = convert_hex_char_to_byte(hex_digit[1]);
        if (partial_byte[0] == -1 || partial_byte[1] == -1) {
            OOR_LOG(LDBG_2, "convert_hex_string_to_bytes: Invalid hexadecimal"
                    " number");
            return (BAD);
        }
        bytes[ctr] = partial_byte[0] * 16 + partial_byte[1];
    }
    return (GOOD);
}


char *
get_char_from_xTR_ID (lisp_xtr_id *xtrid)
{
    static char         xTR_ID_str[33];
    int                 ctr             = 0;

    memset (xTR_ID_str,0,33);

    for (ctr = 0 ; ctr < 16; ctr++){
        sprintf(xTR_ID_str, "%s%02x", xTR_ID_str, xtrid->byte[ctr]);
    }
    return (xTR_ID_str);
}

/* Remove the address from the list not compatible with the local RLOCs */

void
addr_list_rm_not_compatible_addr(glist_t *addr_lst, int compatible_addr_flags)
{
    glist_entry_t *it_addr, *aux_it_addr;
    lisp_addr_t *addr;

    glist_for_each_entry_safe(it_addr, aux_it_addr, addr_lst){
        addr = (lisp_addr_t *)glist_entry_data(it_addr);
        if (!is_compatible_addr(addr,compatible_addr_flags)){
            glist_remove(it_addr,addr_lst);
        }
    }
}

uint8_t
is_compatible_addr(lisp_addr_t *addr, int compatible_addr_flags)
{
    lisp_addr_t *ip_addr = lisp_addr_get_ip_addr(addr);
    int afi = lisp_addr_ip_afi(ip_addr);
    switch(afi){
    case AF_INET:
        return ((compatible_addr_flags & IPv4_SUPPORT) != 0);
    case AF_INET6:
        return ((compatible_addr_flags & IPv6_SUPPORT) != 0);
    default:
        return (FALSE);
    }
}

/*
 * Fill dst from src removing spaces.
 * Dst should already be allocated and have enough space
 */
void
str_rm_spaces(char *src, char *dst)
{
    int s, d=0;
    for (s=0; src[s] != 0; s++){
        if (src[s] != ' ') {
            dst[d] = src[s];
            d++;
        }
    }
    dst[d] = 0;
}

/*
 * Fill dst from src removing double spaces.
 * Dst should already be allocated and have enough space
 */
void
str_rm_double_spaces(char *src, char *dst)
{
    int s, d=0;
    uint8_t is_prev_space;
    for (s=0; src[s] != 0; s++){
        if (src[s] == ' ') {
            if (is_prev_space == FALSE){
                dst[d] = src[s];
                d++;
                is_prev_space = TRUE;
            }
        }else{
            dst[d] = src[s];
            d++;
            is_prev_space = FALSE;
        }
    }
    dst[d] = 0;
}

void
locators_classify_in_4_6(mapping_t *mapping, glist_t *loc_loct_addr,
        glist_t *ipv4_loct_list, glist_t *ipv6_loct_list, get_fwd_ip_addr fwd_if)
{
    locator_t *locator;
    lisp_addr_t *addr;
    lisp_addr_t *ip_addr;

    if (glist_size(mapping->locators_lists) == 0){
        OOR_LOG(LDBG_3,"locators_classify_in_4_6: No locators to classify for mapping with eid %s",
                lisp_addr_to_char(mapping_eid(mapping)));
        return;
    }
    mapping_foreach_active_locator(mapping,locator){
        addr = locator_addr(locator);
        ip_addr = fwd_if(addr,loc_loct_addr);
        if (ip_addr == NULL){
            OOR_LOG(LDBG_2,"locators_classify_in_4_6: No IP address for %s", lisp_addr_to_char(addr));
            continue;
        }

        if (lisp_addr_ip_afi(ip_addr) == AF_INET){
            glist_add(locator,ipv4_loct_list);
        }else{
            glist_add(locator,ipv6_loct_list);
        }
    }mapping_foreach_active_locator_end;
}
