# SimpleTwitterAuthentication

SimpleTwitterAuthentication is a simple wrapper for Twitter login authentication. 

- If installed Twitter app, use Twitter app SSO (like TwitterKit)
- If not installed Twitter app, use in app browser for authentication.
    - iOS 12+: ASWebAuthenticationSession
    - iOS 11: SFAuthenticationSession
    - iOS 10: SFSafariViewController

## How to use

1. Complete registration to Twitter and get Consumer Key and Secret.
2. **You also need add callback URL scheme of `twitterkit-($YOUR_CONSUMER_KEY)://` to your app in Twitter Developer Console.** It need for use by browser authentication.
4. Install SimpleTwitterAuthentication to your project.
5. Add callback URL scheme `twitterkit-($YOUR_CONSUMER_KEY)` to URL Types in Info.plist
6. Implement to call `TwitterAuthentication.authenticate(completionHandler:)` to your need to authenticate to Twitter. When TwitterAuthentication instantiate, pass Consumer Key, Secret and Callback Scheme `twitterkit-($YOUR_CONSUMER_KEY)://`. You need to store instance to it can access from AppDelegate.
7. Implement to call `TwitterAuthentication.handleOpen(_:options:)` to `application(_:open:options:)` in AppDelegate

More detail, please refer to Example.

## Author

Nobuhiro Ito <ito@pirika.org> \
PIRIKA Inc. / PIRIKA Association

## License

Apache License, Version 2.0

```
Copyright (C) 2019 PIRIKA Association
Copyright (C) 2019 PIRIKA Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
