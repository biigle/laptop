FROM docker.pkg.github.com/biigle/core/app:latest
MAINTAINER Martin Zurowietz <martin@cebitec.uni-bielefeld.de>

# Configure the timezone.
ARG TIMEZONE
RUN apk add --no-cache tzdata \
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && apk del tzdata

# Required to generate the REST API documentation.
RUN apk add --no-cache npm \
    && npm install apidoc@"^0.17.0" -g

# Ignore platform reqs because the app image is stripped down to the essentials
# and doens't meet some of the requirements. We do this for the worker, though.
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
    && COMPOSER_SIGNATURE=$(curl -s https://composer.github.io/installer.sig) \
    && php -r "if (hash_file('SHA384', 'composer-setup.php') === '$COMPOSER_SIGNATURE') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
    && php composer-setup.php \
    && rm composer-setup.php

ENV COMPOSER_NO_INTERACTION 1
ENV COMPOSER_ALLOW_SUPERUSER 1

# Include the Composer cache directory to speed up the build.
COPY cache /root/.composer/cache

ARG GITHUB_OAUTH_TOKEN
ARG PROJECTS_VERSION=">=1.0"
ARG LABEL_TREES_VERSION=">=1.0"
ARG VOLUMES_VERSION=">=1.0"
ARG ANNOTATIONS_VERSION=">=1.0"
ARG LARGO_VERSION=">=1.0"
ARG REPORTS_VERSION=">=1.0"
ARG COLOR_SORT_VERSION=">=1.0"
ARG LASERPOINTS_VERSION=">=1.0"
ARG SYNC_VERSION=">=1.0"
ARG VIDEOS_VERSION=">=1.0"
RUN COMPOSER_AUTH="{\"github-oauth\":{\"github.com\":\"${GITHUB_OAUTH_TOKEN}\"}}" \
    php composer.phar require \
        biigle/projects:${PROJECTS_VERSION} \
        biigle/label-trees:${LABEL_TREES_VERSION} \
        biigle/volumes:${VOLUMES_VERSION} \
        biigle/annotations:${ANNOTATIONS_VERSION} \
        biigle/largo:${LARGO_VERSION} \
        biigle/reports:${REPORTS_VERSION} \
        biigle/color-sort:${COLOR_SORT_VERSION} \
        biigle/laserpoints:${LASERPOINTS_VERSION} \
        biigle/sync:${SYNC_VERSION} \
        biigle/videos:${VIDEOS_VERSION} \
        --prefer-dist --update-no-dev --ignore-platform-reqs

RUN sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Projects\\ProjectsServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\LabelTrees\\LabelTreesServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Volumes\\VolumesServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Annotations\\AnnotationsServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Largo\\LargoServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Reports\\ReportsServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\ColorSort\\ColorSortServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Laserpoints\\LaserpointsServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Videos\\VideosServiceProvider::class,' config/app.php \
    && sed -i '/Insert Biigle module service providers/i Biigle\\Modules\\Sync\\SyncServiceProvider::class,' config/app.php

# Add custom config.
COPY config/biigle.php /var/www/config/biigle.php
COPY config/reports.php /var/www/config/reports.php
COPY config/filesystems.php /var/www/config/filesystems.php
COPY config/volumes.php /var/www/config/volumes.php

RUN php composer.phar dump-autoload -o && rm composer.phar

RUN php artisan vendor:publish --tag=public
# Generate the REST API documentation.
RUN cd /var/www && php artisan apidoc &> /dev/null

# Generate the server API documentation
RUN curl -O http://get.sensiolabs.org/sami.phar \
    && php sami.phar update sami.php &> /dev/null \
    && rm -r sami.phar

# Add custom configs.
COPY config/filesystems.php /var/www/config/filesystems.php

RUN php /var/www/artisan route:cache

COPY .env /var/www/.env
RUN php /var/www/artisan config:cache && rm /var/www/.env
