# PHP and web-server extension baseline

The Ubuntu installer adapts the existing GOO Web Server Windows PHP compatibility baseline to native Ubuntu packages.

## PHP-FPM packages

For the selected PHP 8.3, 8.4, or 8.5 series, the installer installs and enables the matching `fpm`, `cli`, `common`, `curl`, `gd`, `intl`, `mbstring`, `mysql`, `pgsql`, `xml`, `zip`, and `opcache` packages. This provides the GOO baseline modules: `curl`, `fileinfo`, `gd`, `intl`, `mbstring`, `mysqli`, `pdo_mysql`, `pgsql`, `pdo_pgsql`, `sodium`, `zip`, `exif`, and OPcache. Core-provided modules such as `fileinfo`, `sodium`, and `exif` are verified through the PHP module list rather than installed as nonexistent standalone packages.

The installer writes the managed `goows.ini` baseline: FastCGI compatibility, production error-display defaults, secure session defaults, OPcache, and realpath cache settings. Ioncube is loaded before normal extensions and disables OPcache JIT, matching the Windows runtime behavior.

## Web servers

- **Apache:** enables `rewrite`, `proxy_fcgi`, and `setenvif`; PHP is served through the selected PHP-FPM configuration, never `mod_php`.
- **Nginx:** rewrite processing is part of Nginx itself; the future managed virtual-host template will route PHP through the selected PHP-FPM socket.

## SQL Server

SQLSRV and PDO_SQLSRV are optional Linux PHP-FPM extensions. If matching supplied NTS assets are present, the installer verifies their checksums, copies them to PHP’s extension directory, enables version-scoped `sqlsrv.ini` and `pdo_sqlsrv.ini`, installs `msodbcsql18` plus `unixodbc`, and verifies both modules with `php -m`.

Microsoft documents PHP-FPM installation of the two drivers with versioned PHP packages and ODBC dependencies. [Microsoft PHP driver guide](https://learn.microsoft.com/en-us/sql/connect/php/installation-tutorial-linux-mac?view=sql-server-ver17) [Microsoft ODBC driver guide](https://learn.microsoft.com/en-us/sql/connect/odbc/linux-mac/installing-the-microsoft-odbc-driver-for-sql-server?view=sql-server-ver15)
