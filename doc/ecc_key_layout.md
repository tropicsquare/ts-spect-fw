# ECC Keys Layout in Key Memory

User slot = x

Physical private key slot = 2x

Physical public key slo = 2x + 1

## Private Key Slot

| offset | key |
| - | - |
| 0 | d/s |
| 8 | w/prefix |

## Public Key Slot

| offset | key |
| - | - |
| 0 | metadata |
| 8 | Ax |
| 16 | Ay |
