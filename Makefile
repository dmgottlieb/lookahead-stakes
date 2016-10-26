deploy :
	jekyll build --config _prod.yml --destination _prod
	rsync -rLvz _prod/ dmgottlieb_grobstein@ssh.phx.nearlyfreespeech.net:/home/public/lookahead-stakes