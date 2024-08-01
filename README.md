# Totpunkt

_german lit. "dead point", meaning "dead center"._

"...the dead centre is any position of a crank where the applied force is straight along its axis, meaning no turning force can be applied." -- [from Wikipedia](https://en.wikipedia.org/wiki/Dead_centre_(engineering))

## TOTP Schema

    otpauth://totp/The%20Issuer:your%40email.com?[issuer=The%20Issuer]&secret=ABCDEFGHIJKLMNOP&algorithm=SHA1(default)|SHA256|SHA512&digits=6(default)|7|8&period=15|30(default)|60

## OTP Migration Schema

Some weird propietary export format used in the google authenticator app. At least google authenticator has an export format...

    otpauth-migration://offline?data=<BASE64_ENCODED_PROTOBUF>
    
The protobuf payload was reverse engineered by [Alexander Bakker](https://alexbakker.me/post/parsing-google-auth-export-qr-code.html) and licensed under [CC BY-SA 4.0](https://creativecommons.org/licenses/by-sa/4.0/). _otpauth-migration.pb.swift_ was generated using _protoc_ and this work.

## HOTP Schema (not supported)

    otpauth://hotp/The%20Issuer:your%40email.com?[issuer=The%20Issuer]&secret=ABCDEFGHIJKLMNOP&algorithm=SHA1(default)|SHA256|SHA512&digits=6(default)|7|8&counter=N

