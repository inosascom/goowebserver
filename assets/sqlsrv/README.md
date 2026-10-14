# SQLSRV NTS assets

Put Linux `amd64`, non-thread-safe PHP extensions supplied for the exact selected PHP series in this structure:

```text
assets/sqlsrv/nts/8.3/SQLSRV_8.3_NTS.so
assets/sqlsrv/nts/8.3/PDO_SQLSRV_8.3_NTS.so
assets/sqlsrv/nts/8.3/SHA256SUMS
assets/sqlsrv/nts/8.4/SQLSRV_8.4_NTS.so
assets/sqlsrv/nts/8.4/PDO_SQLSRV_8.4_NTS.so
assets/sqlsrv/nts/8.4/SHA256SUMS
assets/sqlsrv/nts/8.5/SQLSRV_8.5_NTS.so
assets/sqlsrv/nts/8.5/PDO_SQLSRV_8.5_NTS.so
assets/sqlsrv/nts/8.5/SHA256SUMS
```

The installer also accepts the canonical names `sqlsrv.so` and `pdo_sqlsrv.so`, but the versioned names above are preferred. `SHA256SUMS` must contain exactly the SHA-256 digests using the actual filenames supplied. Drivers must be compiled for the target PHP ABI, Linux `amd64`, and NTS. Do not use Windows `.dll`, macOS, ZTS, or a different PHP minor-version build.

When matching assets exist, the installer’s `--sqlsrv auto` mode enables them. It also requires `--accept-microsoft-eula`, adds the fingerprint-verified Microsoft repository, and installs Microsoft ODBC Driver 18 plus `unixodbc`. Use `--sqlsrv disabled` to omit these drivers explicitly.
