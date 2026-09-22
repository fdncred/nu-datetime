# Regression tests for date-formats.nu
#
#   nu tests/date-formats.nu
#
# `std/testing` supplies only the `@test` attribute in Nushell 0.115 - it has
# no `run-tests` command - so `main` below is the runner. Any external runner
# that understands those attributes (e.g. nutest) can discover them too.
#
# `main` discovers the `@test` commands instead of listing them, so a new test
# runs as soon as it is written; see the comment on `main` for how.

use std/testing *
use std/assert
use ../date-formats.nu *

const SAMPLE = 2023-05-15T12:34:56.123456789+00:00
const OFFSET = 2023-05-15T12:34:56.123456789-05:00
const PAD = 2023-05-05T08:04:06+00:00
const PAST = 1969-07-20T20:17:40.123456789+00:00
const WHOLE = 2023-05-15T12:34:56+00:00
const ANCIENT = 0001-01-01T00:00:00+00:00
const FUTURE = 9999-12-31T00:00:00+00:00

# Locale-dependent catalog names: compared to `format date`, not a snapshot.
const LOCALE_FORMATS = [
  [name pattern];
  [local-datetime "%c"]
  [locale-date "%x"]
  [locale-time "%X"]
]

# Fixed-instant snapshots for every other catalog name.
const EXPECTED = [
  [name value];
  [iso-8601 "2023-05-15T12:34:56+00:00"]
  [iso-8601-full "2023-05-15T12:34:56.123456789+00:00"]
  [iso-8601-basic "20230515T123456+0000"]
  [iso-8601-utc "2023-05-15T12:34:56Z"]
  [iso-8601-basic-utc "20230515T123456Z"]
  [iso-8601-date "2023-05-15"]
  [iso-8601-date-basic "20230515"]
  [iso-8601-time "12:34:56"]
  [iso-8601-time-basic "123456"]
  [iso-8601-time-offset "12:34:56+00:00"]
  [iso-8601-minute "2023-05-15T12:34+00:00"]
  [iso-8601-year-month "2023-05"]
  [iso-8601-year "2023"]
  [iso-8601-week "2023-W20"]
  [iso-8601-week-date "2023-W20-1"]
  [iso-8601-week-date-basic "2023W201"]
  [iso-8601-week-datetime "2023-W20-1T12:34:56+00:00"]
  [iso-8601-ordinal "2023-135"]
  [iso-8601-ordinal-basic "2023135"]
  [iso-8601-ordinal-datetime "2023-135T12:34:56+00:00"]
  [rfc-3339 "2023-05-15T12:34:56+00:00"]
  [rfc-3339-utc "2023-05-15T12:34:56Z"]
  [rfc-3339-frac "2023-05-15T12:34:56.123456789+00:00"]
  [rfc-3339-space "2023-05-15 12:34:56+00:00"]
  [rfc-9557 "2023-05-15T12:34:56.123456789+00:00[UTC]"]
  [rfc-5322 "Mon, 15 May 2023 12:34:56 +0000"]
  [rfc-822 "Mon, 15 May 23 12:34:56 +0000"]
  [rfc-850 "Monday, 15-May-23 12:34:56 GMT"]
  [rfc-7231 "Mon, 15 May 2023 12:34:56 GMT"]
  [rfc-5545 "20230515T123456Z"]
  [ical-local "20230515T123456"]
  [rfc-4517 "20230515123456.123456Z"]
  [ldap-generalized-time-basic "20230515123456Z"]
  [ecma-262 "2023-05-15T12:34:56.123Z"]
  [odata-datetimeoffset "2023-05-15T12:34:56.1234567Z"]
  [fhir-datetime "2023-05-15T12:34:56Z"]
  [asctime "Mon May 15 12:34:56 2023"]
  [asctime-gmt "Mon May 15 12:34:56 2023"]
  [asn1-utctime "230515123456Z"]
  [asn1-generalized-time "20230515123456Z"]
  [asn1-generalized-time-frac "20230515123456.123456Z"]
  [exif-datetime "2023:05:15 12:34:56"]
  [dicom-tm "123456.123456"]
  [dicom-dt "20230515123456.123456+0000"]
  [nato-dtg "151234Z MAY 23"]
  [nato-dtg-compact "151234ZMAY23"]
  [iso-9660 "2023051512345612+00"]
  [net-roundtrip "2023-05-15T12:34:56.1234567+00:00"]
  [net-sortable "2023-05-15T12:34:56"]
  [net-universal "2023-05-15 12:34:56Z"]
  [sql-timestamp "2023-05-15 12:34:56"]
  [sql-timestamptz "2023-05-15 12:34:56+00:00"]
  [unix 1684154096]
  [unix-ms 1684154096123]
  [unix-us 1684154096123456]
  [unix-ns 1684154096123456789]
  [julian-day 2460080.024260688]
  [modified-julian-day 60079.52426068815]
  [rata-die 738655]
  [excel-1900 45061.52426068815]
  [excel-1904 43599.52426068815]
  [ntp 3893142896.123457]
  [filetime 133286276961234567]
  [cf-absolute 705846896.1234567]
]

