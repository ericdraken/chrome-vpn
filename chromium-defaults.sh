# /etc/chromium-browser/default
# Default settings for chromium-browser. This file is sourced by /bin/sh from
# /usr/bin/chromium-browser

# Keep the leading space before flags!
# REF: https://stackoverflow.com/a/1168084/1938889
CHROMIUM_FLAGS=$(
  cat <<'EOF'
 --blink-settings=imagesEnabled=false,scrollAnimatorEnabled=false,threadedScrollingEnabled=false
 --single-process
 --no-sandbox
 --no-zygote
 --disable-dev-shm-usage
 --disable-accelerated-2d-canvas
 --disable-breakpad
 --disable-cloud-import
 --disable-databases
 --disable-preconnect
 --disable-speech-api
 --disable-sync
 --disable-sync-preferences
 --disable-voice-input
 --disable-webgl
 --media-cache-dir=/tmp
 --disk-cache-dir=/tmp
 --no-pings
 --no-wifi
 --disable-local-storage
 --block-new-web-contents
 --enable-low-res-tiling
 --enable-low-end-device-mode
 --disable-background-networking
 --disable-features=AccountConsistency,AppBanners,DesktopIOSPromotion,DoodlesOnLocalNtp,ExperimentalAppBanners,GamepadExtensions,GenericSensor,GenericSensorExtraClasses,IPH_DemoMode,ImageCaptureAPI,NewUsbBackend,NoStatePrefetch,OmniboxSpeculativeServiceWorkerStartOnQueryInput,OpenVR,OptimizationHints,ServiceWorkerPaymentApps,SpeculativePreconnect,SpeculativeResourcePrefetching,TopSitesFromSiteEngagement,TranslateRankerEnforcement,UseSuggestionsEvenIfFew,VoiceSearchOnLocalNtp,WebPayments,ZeroSuggestRedirectToChrome,affiliation-based-matching
EOF
)