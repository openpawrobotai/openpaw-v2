.PHONY: install draft list approve reject post post-dry notify

install:
	pip install -e .

# make draft REPO=openpaw-firmware SHA=abc MSG="[post] add OTA" FILES=ota.c,partitions.csv
draft:
	python -m openpaw_marketing draft --repo "$(REPO)" --sha "$(SHA)" \
		--message "$(MSG)" --files "$(FILES)" --type "$(or $(TYPE),progress)"

list:
	python -m openpaw_marketing list

# make approve ID=ab12cd34ef   (then commit queue/queue.jsonl)
approve:
	python -m openpaw_marketing approve "$(ID)"

reject:
	python -m openpaw_marketing reject "$(ID)"

post:
	python -m openpaw_marketing post-due

post-dry:
	python -m openpaw_marketing post-due --dry-run

# make notify TEXT="🐾 openpaw-firmware — OTA landed"
notify:
	python -m openpaw_marketing notify --text "$(TEXT)"