def format-failures [instant: datetime, cases: table]: nothing -> table {
  $cases
  | each {|row|
      # `$instant` is always supplied, so the row that `each` pipes in is
      # never used as the instant.
      let actual = date as $row.name $instant
      if $actual != $row.value {
        {name: $row.name, expected: $row.value, actual: $actual}
      }
    }
  | compact
}

def assert-no-failures [failures: table, label: string] {
  assert ($failures | is-empty) $"($label): ($failures | to nuon)"
}

# --- one test per catalog format --------------------------------------------

@test
def iso_8601 [] { assert equal (date as iso-8601 $SAMPLE) "2023-05-15T12:34:56+00:00" }

@test
def iso_8601_full [] { assert equal (date as iso-8601-full $SAMPLE) "2023-05-15T12:34:56.123456789+00:00" }

@test
def iso_8601_basic [] { assert equal (date as iso-8601-basic $SAMPLE) "20230515T123456+0000" }

@test
def iso_8601_utc [] { assert equal (date as iso-8601-utc $SAMPLE) "2023-05-15T12:34:56Z" }

@test
def iso_8601_basic_utc [] { assert equal (date as iso-8601-basic-utc $SAMPLE) "20230515T123456Z" }

@test
def iso_8601_date [] { assert equal (date as iso-8601-date $SAMPLE) "2023-05-15" }

@test
def iso_8601_date_basic [] { assert equal (date as iso-8601-date-basic $SAMPLE) "20230515" }

@test
def iso_8601_time [] { assert equal (date as iso-8601-time $SAMPLE) "12:34:56" }

@test
def iso_8601_time_basic [] { assert equal (date as iso-8601-time-basic $SAMPLE) "123456" }

@test
def iso_8601_time_offset [] { assert equal (date as iso-8601-time-offset $SAMPLE) "12:34:56+00:00" }

@test
def iso_8601_minute [] { assert equal (date as iso-8601-minute $SAMPLE) "2023-05-15T12:34+00:00" }

@test
def iso_8601_year_month [] { assert equal (date as iso-8601-year-month $SAMPLE) "2023-05" }

@test
def iso_8601_year [] { assert equal (date as iso-8601-year $SAMPLE) "2023" }

@test
def iso_8601_week [] { assert equal (date as iso-8601-week $SAMPLE) "2023-W20" }

@test
def iso_8601_week_date [] { assert equal (date as iso-8601-week-date $SAMPLE) "2023-W20-1" }

@test
def iso_8601_week_date_basic [] { assert equal (date as iso-8601-week-date-basic $SAMPLE) "2023W201" }

@test
def iso_8601_week_datetime [] { assert equal (date as iso-8601-week-datetime $SAMPLE) "2023-W20-1T12:34:56+00:00" }

