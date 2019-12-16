# /etc/chromium-browser/default
# Default settings for chromium-browser. This file is sourced by /bin/sh from
# /usr/bin/chromium-browser

# --single-process is faster!
#  --force-color-profile=generic-rgb

#  --no-sandbox
# --disable-setuid-sandbox

# Keep the leading space before flags!
# REF: https://stackoverflow.com/a/1168084/1938889
# REF: https://chromium.googlesource.com/chromium/blink/+/master/Source/core/frame/Settings.in
CHROMIUM_FLAGS=$(
  cat <<'EOF'
 --blink-settings=imagesEnabled=false,loadsImagesAutomatically=false,scrollAnimatorEnabled=false,threadedScrollingEnabled=false,doHtmlPreloadScanning=true,lowPriorityIframes=true,offlineWebApplicationCacheEnabled=false,allowFileAccessFromFileURLs=false
 --force-color-profile=generic-rgb
 --no-zygote
 --disable-gpu
 --single-process
 --disable-dev-shm-usage
 --disable-breakpad
 --disable-cloud-import
 --disable-databases
 --disable-preconnect
 --disable-speech-api
 --disable-sync
 --disable-translate

 --ignore-certificate-errors
 --proxy-server=localhost:3128

 --disable-sync-preferences
 --disable-voice-input
 --disable-webgl
 --aggressive-cache-discard
 --disable-cache
 --disable-application-cache
 --disable-offline-load-stale-cache
 --disk-cache-size=0
 --user-data-dir=/dev/null
 --media-cache-dir=/dev/null
 --disk-cache-dir=/dev/null
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
