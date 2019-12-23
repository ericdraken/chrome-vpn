# /etc/chromium-browser/default
# Default settings for chromium-browser. This file is sourced by /bin/sh from
# /usr/bin/chromium-browser

# Keep the leading space before flags!
# REF: https://stackoverflow.com/a/1168084/1938889
# REF: https://chromium.googlesource.com/chromium/blink/+/master/Source/core/frame/Settings.in
CHROMIUM_FLAGS=$(
  cat <<'EOF'
 --blink-settings=imagesEnabled=false,loadsImagesAutomatically=false,scrollAnimatorEnabled=false,threadedScrollingEnabled=false,doHtmlPreloadScanning=true,lowPriorityIframes=true,offlineWebApplicationCacheEnabled=true,allowFileAccessFromFileURLs=false
 --force-color-profile=generic-rgb

 --single-process
 --no-zygote

 --no-sandbox
 --disable-setuid-sandbox
 --no-first-run

 --disable-dev-shm-usage
 --disable-breakpad
 --disable-cloud-import
 --disable-databases
 --disable-preconnect
 --disable-speech-api
 --disable-sync
 --disable-translate

 --ignore-urlfetcher-cert-requests

 --disable-sync-preferences
 --disable-voice-input
 --disable-webgl

 --user-data-dir=/tmp/chrome
 --media-cache-dir=/tmp/chrome
 --disk-cache-dir=/tmp/chrome
 --disk-cache-size=52428800

 --no-pings
 --no-wifi
 --disable-local-storage
 --block-new-web-contents
 --enable-low-res-tiling
 --enable-low-end-device-mode
 --disable-features=AccountConsistency,AppBanners,DesktopIOSPromotion,DoodlesOnLocalNtp,ExperimentalAppBanners,GamepadExtensions,GenericSensor,GenericSensorExtraClasses,IPH_DemoMode,ImageCaptureAPI,NewUsbBackend,NoStatePrefetch,OmniboxSpeculativeServiceWorkerStartOnQueryInput,OpenVR,OptimizationHints,ServiceWorkerPaymentApps,SpeculativePreconnect,SpeculativeResourcePrefetching,TopSitesFromSiteEngagement,TranslateRankerEnforcement,UseSuggestionsEvenIfFew,VoiceSearchOnLocalNtp,WebPayments,ZeroSuggestRedirectToChrome,affiliation-based-matching
EOF
)