@test
def iso_8601_ordinal [] { assert equal (date as iso-8601-ordinal $SAMPLE) "2023-135" }

@test
def iso_8601_ordinal_basic [] { assert equal (date as iso-8601-ordinal-basic $SAMPLE) "2023135" }

@test
def iso_8601_ordinal_datetime [] { assert equal (date as iso-8601-ordinal-datetime $SAMPLE) "2023-135T12:34:56+00:00" }

@test
def rfc_3339 [] { assert equal (date as rfc-3339 $SAMPLE) "2023-05-15T12:34:56+00:00" }

@test
def rfc_3339_utc [] { assert equal (date as rfc-3339-utc $SAMPLE) "2023-05-15T12:34:56Z" }

@test
def rfc_3339_frac [] { assert equal (date as rfc-3339-frac $SAMPLE) "2023-05-15T12:34:56.123456789+00:00" }

@test
def rfc_3339_space [] { assert equal (date as rfc-3339-space $SAMPLE) "2023-05-15 12:34:56+00:00" }

@test
def rfc_9557 [] { assert equal (date as rfc-9557 $SAMPLE) "2023-05-15T12:34:56.123456789+00:00[UTC]" }

@test
def rfc_5322 [] { assert equal (date as rfc-5322 $SAMPLE) "Mon, 15 May 2023 12:34:56 +0000" }

@test
def rfc_822 [] { assert equal (date as rfc-822 $SAMPLE) "Mon, 15 May 23 12:34:56 +0000" }

@test
def rfc_850 [] { assert equal (date as rfc-850 $SAMPLE) "Monday, 15-May-23 12:34:56 GMT" }

@test
def rfc_7231 [] { assert equal (date as rfc-7231 $SAMPLE) "Mon, 15 May 2023 12:34:56 GMT" }

@test
def rfc_5545 [] { assert equal (date as rfc-5545 $SAMPLE) "20230515T123456Z" }

@test
def ical_local [] { assert equal (date as ical-local $SAMPLE) "20230515T123456" }

@test
def rfc_4517 [] { assert equal (date as rfc-4517 $SAMPLE) "20230515123456.123456Z" }

@test
def ldap_generalized_time_basic [] { assert equal (date as ldap-generalized-time-basic $SAMPLE) "20230515123456Z" }

@test
def ecma_262 [] { assert equal (date as ecma-262 $SAMPLE) "2023-05-15T12:34:56.123Z" }

@test
def odata_datetimeoffset [] { assert equal (date as odata-datetimeoffset $SAMPLE) "2023-05-15T12:34:56.1234567Z" }

@test
def fhir_datetime [] { assert equal (date as fhir-datetime $SAMPLE) "2023-05-15T12:34:56Z" }

@test
def fhir_dateTime_official_alias [] { assert equal (date as fhir-dateTime $SAMPLE) "2023-05-15T12:34:56Z" }

@test
def asctime [] { assert equal (date as asctime $SAMPLE) "Mon May 15 12:34:56 2023" }

@test
def asctime_gmt [] { assert equal (date as asctime-gmt $SAMPLE) "Mon May 15 12:34:56 2023" }

@test
def local_datetime [] {
  assert equal (date as local-datetime $SAMPLE) ($SAMPLE | format date "%c")
}

@test
def locale_date [] {
  assert equal (date as locale-date $SAMPLE) ($SAMPLE | format date "%x")
}

@test
def locale_time [] {
  assert equal (date as locale-time $SAMPLE) ($SAMPLE | format date "%X")
}

@test
def asn1_utctime [] { assert equal (date as asn1-utctime $SAMPLE) "230515123456Z" }

@test
def asn1_generalized_time [] { assert equal (date as asn1-generalized-time $SAMPLE) "20230515123456Z" }

@test
def asn1_generalized_time_frac [] { assert equal (date as asn1-generalized-time-frac $SAMPLE) "20230515123456.123456Z" }

@test
def exif_datetime [] { assert equal (date as exif-datetime $SAMPLE) "2023:05:15 12:34:56" }

