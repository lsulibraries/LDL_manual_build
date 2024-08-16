cd /opt/drupal/islandora-starter-site/
# Since islandora_defaults is near the bottom of the dependency chain, requiring
# it will get most of the modules and libraries we need to deploy a standard
# Islandora site.
sudo -u www-data composer require "drupal/flysystem:^2.0@alpha"
sudo -u www-data composer require "islandora/islandora:^2.4"
sudo -u www-data composer require "islandora/controlled_access_terms:^2"
sudo -u www-data composer require "islandora/openseadragon:^2"

# These can be considered important or required depending on your site's
# requirements; some of them represent dependencies of Islandora submodules.
sudo -u www-data composer require "drupal/pdf:1.1"
sudo -u www-data composer require "drupal/rest_oai_pmh:^2.0@beta"
sudo -u www-data composer require "drupal/search_api_solr:^4.2"
sudo -u www-data composer require "drupal/facets:^2"
sudo -u www-data composer require "drupal/content_browser:^1.0@alpha" ## TODO do we need this?
sudo -u www-data composer require "drupal/field_permissions:^1"
sudo -u www-data composer require "drupal/transliterate_filenames:^2.0"

# These tend to be good to enable for a development environment, or just for a
# higher quality of life when managing Islandora. That being said, devel should
# NEVER be enabled on a production environment, as it intentionally gives the
# user tools that compromise the security of a site.
sudo -u www-data composer require drupal/restui:^1.21
sudo -u www-data composer require drupal/console:~1.0
sudo -u www-data composer require drupal/devel:^2.0
sudo -u www-data composer require drupal/admin_toolbar:^2.0