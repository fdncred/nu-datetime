# nu-datetime

Published datetime formatters for [Nushell](https://www.nushell.sh/) 0.115+.

This module extends Nushell's built-in `date` family with a catalog of named standards (ISO 8601, RFCs, HTTP, LDAP, Excel, Unix epochs, and more). It does **not** replace `date now`, `date to-timezone`, `date humanize`, `date from-human`, `date list-timezone`, or the removed `date format` stub. Use `format date` when you need a custom strftime pattern.

## Requirements

- Nushell 0.115 or later

## Install

Clone or copy `date-formats.nu` somewhere on disk. There is no extra install step.

```nushell
# from the repo root
use ./date-formats.nu *

# or by absolute path
use ~/src/nu-datetime/date-formats.nu *

# `source` also works if you want the commands in the current scope
source date-formats.nu
```

Add the `use` line to your `config.nu` to load the module in every session.

## Quick start

Examples below use this instant:

```nushell
let t = 2023-05-15T12:34:56.123456789+00:00
```

```nushell
# current time, RFC 3339
date as rfc-3339

# pipeline input
$t | date as rfc-3339
# => 2023-05-15T12:34:56+00:00

# positional instant
date as rfc-3339 $t

# flag form (handy with --all)
date as rfc-3339 --now $t

# every catalog format as a table
date as --all --now $t

# browse the catalog
date list-formats
date list-formats --full
```

Format names and aliases complete at the prompt (`date as <tab>`).

## Commands

### `date as`

Format an instant using a published standard name or alias.

```
date as <format> [instant] [--now <datetime>] [--all]
```

| Argument | Meaning |
|---|---|
| `format` | Catalog name or alias. Required unless `--all`. |
| `instant` | Datetime to format. Optional. |
| `--now` | Same as `instant`, as a flag. Use with `--all`. |
| `--all` / `-a` | Render every catalog format as a table. Cannot be combined with `format`. |

**Where the instant comes from** (first match wins):

1. Positional `instant`
2. `--now`
3. Pipeline input, if it is a `datetime`
4. `date now`

Step 3 checks the type. Pipeline input that is *not* a `datetime` — a string, an
int, a list — does not raise; it falls through to `date now`, so a forgotten
`into datetime` formats the current instant instead of the value you piped in:

```nushell
"2023-05-15" | date as rfc-3339         # today, not 2023-05-15
"2023-05-15" | into datetime | date as rfc-3339   # the piped value, local offset
```

```nushell
# missing both a format and --all is an error
date as
# Error: date as requires a format name, or --all

# unknown name is an error
date as no-such-format $t
# Error: unknown datetime format: no-such-format
#   help: run `date list-formats` to see supported formats

# a format name plus --all is an error, not a silently ignored argument
date as rfc-3339 --all
# Error: date as --all renders every format; it cannot also take the format rfc-3339
```

`--all` returns a table with `name`, `value`, `standard`, and `description`. A
format that cannot represent the instant (see the nanosecond range note below)
has a `null` `value` instead of failing the whole table:

```nushell
date as --all --now $t | where name =~ "^rfc-3339"
```

```
╭───┬────────────────┬────────────────────────────────────┬──────────┬──────────────────────────────────────────────╮
│ # │      name      │               value                │ standard │                 description                  │
├───┼────────────────┼────────────────────────────────────┼──────────┼──────────────────────────────────────────────┤
│ 0 │ rfc-3339       │ 2023-05-15T12:34:56+00:00          │ RFC 3339 │ Internet date/time with colon offset         │
│ 1 │ rfc-3339-frac  │ 2023-05-15T12:34:56.123456789+00:00│ RFC 3339 │ Internet date/time with fractional seconds   │
│ 2 │ rfc-3339-space │ 2023-05-15 12:34:56+00:00          │ RFC 3339 │ Internet date/time with space instead of T   │
│ 3 │ rfc-3339-utc   │ 2023-05-15T12:34:56Z               │ RFC 3339 │ Internet date/time in UTC with Z             │
╰───┴────────────────┴────────────────────────────────────┴──────────┴──────────────────────────────────────────────╯
```

Names and aliases are case-insensitive: `date as RFC-3339`, `date as Json`, and `date as rfc-3339` are the same format.

### `date list-formats`

List every published format.

```nushell
date list-formats            # name, aliases, standard, description
date list-formats --full     # plus kind, tz, locale, pattern, unit, transform
date list-formats -f         # short flag for --full
```

```nushell
date list-formats | where standard == "RFC 3339"
date list-formats | where {|row| "json" in $row.aliases}
```

### Completions

`nu-complete date as` feeds tab completion for `date as`. Each name is annotated with its standard and description; aliases are marked as `alias of <name>`.

## Named helpers

These commands wrap `date as` for scripts that already call them. Prefer `date as <name>` in new code.

```nushell
utc $t                 # iso-8601-utc
iso-8601 $t
iso-8601-full $t
local-datetime $t      # process locale (%c)
rfc-2822 $t            # rfc-5322
rfc-850 $t
rfc-1036 $t            # rfc-822
rfc-1123 $t            # rfc-7231
rfc-822 $t
rfc-3339 $t
rfc-7231 $t
unix-timestamp $t           # seconds
unix-timestamp --nanos $t   # nanoseconds
```

Each helper accepts a positional datetime or pipeline input, same as `date as`:

```nushell
$t | rfc-3339
$t | unix-timestamp --nanos
```

## Timezone and locale

Each catalog entry has a `tz` policy:

- **`preserve`** — format the instant's own offset (no conversion).
- **`UTC`** — convert to UTC first (Z / GMT / `[UTC]`).

```nushell
let offset = 2023-05-15T12:34:56.123456789-05:00

$offset | date as iso-8601      # 2023-05-15T12:34:56-05:00   (preserve)
$offset | date as iso-8601-utc  # 2023-05-15T17:34:56Z        (UTC)
$offset | date as rfc-7231      # Mon, 15 May 2023 17:34:56 GMT
$offset | date as iso-9660      # 2023051512345612-20         (offset in 15-min units)
```

RFC / ISO weekday and month names always use the C locale (`Mon`, `May`), even if `LC_TIME` is French or another language.

`local-datetime`, `locale-date`, and `locale-time` follow the process locale (`%c`, `%x`, `%X`).

## Format catalog

Values are for `2023-05-15T12:34:56.123456789+00:00`.

### ISO 8601

| Name | Aliases | Example | Standard |
|---|---|---|---|
| `iso-8601` | `iso8601`, `iso` | `2023-05-15T12:34:56+00:00` | ISO 8601-1 |
| `iso-8601-full` | `iso-8601-frac` | `2023-05-15T12:34:56.123456789+00:00` | ISO 8601-1 |
| `iso-8601-basic` | | `20230515T123456+0000` | ISO 8601-1 |
| `iso-8601-utc` | `utc`, `zulu`, `z` | `2023-05-15T12:34:56Z` | ISO 8601-1 |
| `iso-8601-basic-utc` | | `20230515T123456Z` | ISO 8601-1 |
| `iso-8601-date` | `html-date`, `xsd-date`, `toml-local-date` | `2023-05-15` | ISO 8601-1 |
| `iso-8601-date-basic` | `iso-2014`, `ical-date`, `vcard-date`, `dicom-da` | `20230515` | ISO 8601-1 |
| `iso-8601-time` | `html-time`, `toml-local-time` | `12:34:56` | ISO 8601-1 |
| `iso-8601-time-basic` | | `123456` | ISO 8601-1 |
| `iso-8601-time-offset` | `xsd-time` | `12:34:56+00:00` | ISO 8601-1 |
| `iso-8601-minute` | `w3c-dtf-minute` | `2023-05-15T12:34+00:00` | W3C NOTE-datetime |
| `iso-8601-year-month` | `html-month` | `2023-05` | ISO 8601-1 |
| `iso-8601-year` | | `2023` | ISO 8601-1 |
| `iso-8601-week` | `html-week` | `2023-W20` | ISO 8601-1 |
| `iso-8601-week-date` | | `2023-W20-1` | ISO 8601-1 |
| `iso-8601-week-date-basic` | | `2023W201` | ISO 8601-1 |
| `iso-8601-week-datetime` | | `2023-W20-1T12:34:56+00:00` | ISO 8601-1 |
| `iso-8601-ordinal` | | `2023-135` | ISO 8601-1 |
| `iso-8601-ordinal-basic` | | `2023135` | ISO 8601-1 |
| `iso-8601-ordinal-datetime` | | `2023-135T12:34:56+00:00` | ISO 8601-1 |

```nushell
date as iso $t                  # alias of iso-8601
date as iso-8601-week-date $t   # 2023-W20-1
date as iso-8601-ordinal $t     # 2023-135
```

### Internet / RFC

| Name | Aliases | Example | Standard |
|---|---|---|---|
| `rfc-3339` | `rfc3339`, `atom`, `rfc-4287`, `json`, `rfc-7493`, `yaml-timestamp`, `xsd-dateTime`, `toml-offset-datetime`, `w3c-dtf` | `2023-05-15T12:34:56+00:00` | RFC 3339 |
| `rfc-3339-utc` | | `2023-05-15T12:34:56Z` | RFC 3339 |
| `rfc-3339-frac` | | `2023-05-15T12:34:56.123456789+00:00` | RFC 3339 |
| `rfc-3339-space` | | `2023-05-15 12:34:56+00:00` | RFC 3339 |
| `rfc-9557` | `ixdtf` | `2023-05-15T12:34:56.123456789+00:00[UTC]` | RFC 9557 |
| `rfc-5322` | `rfc-2822`, `rfc2822`, `rfc5322`, `email` | `Mon, 15 May 2023 12:34:56 +0000` | RFC 5322 |
| `rfc-822` | `rfc822`, `rfc-1036`, `rfc1036`, `rss` | `Mon, 15 May 23 12:34:56 +0000` | RFC 822 |
| `rfc-850` | `rfc850` | `Monday, 15-May-23 12:34:56 GMT` | RFC 850 |
| `rfc-7231` | `rfc-1123`, `rfc1123`, `rfc-9110`, `rfc9110`, `http-date`, `imf-fixdate`, `cookie`, `rfc-6265` | `Mon, 15 May 2023 12:34:56 GMT` | RFC 9110 |
| `rfc-5545` | `rfc5545`, `ical-utc` | `20230515T123456Z` | RFC 5545 |
| `ical-local` | `toml-local-datetime`, `html-datetime-local` | `20230515T123456` | RFC 5545 |
| `rfc-4517` | `ldap`, `ldap-generalized-time` | `20230515123456.123456Z` | RFC 4517 |
| `ldap-generalized-time-basic` | | `20230515123456Z` | RFC 4517 |

`rfc-3339-frac` and `rfc-9557` always render nine fractional digits, even for a
whole-second instant (`2023-05-15T12:34:56.000000000+00:00`), so their width is
fixed. Use `rfc-3339` when you want no fraction at all.

```nushell
# HTTP Date header (always GMT)
date as http-date $t
# => Mon, 15 May 2023 12:34:56 GMT

# JSON / Atom / YAML timestamp
date as json $t
# => 2023-05-15T12:34:56+00:00

# email Date: header
date as email $t
# => Mon, 15 May 2023 12:34:56 +0000
```

### Web / health

| Name | Aliases | Example | Standard |
|---|---|---|---|
| `ecma-262` | `js-iso`, `html-datetime` | `2023-05-15T12:34:56.123Z` | ECMA-262 |
| `odata-datetimeoffset` | | `2023-05-15T12:34:56.1234567Z` | OData |
| `fhir-datetime` | `fhir-dateTime` | `2023-05-15T12:34:56Z` | HL7 FHIR |

```nushell
date as js-iso $t
# => 2023-05-15T12:34:56.123Z
```

### Legacy, filesystems, SQL, .NET

| Name | Aliases | Example | Standard |
|---|---|---|---|
| `asctime` | `posix-asctime` | `Mon May 15 12:34:56 2023` | ANSI C |
| `asctime-gmt` | `http-asctime` | `Mon May 15 12:34:56 2023` | RFC 9110 |
| `local-datetime` | `locale` | locale `%c` | libc |
| `locale-date` | | locale `%x` | libc |
| `locale-time` | | locale `%X` | libc |
| `asn1-utctime` | | `230515123456Z` | X.680 / X.509 |
| `asn1-generalized-time` | | `20230515123456Z` | X.680 / X.509 |
| `asn1-generalized-time-frac` | | `20230515123456.123456Z` | X.680 / X.509 |
| `exif-datetime` | | `2023:05:15 12:34:56` | JEITA Exif |
| `dicom-tm` | | `123456.123456` | DICOM PS3.5 |
| `dicom-dt` | | `20230515123456.123456+0000` | DICOM PS3.5 |
| `nato-dtg` | | `151234Z MAY 23` | ACP 121 / MIL-STD-6040 |
| `nato-dtg-compact` | | `151234ZMAY23` | ACP 121 / MIL-STD-6040 |
| `iso-9660` | `ecma-119` | `2023051512345612+00` | ISO 9660 / ECMA-119 |
| `net-roundtrip` | | `2023-05-15T12:34:56.1234567+00:00` | .NET |
| `net-sortable` | | `2023-05-15T12:34:56` | .NET |
| `net-universal` | | `2023-05-15 12:34:56Z` | .NET |
| `sql-timestamp` | `iso-9075` | `2023-05-15 12:34:56` | ISO/IEC 9075 |
| `sql-timestamptz` | | `2023-05-15 12:34:56+00:00` | ISO/IEC 9075 |

Notes:

- `asctime` space-pads single-digit days: `Fri May  5 08:04:06 2023`.
- `asctime` is ANSI C `asctime()`: local time, offset preserved. `asctime-gmt`
  is RFC 9110's obsolete HTTP `asctime-date`, which must be GMT, so it converts
  first. They differ only off UTC:

  ```nushell
  $offset | date as asctime       # Mon May 15 12:34:56 2023
  $offset | date as asctime-gmt   # Mon May 15 17:34:56 2023
  ```
- `iso-9660` encodes the offset in 15-minute units (`-05:00` → `-20`).
- `nato-dtg` month names are uppercased.

```nushell
date as sql-timestamp $t
# => 2023-05-15 12:34:56

date as nato-dtg $t
# => 151234Z MAY 23
```

### Numeric / epoch

These return numbers, not strings.

| Name | Aliases | Example | Standard |
|---|---|---|---|
| `unix` | `epoch`, `posix-time`, `unix-timestamp` | `1684154096` | POSIX |
| `unix-ms` | `epoch-ms`, `javascript` | `1684154096123` | POSIX / ECMA-262 |
| `unix-us` | `epoch-us` | `1684154096123456` | POSIX |
| `unix-ns` | `epoch-ns` | `1684154096123456789` | POSIX |
| `julian-day` | `jd` | `2460080.024260688` | IAU / USNO |
| `modified-julian-day` | `mjd` | `60079.52426068815` | IAU / USNO |
| `rata-die` | `rd` | `738655` | Calendrical Calculations |
| `excel-1900` | | `45061.52426068815` | ECMA-376 |
| `excel-1904` | | `43599.52426068815` | ECMA-376 |
| `ntp` | | `3893142896.123457` | RFC 5905 |
| `filetime` | | `133286276961234567` | MS-DTYP |
| `cf-absolute` | `apple-epoch`, `nstimeinterval` | `705846896.1234567` | Apple CFAbsoluteTime |

```nushell
date as unix $t
# => 1684154096

date as unix-ns $t
# => 1684154096123456789

# nanoseconds survive a round-trip through Nushell datetime
date as unix-ns $t | into datetime | date as unix-ns
# => 1684154096123456789

# pre-epoch instants stay negative for Unix, positive for FILETIME
let apollo = 1969-07-20T20:17:40.123456789+00:00
date as unix $apollo        # -14182940
date as unix-ns $apollo     # -14182939876543211
date as filetime $apollo    # 116302906601234567
```

`unix-ns` and `filetime` count nanoseconds in a 64-bit integer, so they only
cover `1677-09-21` .. `2262-04-11` and raise an error outside that window.
Every other format, including `unix`, `unix-ms`, `unix-us`, `rata-die`, and the
Julian/Excel serials, works across the full `datetime` range:

```nushell
date as iso-8601 0001-01-01T00:00:00+00:00   # 0001-01-01T00:00:00+00:00
date as rata-die 0001-01-01T00:00:00+00:00   # 1
date as unix-ns  0001-01-01T00:00:00+00:00
# Error: instant out of range for nanosecond precision: 0001-01-01T00:00:00+00:00
```

- `unix` / `unix-ms` / `unix-us` / `unix-ns` — seconds / ms / µs / ns since 1970-01-01T00:00:00Z
- `julian-day` — Julian Day Number (UTC)
- `modified-julian-day` — JD − 2400000.5
- `rata-die` — day number with 0001-01-01 = 1 (UTC, floored)
- `excel-1900` / `excel-1904` — Excel serial date (Windows / Mac). `excel-1900`
  reproduces Excel's phantom `1900-02-29`, so serials before `1900-03-01` are
  one lower than a plain day count from `1899-12-31` (`1900-01-01` → `1`).
- `ntp` — seconds since 1900-01-01T00:00:00Z
- `filetime` — 100 ns ticks since 1601-01-01T00:00:00Z
- `cf-absolute` — seconds since 2001-01-01T00:00:00Z (`NSTimeInterval`)

## What this module does not do

It only **formats** an instant. Parsing, timezone conversion, and relative phrases stay on the builtins:

```nushell
date now
date to-timezone UTC
date list-timezone
"3 hours ago" | date from-human
date now | date humanize
"2023-05-15" | into datetime
$t | format date "%Y-%m-%d %H:%M"   # custom strftime
```

`date format` is not provided (Nushell removed that command). Use `format date` or `date as`.

## Tests

```nushell
# snapshots, aliases, helpers, API
nu tests/date-formats.nu
```

`std/testing` in Nushell 0.115 supplies only the `@test` attribute - it has no
`run-tests` command - so `main` in `tests/date-formats.nu` is the runner. An
external runner that understands those attributes (e.g. nutest) can also
discover them.

`main` discovers the `@test` commands from `scope commands` rather than listing
them, so adding a test is enough to have it run. Because Nushell cannot call a
command by name from a string, it passes the discovered names to a child `nu`
that sources the file; every check runs even when an earlier one fails, and each
failure prints its test name and the full error.

## License

[MIT](LICENSE)
