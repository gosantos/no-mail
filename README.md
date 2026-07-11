# noMail

noMail is a macOS application that prevents **Apple Mail** from launching.

Simply launch the noMail app and Mail will no longer be able to open — for example, when something on your Mac tries to hand off a `mailto:` link or an app auto-launches Mail in the background.

You can toggle the app's functionality via the menu bar icon with a simple left click.

> Inspired by [noTunes](https://github.com/tombonez/noTunes) by Tom Taylor.

## Installation

### Homebrew

```bash
brew install --cask no-mail
```

### Direct download

Grab `noMail-<version>.zip` from the [Releases](../../releases) page, unzip it, and drag `noMail.app` into `/Applications`.

Because the app is not notarized with an Apple Developer ID, the first launch may be blocked by Gatekeeper. Either right-click the app and choose **Open**, or run:

```bash
xattr -dr com.apple.quarantine /Applications/noMail.app
```

## Usage

### Launch at startup

1. Open **System Settings → General → Login Items**
2. Under **Open at Login**, click **+** and select noMail.

### Toggle noMail

Left click the menu bar icon to toggle between active states:

- **Enabled** — envelope-with-slash icon; Mail is prevented from opening.
- **Disabled** — plain envelope icon; Mail can open normally.

### Hide the menu bar icon

Right click (or control-click) the menu bar icon and choose **Hide Icon**.

### Restore the menu bar icon

Quit noMail, run the following in Terminal, then re-open the app:

```bash
defaults delete com.nomail.NoMail hideIcon
```

### Quit noMail

- **Icon visible:** right/control-click the menu bar icon → **Quit noMail**.
- **Icon hidden:** run `osascript -e 'quit app "noMail"'` or quit via Activity Monitor.

## Configuration

All settings live under the `com.nomail.NoMail` defaults domain.

### Open a replacement when Mail is blocked

Launch another app instead of Mail:

```bash
defaults write com.nomail.NoMail replacement /Applications/Spark.app
```

...or open a website (great for webmail):

```bash
defaults write com.nomail.NoMail replacement https://mail.google.com/
```

Disable the replacement:

```bash
defaults delete com.nomail.NoMail replacement
```

### Block a different app instead of Mail

noMail can block any app by bundle identifier:

```bash
# Block Microsoft Outlook instead of Apple Mail
defaults write com.nomail.NoMail blockedBundleId com.microsoft.Outlook

# Back to Apple Mail
defaults delete com.nomail.NoMail blockedBundleId
```

## Building from source

Requires the Xcode command line tools (`xcode-select --install`).

```bash
./build.sh            # -> build/noMail.app
./build.sh 1.2.0      # -> versioned build + build/noMail-1.2.0.zip + sha256
```

## License

MIT — see [LICENSE](LICENSE).
