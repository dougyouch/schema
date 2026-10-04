# Changelog

## [0.7.4](https://github.com/dougyouch/schema/compare/v0.7.3...v0.7.4) (2026-10-04)


### Bug Fixes

* **array-headers:** fix nested field names, association columns and column collisions ([f0373e0](https://github.com/dougyouch/schema/commit/f0373e0450e9d474dcde5e02b1db76b9c7bbc7d4))
* **associations:** support dynamic types in anonymous parent classes ([45d22da](https://github.com/dougyouch/schema/commit/45d22da233ec97703ba3c3bd90a91e577bac5390))
* **cli:** write csv headers to stdout and lint schema-json2csv ([58ebb13](https://github.com/dougyouch/schema/commit/58ebb138d58cbddca60c2e7214ab980d3c0aae12))

## [0.7.3](https://github.com/dougyouch/schema/compare/v0.7.2...v0.7.3) (2026-10-04)


### Bug Fixes

* **array-headers:** map aliased associations once under their name ([20258e2](https://github.com/dougyouch/schema/commit/20258e22bb59bbfaac088a71dccd773b7ef9255c))
* **parsers:** accept signed exponents and treat nil as nil for array, hash and json ([d4ac539](https://github.com/dougyouch/schema/commit/d4ac539ceba92354b47504523c18bbe3ed209e09))

## [0.7.2](https://github.com/dougyouch/schema/compare/v0.7.1...v0.7.2) (2026-10-04)


### Bug Fixes

* **associations:** read type field aliases and handle bad hash-keyed entries ([d5bdb05](https://github.com/dougyouch/schema/commit/d5bdb05c4ce90cd40e50f1619829f0e29082cec6))
* **model:** honor skip_fields for any key style and fix key lookup edge cases ([3ca3450](https://github.com/dougyouch/schema/commit/3ca34500f71e62c9bfcf0c49419bac22bdfc56bd))
* **parsers:** anchor parser regexes and reject non-finite floats as integers ([0514bd6](https://github.com/dougyouch/schema/commit/0514bd6175031a146bbc3a5d178b9e0fd32b4c7f))

## [0.7.1](https://github.com/dougyouch/schema/compare/v0.7.0...v0.7.1) (2026-10-04)


### Bug Fixes

* **specs:** replace deprecated SimpleCov API calls ([dadae4a](https://github.com/dougyouch/schema/commit/dadae4aa2d0246e964fdb160e1b505187e3fadc6))
* **specs:** wrap trailing hash literals in braces per Style/HashAsLastArrayItem ([cf8f18a](https://github.com/dougyouch/schema/commit/cf8f18af5b7c472298c7c0cbd7b6176356b476fc))
