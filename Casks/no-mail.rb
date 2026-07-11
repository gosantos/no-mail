cask "no-mail" do
  version "1.0.0"
  sha256 "REPLACE_WITH_SHA256_OF_THE_RELEASE_ZIP"

  url "https://github.com/YOUR_GITHUB/no-mail/releases/download/v#{version}/noMail-#{version}.zip"
  name "noMail"
  desc "Prevents Apple Mail from launching"
  homepage "https://github.com/YOUR_GITHUB/no-mail"

  auto_updates false
  depends_on macos: ">= :big_sur"

  app "noMail.app"

  zap trash: [
    "~/Library/Preferences/com.nomail.NoMail.plist",
  ]
end
