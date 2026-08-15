def utc [now?: datetime] {
  if $now == null {
    date now | date to-timezone utc | format date "%Y-%m-%dT%H:%M:%SZ"
  } else {
    $now | date to-timezone utc | format date "%Y-%m-%dT%H:%M:%SZ"
  }
}

def iso-8601 [now?: datetime] {
  if $now == null {
    date now | format date "%Y-%m-%dT%H:%M:%S%z"
  } else {
    $now | format date "%Y-%m-%dT%H:%M:%S%z"
  }
}

def iso-8601-full [now?: datetime] {
  if $now == null {
    date now | format date "%+"
  } else {
    $now | format date "%+"
  }
}

def local-datetime [now?: datetime] {
  if $now == null {
    date now | format date "%c"
  } else {
    $now | format date "%c"
  }
}

def rfc-2822 [now?: datetime] {
  # "Mon, 15 May 2023 12:34:56 +0000"
  if $now == null {
    date now | format date "%a, %d %b %Y %H:%M:%S %z"
  } else {
    $now | format date "%a, %d %b %Y %H:%M:%S %z"
  }
}

def rfc-850 [now?: datetime] {
  # "Monday, 15-May-23 12:34:56 GMT"

  if $now == null {
    date now | format date "%A, %d-%b-%y %H:%M:%S %Z"
  } else {
    $now | format date "%A, %d-%b-%y %H:%M:%S %Z"
  }
}

def rfc-1036 [now?: datetime] {
  if $now == null {
    date now | format date "%a, %d %b %y %H:%M:%S %z"
  } else {
    $now | format date "%a, %d %b %y %H:%M:%S %z"
  }
}

def rfc-1123 [now?: datetime] {
  # "Mon, 15 May 2023 12:34:56 GMT"
  if $now == null {
    date now | format date "%a, %d %b %Y %H:%M:%S %Z"
  } else {
    $now | format date "%a, %d %b %Y %H:%M:%S %Z"
  }
}

def rfc-822 [now?: datetime] {
  # "Mon, 15 May 23 12:34:56 GMT"
  if $now == null {
    date now | format date "%a, %d %b %y %H:%M:%S %z"
  } else {
    $now | format date "%a, %d %b %y %H:%M:%S %z"
  }
}

def rfc-3339 [now?: datetime] {
  # "2023-05-15T12:34:56Z"
  if $now == null {
    date now | format date "%Y-%m-%dT%H:%M:%S%:z"
  } else {
    $now | format date "%Y-%m-%dT%H:%M:%S%:z"
  }
}

def rfc-7231 [now?: datetime] {
  # "Mon, 15 May 2023 12:34:56 GMT"
  # Always in GMT
  if $now == null {
    date now | date to-timezone GMT | format date "%a, %d %b %Y %H:%M:%S GMT"
  } else {
    $now | date to-timezone GMT | format date "%a, %d %b %Y %H:%M:%S GMT"
  }
}

def unix-timestamp [now?: datetime, --nanos(-n)] {
  if $now == null {
    if $nanos {

      # Nanos are helpful because you can immediately do `| into datetime`
      (date now | format date "%s" | into int) * 1_000_000_000
    } else {
        date now | format date "%s"
    }
  } else {
    if $nanos {
      ($now | format date "%s" | into int) * 1_000_000_000
    } else {
      $now | format date "%s"
    }
  }
}

