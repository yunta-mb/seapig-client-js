build:
	coffee -o ./ -m -c src/
	uglifyjs seapig-client.js --in-source-map seapig-client.js.map -cm --source-map seapig-client.min.js.map >seapig-client.min.js
	uglifyjs seapig-viewer.js --in-source-map seapig-viewer.js.map -cm --source-map seapig-viewer.min.js.map >seapig-viewer.min.js
	sed -e '/__CODE__/,$$ d' src/seapig-viewer.template.html > seapig-viewer.html
	for incl in vendor/*; do cat $$incl >> seapig-viewer.html; echo ";" >> seapig-viewer.html; done
	cat seapig-client.js >> seapig-viewer.html
	cat seapig-viewer.js >> seapig-viewer.html
	sed -e '1,/__CODE__/ d' src/seapig-viewer.template.html >> seapig-viewer.html
	sed -e '/__CODE__/,$$ d' src/seapig-viewer.template.html > seapig-viewer.min.html
	for incl in vendor/*; do cat $$incl >> seapig-viewer.min.html; echo ";" >> seapig-viewer.min.html; done
	cat seapig-client.min.js >> seapig-viewer.min.html
	cat seapig-viewer.min.js >> seapig-viewer.min.html
	sed -e '1,/__CODE__/ d' src/seapig-viewer.template.html >> seapig-viewer.min.html
	rm  seapig-viewer.js seapig-viewer.js.map seapig-viewer.min.js seapig-viewer.min.js.map

clean:
	rm seapig-client.js  seapig-client.js.map  seapig-client.min.js  seapig-client.min.js.map  seapig-viewer.html  seapig-viewer.js  seapig-viewer.js.map seapig-viewer.min.html  seapig-viewer.min.js  seapig-viewer.min.js.map