@test
def dicom_tm [] { assert equal (date as dicom-tm $SAMPLE) "123456.123456" }

@test
def dicom_dt [] { assert equal (date as dicom-dt $SAMPLE) "20230515123456.123456+0000" }

@test
def nato_dtg [] { assert equal (date as nato-dtg $SAMPLE) "151234Z MAY 23" }

@test
def nato_dtg_compact [] { assert equal (date as nato-dtg-compact $SAMPLE) "151234ZMAY23" }

@test
def iso_9660 [] { assert equal (date as iso-9660 $SAMPLE) "2023051512345612+00" }

@test
def net_roundtrip [] { assert equal (date as net-roundtrip $SAMPLE) "2023-05-15T12:34:56.1234567+00:00" }

@test
def net_sortable [] { assert equal (date as net-sortable $SAMPLE) "2023-05-15T12:34:56" }

@test
def net_universal [] { assert equal (date as net-universal $SAMPLE) "2023-05-15 12:34:56Z" }

@test
def sql_timestamp [] { assert equal (date as sql-timestamp $SAMPLE) "2023-05-15 12:34:56" }

@test
def sql_timestamptz [] { assert equal (date as sql-timestamptz $SAMPLE) "2023-05-15 12:34:56+00:00" }

@test
def unix [] { assert equal (date as unix $SAMPLE) 1684154096 }

@test
def unix_ms [] { assert equal (date as unix-ms $SAMPLE) 1684154096123 }

@test
def unix_us [] { assert equal (date as unix-us $SAMPLE) 1684154096123456 }

@test
def unix_ns [] { assert equal (date as unix-ns $SAMPLE) 1684154096123456789 }

@test
def julian_day [] { assert equal (date as julian-day $SAMPLE) 2460080.024260688 }

@test
def modified_julian_day [] { assert equal (date as modified-julian-day $SAMPLE) 60079.52426068815 }

@test
def rata_die [] { assert equal (date as rata-die $SAMPLE) 738655 }

@test
def excel_1900 [] { assert equal (date as excel-1900 $SAMPLE) 45061.52426068815 }

@test
def excel_1904 [] { assert equal (date as excel-1904 $SAMPLE) 43599.52426068815 }

@test
def ntp [] { assert equal (date as ntp $SAMPLE) 3893142896.123457 }

@test
def filetime [] { assert equal (date as filetime $SAMPLE) 133286276961234567 }

@test
def cf_absolute [] { assert equal (date as cf-absolute $SAMPLE) 705846896.1234567 }

# --- catalog completeness ---------------------------------------------------

@test
def every_catalog_name_has_a_test [] {
  let catalog = date list-formats | get name | sort
  let tested = (
    $EXPECTED
    | get name
    | append ($LOCALE_FORMATS | get name)
    | sort
  )
  assert equal $catalog $tested "add a snapshot (or locale mapping) for every new catalog name"
}

@test
def date_as_all_covers_every_catalog_name [] {
  let catalog = date list-formats | get name | sort
  let rendered = date as --all --now $SAMPLE | get name | sort
  assert equal $catalog $rendered
}

@test
def catalog_snapshots_match_together [] {
  assert-no-failures (format-failures $SAMPLE $EXPECTED) "utc sample"
}

# --- aliases ----------------------------------------------------------------

@test
def every_alias_matches_canonical [] {
  let failures = (
    date list-formats
    | each {|row|
        $row.aliases | each {|alias|
          let via_alias = date as $alias $SAMPLE
          let via_name = date as $row.name $SAMPLE
          if $via_alias != $via_name {
            {alias: $alias, name: $row.name, alias_value: $via_alias, name_value: $via_name}
          }
        }
      }
    | flatten
    | compact
  )
  assert-no-failures $failures "aliases"
}

# --- UTC conversion from a non-UTC offset -----------------------------------

@test
def offset_iso_8601_utc [] { assert equal (date as iso-8601-utc $OFFSET) "2023-05-15T17:34:56Z" }

