module {
  "name": "kafka",
  "author": "agrski"
};

def ts_to_date:
  .ts
    | (. % 1000) as $ms
    | . / 1000
    | todate
    | sub("Z"; ($ms | tostring | "." + . + "Z"))
  ;

def headers:
  .headers
    | [[range(length)], .]                        # For-each indexed
    | transpose                                   # Zip indices & headers
    | [                                           # Split headers into keys & values, drop indices
        [.[] | select(.[0] % 2 == 0) | .[1]],
        [.[] | select(.[0] % 2 == 1) | .[1]]
      ]
    | transpose                                   # Zip keys & values
    | reduce .[] as [$k, $v] ({}; .[$k] += [$v])  # Coalesce, accounting for repeated keys
  ;
