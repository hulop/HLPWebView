# HLPWebView

## MapService Client Framework
HLPWebView is a [MapService](https://github.com/hulop/MapService) Client Framework for iOS.

## Dependencies
- None

## Installation
1. Install [Carthage](https://github.com/Carthage/Carthage).
2. Add below to your `Cartfile`:
```
github "hulop/HLPWebView"
```
3. In your project directory, run `carthage update HLPWebView`.

## Usage

### Basic Setup
1. Add HLPWebView to ViewController class

  If you use StoryBoard, add UIWebView object to your ViewController scene. And set `Custom Class` to `HLPWebView`.
  Then, make link from the object to the source file of ViewController.
  ```objc
  @property (weak, nonatomic) IBOutlet HLPWebView *webView;
  ```

2. Setup parameters

  Set HLPWebView parameters below
  - `userMode` - A name of MapService setting preset.
    - The preset names:
      - `user_blind` - A preset for blind users
      - `user_wheelchair` - A preset for wheel chair users
      - `user_general` (default) - A preset for all sighted users
  - `config` - MapService server setting.
    - Setting keys:
      - `serverHost` - Server host name
      - `serverContext` - API Key
      - `usesHttps` (default: YES) -  Use HTTPS to access server

### HLPWebViewDelegate
Set `HLPWebViewDelegate` implementation to `HLPWebView.delegate`.
It enables to get current parameters of MapService.

### HLPTTSProtocol
Set `HLPTTSProtocol` implementation to `HLPWebView.tts`.
The protocol enables to customize Text to Speech and vibration.

----
## About
[About HULOP](https://github.com/hulop/00Readme)

## License
[MIT](https://opensource.org/licenses/MIT)

## README
This Human Scale Localization Platform library is intended solely for use with an Apple iOS product and intended to be used in conjunction with officially licensed Apple development tools and further customized and distributed under the terms and conditions of your licensed Apple developer program.
