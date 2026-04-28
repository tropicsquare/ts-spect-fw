
; ==============================================================================
;  file    others/tmac_drng.s
;  author  vit.masek@tropicsquare.com
;
;  Copyright © 2023-2026 Tropic Square s.r.o. (https://tropicsquare.com/)
;  This work is subject to the license terms of the LICENSE file in the root
;  directory of this source tree.
;  If a copy of the LICENSE file was not distributed with this work, you can 
;  obtain one at (https://tropicsquare.com/license).
;
; ==============================================================================
;
; Utilize TMAC core as DRNG seeded form TRNG using GRV instruction.
; Used only for pseudo-random data for clean-up and precharge.
;
;        !!! MUST NOT be used as source of high entropy random data !!!
; !!! Keys and masks, which are security critical MUST be generated using GRV!!!
;
; API:
; - tmac_drng_seed_init
;     Initialize the seed to ca_tmac_drng_seed using initial entropy from GRV
;
; - tmac_drng_init
;     Initialize the TMAC core with the seed in ca_tmac_drng_seed.
;     Then updates the seed in ca_tmac_drng_seed for future calls.
;     The updated value is got as the first 32B output of the newly initialized
;     TMAC DRNG. To initialize with fresh entropy, the user must call
;     `tmac_drng_seed_init` before.
;
; - tmac_drng_get
;     Get next 32B using TMAC_RD and store it to address in r0
;
; The user may also get the next 32B using TMAC_RD directly to register.
; The user MUST take tract of the usage of the TMAC core by them self!
; The implementation does not ensure that the TMAC core is correctly initialized
; nor that the current TMAC state does not belong to other routine.
;
; ==============================================================================

tmac_drng_seed_init:
    GRV         r0
    ST          r0,  ca_tmac_drng_seed
    RET

tmac_drng_init:
    LD          r0,  ca_tmac_drng_seed
    MOV         r7,  r0
    ; Used the seed to get TMAC mask
    ; extend_tmac_mask uses SHA512 to extend 32B value to 128B
    CALL        extend_tmac_mask
    TMAC_IT     r7
    ; Use the seed for TMAC init string
    TMAC_IS     r0,  tmac_dst_drng
    ; Update the seed for future inits
    TMAC_RD     r0
    ST          r0,  ca_tmac_drng_seed
    RET

tmac_drng_get:
    TMAC_RD     r1
    STR         r1, r0
    RET
