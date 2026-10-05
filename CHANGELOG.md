# Changelog

## [0.12.0](https://github.com/dougyouch/schema/compare/v0.11.0...v0.12.0) (2026-10-05)


### ⚠ BREAKING CHANGES

* with Schema::All, a parsing error's type is now the code symbol (e.g. :invalid) instead of the message string; messages are unchanged.

### Features

* decimal type, datetime alias, association was_set? and parsing error codes ([e93e683](https://github.com/dougyouch/schema/commit/e93e6836e98efcdf01da656818f70ec305f59871))

## [0.11.0](https://github.com/dougyouch/schema/compare/v0.10.0...v0.11.0) (2026-10-05)


### ⚠ BREAKING CHANGES

* **gem:** Ruby 3.2 reached end of life in March 2026 and is no longer supported. CI now tests Ruby 3.3 and the .ruby-version Ruby, both with Gemfile.lock and the coverage gate.

### Build System

* **gem:** require ruby 3.3 ([412cb95](https://github.com/dougyouch/schema/commit/412cb95c84f26623fb9b3d67257f3339390e952f))

## [0.10.0](https://github.com/dougyouch/schema/compare/v0.9.1...v0.10.0) (2026-10-04)


### ⚠ BREAKING CHANGES

* **parsers:** string_or_nil now returns nil for whitespace-only strings such as "   ", matching how blank strings parse for the other types. Other strings are still kept as is.

### Features

* **model:** add as_json only_set and handle input that is not a hash ([bdda922](https://github.com/dougyouch/schema/commit/bdda922bd6e4b7fbb2c31e0ada74596b67a3d5e7))
* **parsers:** treat whitespace-only strings as nil for string_or_nil ([7313c99](https://github.com/dougyouch/schema/commit/7313c99bb0de5e340ad92cc958a1b601a5e3e15c))


### Bug Fixes

* **arrays:** raise a clear error for has_many without size ([617cb89](https://github.com/dougyouch/schema/commit/617cb89d9cbb028560d2148d4450e7d77689b877))
* **cli:** report malformed json without a backtrace ([fc2f1f9](https://github.com/dougyouch/schema/commit/fc2f1f95df5681184cc80850a18d40cffeede121))
* **csv:** strip the utf-8 byte order mark and handle empty header cells ([ad0216d](https://github.com/dougyouch/schema/commit/ad0216d429c881582d949ee2785e2e729d28bd23))

## [0.9.1](https://github.com/dougyouch/schema/compare/v0.9.0...v0.9.1) (2026-10-04)


### Bug Fixes

* **associations:** keep association defaults out of the set values ([3d90df3](https://github.com/dougyouch/schema/commit/3d90df3f8e8fa0b5da75cb313137d76a49106091))

## [0.9.0](https://github.com/dougyouch/schema/compare/v0.8.0...v0.9.0) (2026-10-04)


### Features

* **model:** add set_attribute_values, parsed_and_valid? and full_error_messages ([0c8b922](https://github.com/dougyouch/schema/commit/0c8b922cb4417720b70d069a8c51fb80b3b1c644))


### Bug Fixes

* **validator:** fail schema validation on nested parsing errors ([b17704a](https://github.com/dougyouch/schema/commit/b17704af2629d3a4a81ee69f748e216a8c5d7488))

## [0.8.0](https://github.com/dougyouch/schema/compare/v0.7.4...v0.8.0) (2026-10-04)


### ⚠ BREAKING CHANGES

* **model:** unrecognized boolean strings, and dates that aren't ISO 8601, are now invalid instead of false or a guessed date; blank strings parse to nil instead of being invalid (integer, float, date, time) or false (boolean); with ActiveModel, parsing_errors messages are readable text such as "is invalid" instead of codes such as "invalid"; capture_unknown_attributes= now changes nested association classes; and models compare by value with ==.

### Features

* **model:** stricter parsing, readable parsing errors and model helpers ([9267d77](https://github.com/dougyouch/schema/commit/9267d770f79b260bae2b3890f31f583e1684bdbe))

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
