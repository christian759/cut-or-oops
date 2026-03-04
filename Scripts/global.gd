extends Node

enum GameMode {
	RULES,
	SURVIVAL,
	RUSH,
	NORMAL
}

var current_mode: GameMode = GameMode.RULES
var games_played: int = 0

var interstitial_ad: InterstitialAd
var is_ad_loading := false
var ad_unit_id := "ca-app-pub-3940256099942544/1033173712" # Test Interstitial ID for Android

signal ad_finished

func _ready() -> void:
	MobileAds.initialize()
	_load_interstitial_ad()

func _load_interstitial_ad() -> void:
	if is_ad_loading or interstitial_ad:
		return
	
	is_ad_loading = true
	var interstitial_ad_loader := InterstitialAdLoader.new()
	var callback := InterstitialAdLoadCallback.new()
	
	callback.on_ad_loaded = func(ad: InterstitialAd):
		interstitial_ad = ad
		is_ad_loading = false
		print("AdMob: Interstitial loaded")
		
	callback.on_ad_failed_to_load = func(error: LoadAdError):
		is_ad_loading = false
		print("AdMob: Interstitial failed to load: ", error.message)
		# Retry in 10 seconds
		get_tree().create_timer(10.0).timeout.connect(_load_interstitial_ad)
	
	interstitial_ad_loader.load(ad_unit_id, AdRequest.new(), callback)

func show_ad_if_needed(parent: Node) -> Signal:
	games_played += 1
	
	if games_played >= 3:
		games_played = 0
		if interstitial_ad:
			interstitial_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = func():
				interstitial_ad = null
				_load_interstitial_ad()
				ad_finished.emit()
				
			interstitial_ad.full_screen_content_callback.on_ad_failed_to_show_full_screen_content = func(error):
				interstitial_ad = null
				_load_interstitial_ad()
				ad_finished.emit()
			
			interstitial_ad.show()
			return ad_finished
		else:
			# Ad not ready, just continue and try to load again
			_load_interstitial_ad()
	
	# Return a dummy timer to keep flow consistent
	return parent.get_tree().create_timer(0.01).timeout
