.PHONY: push

push:
	git add -A
	git commit -m "m" || true
	git push