@test
def offset_rfc_3339_utc [] { assert equal (date as rfc-3339-utc $OFFSET) "2023-05-15T17:34:56Z" }

@test
def offset_rfc_7231 [] { assert equal (date as rfc-7231 $OFFSET) "Mon, 15 May 2023 17:34:56 GMT" }

@test
def offset_rfc_850 [] { assert equal (date as rfc-850 $OFFSET) "Monday, 15-May-23 17:34:56 GMT" }

@test
def offset_rfc_5545 [] { assert equal (date as rfc-5545 $OFFSET) "20230515T173456Z" }

@test
def offset_nato_dtg [] { assert equal (date as nato-dtg $OFFSET) "151734Z MAY 23" }

@test
def offset_nato_dtg_compact [] { assert equal (date as nato-dtg-compact $OFFSET) "151734ZMAY23" }

@test
def offset_ecma_262 [] { assert equal (date as ecma-262 $OFFSET) "2023-05-15T17:34:56.123Z" }

@test
def offset_iso_9660 [] { assert equal (date as iso-9660 $OFFSET) "2023051512345612-20" }

@test
def offset_asctime_gmt_converts_but_asctime_does_not [] {
  # ANSI C asctime() is local time; RFC 9110's obsolete asctime-date is GMT.
  assert equal (date as asctime $OFFSET) "Mon May 15 12:34:56 2023"
  assert equal (date as asctime-gmt $OFFSET) "Mon May 15 17:34:56 2023"
}

@test
def offset_preserves_local_iso_8601 [] {
  assert equal (date as iso-8601 $OFFSET) "2023-05-15T12:34:56-05:00"
}

# --- edge cases -------------------------------------------------------------

@test
def asctime_space_pads_single_digit_day [] {
  assert equal (date as asctime $PAD) "Fri May  5 08:04:06 2023"
}

@test
def unix_ns_preserves_fraction_and_pre_epoch [] {
  assert equal (date as unix-ns $PAST) (-14182939876543211)
  assert equal (date as unix $PAST) (-14182940)
  assert equal (date as unix-ns $SAMPLE) 1684154096123456789
}

@test
def unix_ns_roundtrips_through_into_datetime [] {
  assert equal (date as unix-ns $SAMPLE | into datetime | date as unix-ns) 1684154096123456789
  assert equal (date as unix-ns $PAST | into datetime | date as unix-ns) (-14182939876543211)
}

@test
def filetime_pre_epoch_is_still_positive [] {
  assert equal (date as filetime $PAST) 116302906601234567
}

@test
def rfc_weekday_stays_english_under_french_locale [] {
  let value = with-env {LC_ALL: "fr_FR.UTF-8", LC_TIME: "fr_FR.UTF-8", LANG: "fr_FR.UTF-8"} {
    date as rfc-7231 $SAMPLE
  }
  assert equal $value "Mon, 15 May 2023 12:34:56 GMT"
}

# --- named helpers ----------------------------------------------------------

@test
def helper_utc [] { assert equal (utc $SAMPLE) "2023-05-15T12:34:56Z" }

@test
def helper_iso_8601 [] { assert equal (iso-8601 $SAMPLE) "2023-05-15T12:34:56+00:00" }

@test
def helper_iso_8601_full [] { assert equal (iso-8601-full $SAMPLE) "2023-05-15T12:34:56.123456789+00:00" }

@test
def helper_local_datetime [] {
  assert equal (local-datetime $SAMPLE) ($SAMPLE | format date "%c")
}

@test
def helper_rfc_2822 [] { assert equal (rfc-2822 $SAMPLE) "Mon, 15 May 2023 12:34:56 +0000" }

@test
def helper_rfc_850 [] { assert equal (rfc-850 $SAMPLE) "Monday, 15-May-23 12:34:56 GMT" }

@test
def helper_rfc_1036 [] { assert equal (rfc-1036 $SAMPLE) "Mon, 15 May 23 12:34:56 +0000" }

