cat ./input.txt | \
    INTERVAL=200 GROUP_SIZE=4 \
    python ./json-chunker.py | \
    SYS_FILE=./sys-append.txt \
    bash ./exec-llama.sh > \
    ./output.txt

# jq -r '.segment_ja' input-jp.ndjson | \
#     INTERVAL=200 GROUP_SIZE=4 \
#     python ./json-chunker.py | \
#     SYS_FILE=./sys-append.txt \
#     bash ./exec-llama.sh > \
#     ./output.txt
