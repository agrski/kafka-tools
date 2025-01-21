module {
  "name": "kafka",
  "author": "agrski"
};

def ts_to_date:
  .ts | (. % 1000) as $ms | . / 1000 | todate | sub("Z"; ($ms | tostring | "." + . + "Z"));
