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
 --force-raster-color-profile=generic-rgb

 --no-startup-window
 --single-process
 --no-zygote

 --no-sandbox
 --disable-setuid-sandbox
 --no-first-run

 --ignore-urlfetcher-cert-requests
 --use-fake-device-for-media-stream

 --user-data-dir=/tmp/chrome
 --media-cache-dir=/tmp/chrome
 --disk-cache-dir=/tmp/chrome
 --disk-cache-size=52428800

 --no-pings
 --no-wifi
 --block-new-web-contents

 --enable-low-res-tiling
 --enable-low-end-device-mode

 --disable-threaded-animation
 --disable-test-root-certs
 --disable-smooth-scrolling
 --disable-shared-workers
 --disable-remote-fonts
 --disable-reading-from-canvas
 --disable-notifications
 --disable-logging
 --disable-highres-timer
 --disable-gpu
 --disable-gpu-early-init
 --disable-font-subpixel-positioning
 --disable-fine-grained-time-zone-detection
 --disable-extensions
 --disable-domain-reliability
 --disable-device-discovery-notifications
 --disable-demo-mode
 --disable-dev-shm-usage
 --disable-breakpad
 --disable-cloud-import
 --disable-databases
 --disable-preconnect
 --disable-speech-api
 --disable-sync
 --disable-translate
 --disable-default-apps
 --disable-sync-preferences
 --disable-voice-input
 --disable-webgl
 --disable-webgl2
 --disable-client-side-phishing-detection
 --disable-local-storage
 --disable-features=AccountConsistency,AppBanners,DesktopIOSPromotion,DoodlesOnLocalNtp,ExperimentalAppBanners,GamepadExtensions,GenericSensor,GenericSensorExtraClasses,IPH_DemoMode,ImageCaptureAPI,NewUsbBackend,NoStatePrefetch,OmniboxSpeculativeServiceWorkerStartOnQueryInput,OpenVR,OptimizationHints,ServiceWorkerPaymentApps,SpeculativePreconnect,SpeculativeResourcePrefetching,TopSitesFromSiteEngagement,TranslateRankerEnforcement,UseSuggestionsEvenIfFew,VoiceSearchOnLocalNtp,WebPayments,ZeroSuggestRedirectToChrome,affiliation-based-matching
EOF
)

# --trace-startup=*,disabled-by-default-memory-infra
# --trace-to-console