# Turns a line of traefik/logs/access.log into a table row, used by logs.sh
# $domain - DOMAIN from .env, cut off the hosts: "hub" for "hub.<DOMAIN>"
# $color - Whether to add colors

# Adds spaces up to n characters, so the columns line up. Done before coloring: the color codes have no width
def pad(n): tostring | if length < n then . + " " * (n - length) else . end;

# Wraps the text in a terminal color code: 1 bold, 2 dim, 31 red, 32 green, 33 yellow, 34 blue, 35 magenta, 36 cyan
def color(code): if $color and code != "" then "\u001b[\(code)m\(.)\u001b[0m" else . end;

# 2xx green, 3xx cyan, 401/403/429 (no token, rate limit) magenta, other 4xx yellow, 5xx red
def status_color: if . >= 500 then "1;31" elif . == 401 or . == 403 or . == 429 then "1;35" elif . >= 400 then "1;33" elif . >= 300 then "1;36" else "1;32" end;

# Bytes as 433B, 12K, 3M
def size: if . < 1024 then "\(.)B" elif . < 1048576 then "\(. / 1024 | floor)K" else "\(. / 1048576 | floor)M" end;

# Lines that aren't JSON are skipped
fromjson? |

# No router matched: bots scanning the IP. The whole row is dimmed instead, so the real requests stand out
(.RouterName == null) as $noise |
def cell(code): if $noise then . else color(code) end;

[
  # Time: "09-27 16:26:03" from "2026-09-27T16:26:03+02:00"
  (.time[5:10] + " " + .time[11:19] | pad(14) | cell("2")),

  # Status of the response
  (.DownstreamStatus as $status | $status | pad(6) | cell($status | status_color)),

  # Status from the service. "-": Traefik answered by itself (no router, no token, rate limit, redirect, service down)
  (.OriginStatus // 0 | if . == 0 then "-" | pad(6) | cell("2") else . as $status | pad(6) | cell($status | status_color) end),

  # Duration: nanoseconds to ms, a second or more is yellow
  ((.Duration // 0) / 1000000 | floor | if . >= 1000 then "\(.)ms" | pad(8) | cell("33") else "\(.)ms" | pad(8) end),

  # Response size
  (.DownstreamContentSize // 0 | size | pad(6)),

  # Client IP
  (.ClientHost | pad(15) | cell("36")),

  # Requested host without ".<DOMAIN>"
  (.RequestHost // "-" | if $domain != "" and endswith("." + $domain) then .[:-($domain | length) - 1] else . end | pad(14)),

  # Router without "websecure-" and "@file". The routers open to the Internet ("-remote") are bold
  (.RouterName // "-" | sub("^websecure-"; "") | sub("@file$"; "") | if endswith("-remote") then pad(20) | cell("1;34") else pad(20) | cell("34") end),

  # Method in bold and path
  (.RequestMethod as $method | ($method | cell("1")) + " " + (.RequestPath | pad(34 - ($method | length)))),

  # User-Agent
  (.["request_User-Agent"] // "-" | cell("2"))
] | join("  ") | if $noise then color("2") else . end
