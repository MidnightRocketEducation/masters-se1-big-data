# Generate `raw-categories`

```sh
jq -r '.categories | if type == "string" then ascii_downcase | split(", ").[] end' "yelp_academic_dataset_business.json" | sort -u -o "raw-categories"
```

# Filter
> Minimum context length 64k. Optimal 256k. 
> Using Ollama with gpt-oss model.

```sh
./process-with-ai
```

This script produces a number of output files. 
This is because of the inherrent randomness of LLMs. See Post processing below. 
These files are also comitted to the repo, to persist them, because processing these output are very resource intensive.



# Post processing

## Categories which is common among `COUNT` of AI runs.
Because of the inherrent randomness of LLMs some post processing is needed. 

Some iterations through the AI filter are too strict, while other iterations are too lenient.
To compensate for this, combinning the result of multiple iterations, mitigates some of these tendencies.

If a category has passed the filter only once, then that might indicate it is not that relevant to the topic, and is really just an outlier.
While requiring a category to have passed all iterations, might be too strict, and leave out at lot of categories.

The below script filters categories which has passed the filter in at least `COUNT` iterations or more. 
Finally it also compares with the original categories, to filter out any categories which have been hallucinated, something which is (un)suprisingly common.

```sh
COUNT=3 ./post-filter
```

Adjust the `COUNT` to higher values to be more conservative,
or to lower values to be more lenient.

This ensures that at least `COUNT` runs of the AI agrees has found the category to be relevant, and that the categories also exists in the `raw-categories`. 
This removes invented categories.

