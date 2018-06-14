# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- add-module=nginx-upstream-dynamic-servers

## [1.1.0] - 2018-01-09
### Added
- Updated open resty to stable versio 1.13.6.1
- Updated open ssl to 1.0.2o
- Updated pagespeed to version 1.12.34.3
- Updated Pagespeed optimization library (PSOL) to 1.12.34.2-x64"
- Added own version variable for psol

### Removed
- separate nginx2redis lib since its already included

## [1.0.0] - 2018-01-09
### Added
- This changelog

### Changed
- New FROM path for base image in Dockerfile `devgeniem/base:ubuntu`
- Pagespeed package name changed
