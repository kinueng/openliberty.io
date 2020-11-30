# This script contains the end-to-end steps for building the website with Jekyll and using Maven to package
# Exit immediately if a simple command exits with a non-zero status.
set -e
export BUILD_SCRIPTS_DIR=$(dirname $0)

$BUILD_SCRIPTS_DIR/ruby_install.sh

# Guides that are ready to be published to openliberty.io
echo "Cloning repositories with name starting with guide or iguide..."
ruby $BUILD_SCRIPTS_DIR/clone_guides.rb

# Need to make sure there are draft-iguide* folders before using the find command
# If we don't, the find command will fail because the path does not exist
if [ $(find src/main/content/guides -type d -name "draft-iguide*" | wc -l ) != "0" ] ; then
    echo "Moving any js and css files from draft interactive guides..."
    find src/main/content/guides/draft-iguide* -d -name js -exec cp -R '{}' src/main/content/_assets \;
    find src/main/content/guides/draft-iguide* -d -name css -exec cp -R '{}' src/main/content/_assets \;
fi

# For non-prod sites, add robots.txt to avoid indexing
if [ "$PROD_SITE" != "true" ]; then
    echo "Adding robots.txt"
    cp robots.txt src/main/content/robots.txt
fi

# Special external link handling
pushd gems/ol-target-blank
gem build ol-target-blank.gemspec
gem install ol-target-blank-0.0.1.gem
popd

echo "Copying guide images to /img/guide"
mkdir -p src/main/content/img/guide

# Find images in draft guides and copy to img/guide/{projectid}
find src/main/content/guides/draft-guide*/assets/* | while read line; do
    imgPath=$(echo "$line" | sed -e 's/guides\/draft-guide-/img\/guide\//g' | sed 's/\/assets\/.*//g')
    mkdir -p $imgPath && cp -R $line "$_"
done

# Find images in published guides and copy to img/guide/{projectid}
find src/main/content/guides/guide*/assets/* | while read line; do
    imgPath=$(echo "$line" | sed -e 's/guides\/guide-/img\/guide\//g' | sed 's/\/assets\/.*//g')
    mkdir -p $imgPath && cp -R $line "$_"
done

# Move any js/css files from guides to the _assets folder for jekyll-assets minification.
echo "Moving any js and css files published interactive guides..."
# Assumption: There is _always_ iguide* folders
find src/main/content/guides/iguide* -d -name js -exec cp -R '{}' src/main/content/_assets \;
find src/main/content/guides/iguide* -d -name css -exec cp -R '{}' src/main/content/_assets \;

# Clone certifications
$BUILD_SCRIPTS_DIR/clone_certifications.sh

# Clone draft and published blogs
$BUILD_SCRIPTS_DIR/clone_blogs.sh

# Jekyll build all the cloned content
echo "Building with jekyll..."
echo `jekyll -version`
mkdir -p target/jekyll-webapp

# Enable google analytics if ga is true
if [ "$PROD_SITE" = true ]
  then 
    jekyll build --source src/main/content --config src/main/content/_config.yml,src/main/content/_google_analytics.yml --destination target/jekyll-webapp 
  else
    # Set the --future flag to show blogs with date timestamps in the future
    jekyll build --future --source src/main/content --destination target/jekyll-webapp 
fi
