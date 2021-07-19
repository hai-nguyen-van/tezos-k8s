#! /bin/bash

export TEZOS_CLIENT_UNSAFE_DISABLE_DISCLAIMER=Y
(tezos-client stresstest transfer using text:'[ { "pkh": "tz1L8yuUgJopLYULXwjkb7qnzHe4tYKdknEr", "pk": "edpkvFqVMLRhxJF7MLawyiKHC4NVy7UpkofdWM5aVzdtNEVUQNyExb", "sk": "edsk4K663GCFQwpP9A8KmB1apLti9QdymaLSfDpZJYxF6FU7RDxTf7" }, { "pkh": "tz1Tvrcg4ma7FBEjYbBY4BnWub2SXQNPuZya", "pk": "edpkuYzKgmQjxw7xFCgCZC3JfugBG6pEUEfGS5fD2Nj3T1hYtioZfq", "sk": "edsk3TQC5LiubMxjRHPtG9C6nm36naBc48HRyCutpg7EvKEjbDXWwg" } ]' --fresh-probability 0.1 --strategy "evaporation:0.01" -seed 98098 --single-op-per-pkh-per-block --transfers 50 --tps 10 2> /dev/null) | tail -n 1 | cut -d ' ' -f 1

## With a loop on the tps parameter

# echo "# Generated log on pod $(hostname)"
# for TPS in 0.017 0.020 0.025 0.033 0.050 0.075 0.100 0.200 0.300 0.400 0.500 0.600 0.700 0.800 0.900 1.000 2.000 3.000 4.000 5.000 6.000 7.000 8.000 9.000 10.000 20 50 75 100 150 200 250 300 400 500 750 1000
# do
#     printf "$TPS,"
#     (tezos-client stresstest transfer using text:'[ { "pkh": "tz1L8yuUgJopLYULXwjkb7qnzHe4tYKdknEr", "pk": "edpkvFqVMLRhxJF7MLawyiKHC4NVy7UpkofdWM5aVzdtNEVUQNyExb", "sk": "edsk4K663GCFQwpP9A8KmB1apLti9QdymaLSfDpZJYxF6FU7RDxTf7" }, { "pkh": "tz1Tvrcg4ma7FBEjYbBY4BnWub2SXQNPuZya", "pk": "edpkuYzKgmQjxw7xFCgCZC3JfugBG6pEUEfGS5fD2Nj3T1hYtioZfq", "sk": "edsk3TQC5LiubMxjRHPtG9C6nm36naBc48HRyCutpg7EvKEjbDXWwg" } ]' --fresh-probability 0.1 --strategy "evaporation:0.01" -seed 98098 --single-op-per-pkh-per-block --transfers 50 --tps $TPS 2> /dev/null) | tail -n 1 | cut -d ' ' -f 1
# done