@test
def helper_rfc_1123 [] { assert equal (rfc-1123 $SAMPLE) "Mon, 15 May 2023 12:34:56 GMT" }

@test
def helper_rfc_822 [] { assert equal (rfc-822 $SAMPLE) "Mon, 15 May 23 12:34:56 +0000" }

@test
def helper_rfc_3339 [] { assert equal (rfc-3339 $SAMPLE) "2023-05-15T12:34:56+00:00" }

@test
def helper_rfc_7231 [] { assert equal (rfc-7231 $SAMPLE) "Mon, 15 May 2023 12:34:56 GMT" }

@test
def helper_unix_timestamp [] { assert equal (unix-timestamp $SAMPLE) 1684154096 }

@test
def helper_unix_timestamp_nanos [] { assert equal (unix-timestamp --nanos $SAMPLE) 1684154096123456789 }

@test
def helpers_accept_pipeline_input [] {
  assert equal ($SAMPLE | rfc-3339) "2023-05-15T12:34:56+00:00"
  assert equal ($SAMPLE | rfc-7231) "Mon, 15 May 2023 12:34:56 GMT"
  assert equal ($SAMPLE | unix-timestamp --nanos) 1684154096123456789
}

# --- API / builtins ---------------------------------------------------------

@test
def date_as_accepts_pipeline_and_now_flag [] {
  assert equal ($SAMPLE | date as rfc-3339) "2023-05-15T12:34:56+00:00"
  assert equal (date as rfc-3339 --now $SAMPLE) "2023-05-15T12:34:56+00:00"
}

@test
def date_as_without_format_errors [] {
  assert error { date as }
}

@test
def date_as_unknown_format_errors [] {
  assert error { date as no-such-format $SAMPLE }
}

@test
def date_list_formats_has_expected_columns [] {
  assert equal (date list-formats | columns) [name aliases standard description]
  assert equal (date list-formats --full | columns) [name aliases kind tz locale pattern unit transform standard description]
}

@test
def builtins_are_not_replaced [] {
  assert equal ($SAMPLE | date to-timezone UTC | format date "%Y-%m-%dT%H:%M:%SZ") "2023-05-15T12:34:56Z"
  assert equal (date now | describe) "datetime"
  assert error { $SAMPLE | date format "%Y" }
}

@test
def far_instants_format_without_overflow [] {
  # Every non-nanosecond format must work outside the i64 nanosecond window
  # (1677-09-21 .. 2262-04-11).
  assert equal (date as iso-8601 $ANCIENT) "0001-01-01T00:00:00+00:00"
  assert equal (date as rfc-7231 $ANCIENT) "Mon, 01 Jan 0001 00:00:00 GMT"
  assert equal (date as rata-die $ANCIENT) 1
  assert equal (date as julian-day $ANCIENT) 1721425.5
  assert equal (date as iso-8601-year $FUTURE) "9999"
  assert equal (date as rata-die $FUTURE) 3652059
  assert equal (date as unix $FUTURE) 253402214400
}

@test
def nanosecond_formats_reject_out_of_range_instants [] {
  assert error { date as unix-ns $ANCIENT }
  assert error { date as filetime $ANCIENT }
  assert error { date as unix-ns $FUTURE }
  assert error { date as filetime $FUTURE }
  # The window boundary itself still round-trips exactly.
  assert equal (date as unix-ns 2262-04-11T23:47:15.999999999+00:00) 9223372035999999999
}

@test
def excel_1900_matches_excel_serials [] {
  # Excel's 1900 system counts a phantom 1900-02-29, so serials before
  # 1900-03-01 are one lower than a plain day count from 1899-12-31.
  assert equal (date as excel-1900 1900-01-01T00:00:00+00:00) 1.0
  assert equal (date as excel-1900 1900-02-28T00:00:00+00:00) 59.0
  assert equal (date as excel-1900 1900-03-01T00:00:00+00:00) 61.0
  assert equal (date as excel-1900 $FUTURE) 2958465.0
  assert equal (date as excel-1904 1904-01-01T00:00:00+00:00) 0.0
}

