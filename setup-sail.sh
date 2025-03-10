#!/bin/bash

set -e

verify_php_version() {
    # Check if PHP is installed
    if ! command -v php &> /dev/null; then
        echo "PHP is not installed. Please install PHP to proceed."
        exit 1
    fi

    # Check PHP version
    PHP_VERSION=$(php -r "echo PHP_VERSION;")
    REQUIRED_PHP_VERSION="8.2"

    if [[ "$PHP_VERSION" < "$REQUIRED_PHP_VERSION" ]]; then
        echo "PHP version must be $REQUIRED_PHP_VERSION or higher. Current version: $PHP_VERSION"
        exit 1
    fi

    echo "PHP version is $PHP_VERSION"
}

prepare_composer(){
    # Check if composer is globally available
    if command -v composer &> /dev/null; then
        echo "Composer is globally available"
        export COMPOSER_CMD="composer"
    else
        echo "Composer is not globally available, using local composer"

        # Download composer.phar if it does not exist
        if [ ! -f composer.phar ]; then
            echo "Downloading composer.phar"
            curl -sS https://getcomposer.org/installer | php
            chmod +x composer.phar
        fi

        export COMPOSER_CMD="./composer.phar"
    fi
}

fetch_composer_dependencies() {
    echo "Fetching composer dependencies (without platform requirements)"
    $COMPOSER_CMD install --ignore-platform-reqs --no-autoloader
}

main() {
    verify_php_version
    prepare_composer
    fetch_composer_dependencies
    bash setup/prepare-certificates.sh
}

main "$@"
