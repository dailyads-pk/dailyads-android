# Contributing

Thanks for helping improve the DailyAds.pk app.

## Reporting a problem

Open an [issue](../../issues) with:

- what you did and what happened instead;
- your Android version and phone model;
- the advertisement or page link, if the problem is with one ad.

Problems with the content of an advertisement (wrong city, wrong date, an ad
that should be removed) belong on the site's
[contact page](https://dailyads.pk/contact), not here.

## Pull requests

1. Keep changes focused — one fix or feature per pull request.
2. Match the existing code style and run `dart format .`.
3. `flutter analyze` must report no issues and `flutter test` must pass.
4. If you change how pages are parsed, add or update a test in
   `test/markdown_parser_test.dart` against a saved page in `test/fixtures/`.
5. Describe what changed and why in the pull request.

The app must keep working without accounts, trackers, analytics or
proprietary libraries (no Google Play Services or Firebase), so that it can be
built entirely from free software.

By contributing you agree that your contribution is licensed under the
project's [GPL-3.0-or-later](LICENSE) licence.
