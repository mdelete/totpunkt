# Totpunkt

_german lit. "dead point", meaning "dead center"._

"...the dead centre is any position of a crank where the applied force is straight along its axis, meaning no turning force can be applied." -- [from Wikipedia](https://en.wikipedia.org/wiki/Dead_centre_(engineering))

## TOTP Schema

    otpauth://totp/The%20Issuer:your%40email.com?[issuer=The%20Issuer]&secret=ABCDEFGHIJKLMNOP&algorithm=SHA1(default)|SHA256|SHA512&digits=6(default)|7|8&period=15|30(default)|60

## HOTP Schema (not supported yet)

    otpauth://hotp/The%20Issuer:your%40email.com?[issuer=The%20Issuer]&secret=ABCDEFGHIJKLMNOP&algorithm=SHA1(default)|SHA256|SHA512&digits=6(default)|7|8&counter=N