@test
def fractional_formats_always_carry_a_fraction [] {
  # A whole-second instant must still render a fraction, or these formats are
  # indistinguishable from iso-8601 / rfc-3339.
  assert equal (date as iso-8601-full $WHOLE) "2023-05-15T12:34:56.000000000+00:00"
  assert equal (date as rfc-3339-frac $WHOLE) "2023-05-15T12:34:56.000000000+00:00"
  assert equal (date as ecma-262 $WHOLE) "2023-05-15T12:34:56.000Z"
  assert equal (date as odata-datetimeoffset $WHOLE) "2023-05-15T12:34:56.0000000Z"
  assert equal (date as net-roundtrip $WHOLE) "2023-05-15T12:34:56.0000000+00:00"
  # rfc-9557 used chrono %+, which dropped the fraction entirely at whole seconds.
  assert equal (date as rfc-9557 $WHOLE) "2023-05-15T12:34:56.000000000+00:00[UTC]"
}

@test
def date_as_all_rejects_an_explicit_format [] {
  assert error { date as rfc-3339 --all }
  assert error { date as --all rfc-3339 }
}

@test
def date_as_all_accepts_pipeline_input [] {
  assert equal ($SAMPLE | date as --all | length) (date list-formats | length)
  assert equal (
    $SAMPLE | date as --all | where name == "rfc-3339" | get 0.value
  ) "2023-05-15T12:34:56+00:00"
}

@test
def date_as_all_survives_out_of_range_instants [] {
  let rows = date as --all --now $ANCIENT
  assert equal ($rows | length) (date list-formats | length)
  # Only the nanosecond formats drop out; everything else still renders.
  assert equal ($rows | where value == null | get name | sort) [filetime unix-ns]
  assert equal ($rows | where name == "iso-8601" | get 0.value) "0001-01-01T00:00:00+00:00"
  assert equal ($rows | where name == "rata-die" | get 0.value) 1
}

@test
def unknown_format_is_reported_before_instant_math [] {
  # An out-of-range instant must not mask the real problem: the bad name.
  let err = try { date as no-such-format $ANCIENT } catch {|e| $e.msg }
  assert str contains $err "no-such-format"
}

# The child script that actually runs the checks. `__CHECKS__` becomes a list of
# {name, run} records, one per discovered `@test` command. It is a plain string
# so the `$"..."` below are interpolated by the child, not by this file.
const RUNNER = '
let failures = __CHECKS__
  | each {|check|
      try { do $check.run; null } catch {|err| {name: $check.name, error: $err.rendered} }
    }
  | compact
if ($failures | is-not-empty) {
  $failures | each {|failure| print $"FAIL ($failure.name)"; print $failure.error } | ignore
  error make --unspanned {msg: $"($failures | length) of __COUNT__ checks failed"}
}
print $"ok __COUNT__ checks"
'

# Runner. Discovers every `@test` command in this file instead of listing them,
# so a new test cannot be silently skipped.
#
# Nushell cannot call a command whose name is only known as a string, so the
# discovered names are handed to a child `nu` that sources this file and calls
# each one. Every check runs even when an earlier one fails, and each failure is
# reported with its test name and the full rendered error.
def main [] {
  let tests = (
    scope commands
    | where {|cmd| $cmd.attributes | any {|attr| $attr.name == "test"} }
    | get name
    | sort
  )
  if ($tests | is-empty) {
    error make --unspanned {msg: "no @test commands found; is this file being run directly?"}
  }
  let checks = $tests | each {|name| $'{name: "($name)", run: {|| ($name)}}' } | str join ", "
  let script = (
    "source `" + $env.CURRENT_FILE + "`\n"
    + ($RUNNER
       | str replace "__CHECKS__" $"[($checks)]"
       | str replace --all "__COUNT__" ($tests | length | into string))
  )
  ^$nu.current-exe --no-config-file --commands $script
}
