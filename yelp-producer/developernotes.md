# `yelp_academic_dataset_business.json`
> Observations made during the initial analysis of the provided files in the yelp dataset.





Find all unique categories for all businesses:
```sh
jq -r '.categories | if type == "string" then ascii_downcase | split(", ").[] end' "yelp_academic_dataset_business.json" | sort -u | tee /mnt/dev/categories | wc -l
# 1312
```

Find all unique category full strings for all businesses:
```sh
jq -r '.categories | if type == "string" then ascii_downcase end' "yelp_academic_dataset_business.json" | sort -u | wc -l
# 150346
```


Find numbers of business with empty categories:
```sh
jq -r '.categories | if type == "string" then empty end' "yelp_academic_dataset_business.json" | wc -l
# 103
```


Find number of states:
```sh
jq -r '.state' yelp_academic_dataset_business.json | sort -u | wc -l
# 27
```


Number of unique attributes
```sh
jq -r '.attributes | if . != null then keys.[] else empty end' yelp_academic_dataset_business.json | sort -u | wc -l
# 39
```

Filter based on has attribute key
```sh
jq -r 'select(.attributes | . != null and (keys | any(match("Restaurants")) and (any(match("RestaurantsPriceRange"))|not) ) )' yelp_academic_dataset_business.json
```
