#import "Imports.h"

%group SettingsPage
%hook YTMAvatarAccountView
%property(nonatomic,strong) YTMUltimateSettingsController *YTMUltimateController;

- (void)setAccountMenuUpperButtons:(id)arg1 lowerButtons:(id)arg2 {
    
    UIImage *icon;
    if (@available(iOS 13, *)) {
        icon = [UIImage systemImageNamed:@"flame"];
    } else {
        icon = nil;
    }
    
    //Create the YTMusicUltimate button
    YTMAccountButton *button = [[%c(YTMAccountButton) alloc] initWithTitle:@"YTMusicUltimate" identifier:@"ytmult" icon:icon actionBlock:^(BOOL arg4){
        //Push YTMusicUltimate view controller.

        self.YTMUltimateController = [[YTMUltimateSettingsController alloc] init];
        [self._viewControllerForAncestor presentViewController:self.YTMUltimateController animated:YES completion:nil];
    }];

    button.tintColor = [UIColor redColor];

    //Add our custom button to the list.
    NSMutableArray *arrDown = [[NSMutableArray alloc] init];
    [arrDown addObjectsFromArray:arg2];
    [arrDown addObject:button];

    //Remove the subscribe to premium button.
    NSMutableArray *arrUp = [[NSMutableArray alloc] init];
    for (YTMAccountButton *yt_button in arg1) {
        if (![[yt_button.titleLabel text] containsString:@"Premium"]) {
            [arrUp addObject:yt_button];
        }
    }

    //Continue the function with our own parameters.
    %orig(arrUp, arrDown);
}
%end
%end

#pragma mark - Fix sideloading issues
%group SideloadingFixes
//Fix login (2) - Ginsu & AhmedBakfir
%hook SSOSafariSignIn
- (void)signInWithURL:(id)arg1 presentationAnchor:(id)arg2 completionHandler:(id)arg3 {
    NSURL *origURL = arg1;

    NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:origURL resolvingAgainstBaseURL:NO];
    NSMutableArray *newQueryItems = [urlComponents.queryItems mutableCopy];
    for (NSURLQueryItem *queryItem in urlComponents.queryItems) {
        if ([queryItem.name isEqualToString:@"system_version"]
            || [queryItem.name isEqualToString:@"app_version"]
            || [queryItem.name isEqualToString:@"kdlc"]
            || [queryItem.name isEqualToString:@"kss"]
            || [queryItem.name isEqualToString:@"lib_ver"]
            || [queryItem.name isEqualToString:@"device_model"]) {
            [newQueryItems removeObject:queryItem];
        }
    }
    urlComponents.queryItems = [newQueryItems copy];
    %orig(urlComponents.URL, arg2, arg3);
}
%end

//Force enable safari sign-in
%hook SSOConfiguration
- (BOOL)shouldEnableSafariSignIn {
    return YES;
}
%end

//Fix login (1) - thanks poomsmart & julioverne
%hook SSOService
+ (id)fetcherWithRequest:(NSMutableURLRequest *)request configuration:(id)configuration {
    if ([request isKindOfClass:[NSMutableURLRequest class]] && request.HTTPBody) {
        NSError *error = nil;
        NSMutableDictionary *body = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:NSJSONReadingMutableContainers error:&error];
        if (!error && [body isKindOfClass:[NSMutableDictionary class]]) {
            [body removeObjectForKey:@"device_challenge_request"];
            request.HTTPBody = [NSJSONSerialization dataWithJSONObject:body options:kNilOptions error:&error];
        }
    }
    return %orig;
}
%end

%hook SSOKeychainCore
//Thanks to jawshoeadan for this hook.
+ (id)accessGroup {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];

    return accessGroup;
}

+ (id)sharedAccessGroup {
    NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:
                           (__bridge NSString *)kSecClassGenericPassword, (__bridge NSString *)kSecClass,
                           @"bundleSeedID", kSecAttrAccount,
                           @"", kSecAttrService,
                           (id)kCFBooleanTrue, kSecReturnAttributes,
                           nil];
    CFDictionaryRef result = nil;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status == errSecItemNotFound)
        status = SecItemAdd((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);
    if (status != errSecSuccess)
        return nil;
    NSString *accessGroup = [(__bridge NSDictionary *)result objectForKey:(__bridge NSString *)kSecAttrAccessGroup];

    return accessGroup;
}
%end

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    if (groupIdentifier != nil) {
        NSArray *paths = [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
        NSURL *documentsURL = [paths lastObject];
        return [documentsURL URLByAppendingPathComponent:@"AppGroup"];
    }
    return %orig(groupIdentifier);
}
%end
%end

#pragma mark - Enabling cast
%group Cast
%hook MDXFeatureFlags
- (BOOL)isCastCloudDiscoveryEnabled {
    return YES;
}

- (void)setIsCastCloudDiscoveryEnabled:(BOOL)enabled {
    %orig(YES);
}

- (BOOL)isCastToNativeEnabled {
    return YES;
}

- (void)setIsCastToNativeEnabled:(BOOL)enabled {
    %orig(YES);
}

- (BOOL)isCastEnabled {
    return YES;
}

- (void)setIsCastEnabled:(BOOL)enabled {
    %orig(YES);
}
%end

%hook YTColdConfig
- (BOOL)isCastToNativeEnabled {
    return YES;
}

- (void)setIsCastToNativeEnabled:(BOOL)enabled {
    %orig(YES);
}

- (BOOL)isPersistentCastIconEnabled {
    return YES;
}

- (void)setIsPersistentCastIconEnabled:(BOOL)enabled {
    %orig(YES);
}

- (BOOL)musicEnableSuggestedCastDevices {
    return YES;
}

- (void)setMusicEnableSuggestedCastDevices:(BOOL)suggest {
    %orig(YES);
}

- (BOOL)musicClientConfigEnableCastButtonOnPlayerHeader {
    return YES;
}

- (void)setMusicClientConfigEnableCastButtonOnPlayerHeader:(BOOL)enabled {
    %orig(YES);
}

- (BOOL)musicClientConfigEnableAudioOnlyCastingForNonMusicAudio {
    return YES;
}

- (void)setMusicClientConfigEnableAudioOnlyCastingForNonMusicAudio:(BOOL)enabled {
    %orig(YES);
}
%end

%hook YTMCastSessionController
- (id)premiumUpgradeAction {
    return nil;
}

- (void)showAudioCastUpsellDialog {
    return;
}

- (BOOL)isFreeTierAudioCastEnabled {
    return YES;
}

- (void)setIsFreeTierAudioCastEnabled:(BOOL)enabled {
    %orig(YES);
}

- (void)openMusicPremiumLandingPage {
    return;
}
%end

%hook YTMMusicAppMetadata
- (BOOL)isAudioCastEnabled {
    return YES;
}

- (void)setIsAudioCastEnabled:(BOOL)enabled {
    %orig(YES);
}
%end
%end

#pragma mark - Removing premium promos
%group EnsurePremiumStatus
%hook MDXFeatureFlags
- (BOOL)areMementoPromotionsEnabled {
    return NO;
}

- (void)setAreMementoPromotionsEnabled:(BOOL)enabled {
    %orig(NO);
}
%end

%hook YTColdConfig
- (BOOL)isPassiveSignInUniquePremiumValuePropEnabled {
    return YES;
}

- (void)setIsPassiveSignInUniquePremiumValuePropEnabled:(BOOL)enabled {
    %orig(YES);
}
%end

%hook YTIPlayabilityStatus
- (id)backgroundUpsell {
    return nil;
}

- (id)offlineUpsell {
    return nil;
}
%end

%hook YTMAppDelegate
- (void)showUpsellAlertWithTitle:(id)arg1 subtitle:(id)arg2 upgradeButtonTitle:(id)arg3 upsellURLString:(id)arg4 sourceApplication:(id)arg5 {
    return;
}
%end

%hook MDXPromotionManager
- (void)presentMementoPromotionIfTriggerConditionsAreSatisfied {
    return;
}

- (void)presentMementoPromotion:(long long)arg1 {
    return;
}
%end

%hook YTPlayerPromoController
- (void)showBackgroundabilityUpsell {
    return;
}

- (void)showBackgroundOnboardingHint {
    return;
}

- (void)showPipOnboardingHint {
    return;
}
%end

%hook YTMMusicAppMetadata
- (BOOL)isPremiumSubscriber{
    return YES;
}

- (void)setIsPremiumSubscriber:(BOOL)premium {
    %orig(YES);
}

- (id)sidePanelPromo{
    return nil;
}
%end

%hook YTPivotBarView
- (void)setRenderer:(YTIPivotBarRenderer *)renderer {
    NSMutableArray <YTIPivotBarSupportedRenderers *> *items = [renderer itemsArray];

    NSUInteger index = [items indexOfObjectPassingTest:^BOOL(YTIPivotBarSupportedRenderers *renderers, NSUInteger idx, BOOL *stop) {
        return [[[renderers pivotBarItemRenderer] pivotIdentifier] isEqualToString:@"SPunlimited"];
    }];
    if (index != NSNotFound) [items removeObjectAtIndex:index];
    %orig;
}
%end

%hook YTIShowFullscreenInterstitialCommand
-(BOOL)shouldThrottleInterstitial{
    return YES;
}

- (void)setShouldThrottleInterstitial:(BOOL)throttle {
    %orig(YES);
}
%end

%hook YTMAppResponder
- (void)presentInterstitialPromoForEvent:(id)event{
    return;
}

- (void)presentFullscreenPromoForEvent:(id)event{
    return;
}

- (void)presentInterstitialGridPromoForEvent:(id)event{
    return;
}
%end

%hook YTPromosheetController
- (void)presentPromosheetWithEvent:(id)event{
    return;
}
%end

%hook YTMCarPlayController
- (BOOL)isPremiumSubscriber{
    return YES;
}

- (void)setIsPremiumSubscriber:(BOOL)premium {
    %orig(YES);
}
%end

%hook YTMYPCGetOfflineUpsellEndpointCommandHandler
- (BOOL)isPremiumSubscriber{
    return YES;
}

- (void)setIsPremiumSubscriber:(BOOL)premium {
    %orig(YES);
}
%end
%end

#pragma mark - Background playback
%group BackgroundPlayback
%hook YTMBackgroundUpsellNotificationController
- (id)upsellNotificationTriggerOnBackground {
    return nil;
}

- (void)appDidEnterBackground:(id)arg1 {
    return;
}

- (void)maybeScheduleBackgroundUpsellNotification {
    %orig;
    [self removePendingBackgroundNotifications];
}
%end

%hook YTColdConfig
- (BOOL)disablePlaybackLockScreenController {
    return NO;
}

- (void)setDisablePlaybackLockScreenController:(BOOL)enabled {
    %orig(NO);
}

- (BOOL)enableIMPBackgroundableAudio {
    return YES;
}

- (void)setEnableIMPBackgroundableAudio:(BOOL)enabled {
    %orig(YES);
}
%end

%hook YTMMusicAppMetadata
- (BOOL)canPlayBackgroundableContent {
    return YES;
}

- (void)setCanPlayBackgroundableContent:(BOOL)playable {
    %orig(YES);
}
%end

%hook HAMPlayer
- (BOOL)allowsBackgroundPlayback {
    return YES;
}

- (void)setAllowsBackgroundPlayback:(BOOL)allow {
    %orig(YES);
}
%end

%hook YTPlayerStatus
- (id)initWithExternalPlayback:(_Bool)arg1 backgroundPlayback:(_Bool)arg2 inlinePlaybackActive:(_Bool)arg3 cardboardModeActive:(_Bool)arg4 layout:(int)arg5 userAudioOnlyModeActive:(_Bool)arg6 blackoutActive:(_Bool)arg7 clipID:(id)arg8 accountLinkState:(id)arg9 muted:(_Bool)arg10 pictureInPicture:(_Bool)arg11 {
    return %orig(YES, YES, YES, YES, arg5, NO, YES, arg8, arg9, arg10, arg11);
}

- (BOOL)backgroundPlayback {
    return YES;
}

- (void)setBackgroundPlayback:(BOOL)backgroundable {
    %orig(YES);
}
%end

%hook YTPlaybackData
- (BOOL)isPlayable {
    return YES;
}

- (BOOL)isPlayableInBackground {
    return YES;
}

- (void)setIsPlayableInBackground:(BOOL)playable {
    %orig(YES);
}
%end

%hook YTPlaybackBackgroundTaskController
- (BOOL)isContentPlayableInBackground {
    return YES;
}

- (void)setIsContentPlayableInBackground:(BOOL)playable {
    %orig(YES);
}
%end

%hook YTLocalPlaybackController
- (void)stopBackgroundPlayback {
    return;
}

- (void)updateForceDisableBackgroundingForVideo:(id)arg1 {
    return;
}

- (void)maybeStopBackgroundPlayback {
    return;
}

- (BOOL)isPlaybackBackgroundable {
    return YES;
}

- (void)setIsPlaybackBackgroundable:(BOOL)playable {
    %orig(YES);
}
%end

%hook YTIPlayabilityStatus
- (BOOL)isPlayable {
    return YES;
}

- (BOOL)isPlayableInBackground{
    return YES;
}

- (void)setIsPlayableInBackground:(BOOL)backgroundable {
    %orig(YES);
}
%end

%hook YTSingleVideo
- (BOOL)isPlayableInBackground{
    return YES;
}

- (void)setIsPlayableInBackground:(BOOL)backgroundable {
    %orig(YES);
}
%end

%hook YTIBackgroundabilityRenderer
- (id)backgroundUpsell {
    return nil;
}

- (BOOL)backgroundable {
    return YES;
}

- (BOOL)hasBackgroundable {
    return YES;
}

- (BOOL)hasBackgroundPlaybackControls {
    return YES;
}
%end

%hook YTIPlayerResponse
- (BOOL)hasBackgroundability {
    return YES;
}

- (BOOL)hasPlayableInBackground {
    return YES;
}

- (BOOL)isDAIEnabledPlayback {
    return YES;
}

- (BOOL)isPlayableInBackground{
    return YES;
}

- (void)setIsPlayableInBackground:(BOOL)backgroundable {
    %orig(YES);
}
%end

%hook YTMIntentHandler
- (BOOL)isBackgroundPlaybackEnabled {
    return YES;
}

- (void)setIsBackgroundPlaybackEnabled:(BOOL)backgroundable {
    %orig(YES);
}
%end

%hook YTMSettings
- (BOOL)backgroundPlaybackModeModified {
    return NO;
}

- (void)setBackgroundPlaybackModeModified:(BOOL)modified {
    %orig(NO);
}

- (void)setBackgroundPlaybackMode:(long long)mode {
    %orig(1);
}

- (long long)backgroundPlaybackMode {
    return 1;
}
%end

%hook YTIMainAppColdConfig
- (BOOL)iosEnableImpBackgroundableAudio {
    return YES;
}

- (BOOL)hasIosEnableImpBackgroundableAudio {
    return YES;
}
%end
%end

#pragma mark - Removing ads
%group RemoveAds
%hook YTAdsInnerTubeContextDecorator
- (void)decorateContext:(id)arg1{
    return;
}
%end
%end

#pragma mark - Video/Audio switching
%group VideoAndAudioModePatches
%hook YTIPlayerResponse
- (id)ytm_audioOnlyPlayabilityRenderer {
    return nil;
}

- (id)ytm_audioOnlyUpsell {
    return nil;
}

- (BOOL)ytm_isAudioOnlyPlayable {
    return YES;
}

- (BOOL)isAudioOnlyAvailabilityBlocked {
    return NO;
}

- (void)setIsAudioOnlyAvailabilityBlocked:(BOOL)blocked{
    %orig(NO);
}

- (void)setYtm_isAudioOnlyPlayable:(BOOL)playable{
    %orig(YES);
}
%end

%hook YTMSettings
- (BOOL)noVideoModeEnabled{
    return NO;
}

- (void)setNoVideoModeEnabled:(BOOL)enabled {
    %orig(NO);
}
%end

%hook YTUserDefaults
- (BOOL)noVideoModeEnabled{
    return NO;
}

- (void)setNoVideoModeEnabled:(BOOL)enabled {
    %orig(NO);
}
%end

%hook YTMAudioVideoModeController
- (BOOL)isAudioOnlyBlocked {
    return NO;
}

- (void)setIsAudioOnlyBlocked:(BOOL)blocked {
    %orig(NO);
}

- (void)setSwitchAvailability:(long long)arg1 {
    %orig(1);
}
%end

%hook YTMQueueConfig
- (BOOL)isAudioVideoModeSupported {
    return YES;
}

- (void)setIsAudioVideoModeSupported:(BOOL)supported {
    %orig(YES);
}
%end

%hook YTDefaultQueueConfig
- (BOOL)isAudioVideoModeSupported {
    return YES;
}

- (void)setIsAudioVideoModeSupported:(BOOL)supported {
    %orig(YES);
}
%end
%end

#pragma mark - OLED Theme
%group oledTheme
%hook YTCommonColorPalette
- (UIColor *)brandBackgroundSolid { return [UIColor blackColor]; }
- (UIColor *)brandBackgroundPrimary { return [UIColor blackColor]; }
%end

%hook YTPivotBarView
- (void)didMoveToWindow {
    self.subviews[0].backgroundColor = [UIColor blackColor];
    %orig;
}
%end

%hook YTMMusicMenuTitleView
- (void)didMoveToWindow {
    self.backgroundColor = [UIColor blackColor];
    %orig;
}
%end

%hook MDCSnackbarMessageView
- (void)didMoveToWindow {
    self.backgroundColor = [UIColor blackColor];
    %orig;
}
%end
%end

#pragma mark - OLED Keyboard
%group oledKB
%hook UIPredictionViewController // support prediction bar - @ichitaso: http://gist.github.com/ichitaso/935100fd53a26f18a9060f7195a1be0e
- (void)loadView {
    %orig;
    [self.view setBackgroundColor:[UIColor blackColor]];
}
%end

%hook UICandidateViewController // support prediction bar - @ichitaso:http://gist.github.com/ichitaso/935100fd53a26f18a9060f7195a1be0e
- (void)loadView {
    %orig;
    [self.view setBackgroundColor:[UIColor blackColor]];
}
%end

%hook UIKBRenderConfig // Prediction text color
- (void)setLightKeyboard:(BOOL)arg1 { %orig(NO); }
%end

%hook UIKeyboardDockView
- (void)didMoveToWindow {
    self.backgroundColor = [UIColor blackColor];
    %orig;
}
%end

%hook UIKeyboardLayoutStar 
- (void)didMoveToWindow {
    self.backgroundColor = [UIColor blackColor];
    %orig;
}
%end
%end

#pragma mark - Playback rate
%group RateController
%hook YTMModularNowPlayingViewController
- (BOOL)playbackRateButtonEnabled {
    return YES;
}

- (void)setPlaybackRateButtonEnabled:(BOOL)enabled {
    %orig(YES);
}
%end

%hook YTMPlayerControlsView
- (BOOL)playbackRateButtonEnabled {
    return YES;
}

- (void)setPlaybackRateButtonEnabled:(BOOL)enabled {
    %orig(YES);
}
%end
%end

%group CarPlay
%hook YTIMusicColdConfig
- (BOOL)iosEnableCarplayLastplayedUpdates {
    return YES;
}

- (BOOL)hasIosEnableCarplayLastplayedUpdates {
    return YES;
}
%end

%hook YTIMusicIntegrationsColdConfig
- (BOOL)hasMusicIosCarplayEnableSdkLogic {
    return YES;
}

- (BOOL)musicIosCarplayEnableSdkLogic {
    return YES;
}
%end

%hook YTINotificationRegistration_APNSRegistration_EnabledSettings
- (BOOL)hasCarPlay {
    return YES;
}
%end

%hook YTMModularWatchViewController
- (BOOL)isCarPlayActive {
    return YES;
}
%end

%hook YTNowPlayingInfoCenterPlaybackObserver
- (BOOL)isCarPlayActive {
    return YES;
}
%end
%end

// %group Offline
// %hook YTColdConfig
// - (BOOL)allOfflineContentOnCommuteShelfEnabled {
//     return YES;
// }

// - (void)setAllOfflineContentOnCommuteShelfEnabled:(_Bool)arg1 {
//     %orig(YES);
// }
// %end

// %hook YTIBrowseResponse
// + (BOOL)offlineVideosAreDisplayable:(id)arg1 {
//     return YES;
// }
// %end

// %hook YTMAppResponder
// - (BOOL)allowsOfflineTransition {
//     return YES;
// }
// %end

// %hook YTHotConfig
// - (BOOL)isDownloadsPageCommuteEntryPointEnabled {
//     return YES;
// }

// - (void)setIsDownloadsPageCommuteEntryPointEnabled:(BOOL)enabled {
//     %orig(YES);
// }

// - (BOOL)enableDownloadsPageDRMVideosDecoration {
//     return NO;
// }

// - (BOOL)enableOfflineOrchestrationAPIForDRM {
//     return NO;
// }
// %end

// %hook YTMXSDKContentController
// - (BOOL)prefetchDownloadsEnabled {
//     return YES;
// }

// - (void)setPrefetchDownloadsEnabled:(BOOL)enabled {
//     %orig(YES);
// }
// %end

// %hook YTOfflineVideoDownloader
// - (BOOL)canDownloadVideo {
//     return YES;
// }
// %end

// %hook YTMOfflineContentAvailabilityController
// + (BOOL)offlineMixtapeEnabled {
//     return YES;
// }
// %end

// %hook YTOfflineVideo
// - (BOOL)isPlayableForOfflineStateDateSkewCheckForDate:(id)arg1 upsell:(id *)arg2 {
//     return YES;
// }

// - (BOOL)isPlayableForOfflineExpiryCheckForDate:(id)arg1 upsell:(id *)arg2 {
//     return YES;
// }

// - (BOOL)isPlayableForStatusWithUpsell:(id *)arg1 {
//     return YES;
// }

// - (BOOL)isPlayableForPlayabilityStatusWithUpsell:(id *)arg1 {
//     return YES;
// }

// - (BOOL)isPlayableForOfflineActionWithUpsell:(id *)arg1 {
//     return YES;
// }

// - (BOOL)isPlayableForManualDeletionCheckWithUpsell:(id *)arg1 {
//     return YES;
// }

// - (BOOL)isPlayableOfflineWithUpsell:(id *)arg1 {
//     return YES;
// }

// - (BOOL)isPlayableOfflineWithReason:(id *)arg1 {
//     return YES;
// }
// %end

// %hook YTIOfflineState
// - (BOOL)isPlayableOffline {
//     return YES;
// }

// - (id)offlineUpsell {
//     return nil;
// }

// - (BOOL)hasOfflineUpsell {
//     return NO;
// }

// - (BOOL)isOfflineSharingAllowed {
//     return YES;
// }

// - (BOOL)hasIsOfflineSharingAllowed {
//     return YES;
// }

// - (BOOL)hasOfflineFutureUnplayableInfo {
//     return NO;
// }

// - (BOOL)hasOfflinePlaybackDisabledReason {
//     return NO;
// }
// %end

// %hook YTOfflineFutureUnplayableInfoModel
// - (BOOL)hasUnplayableReason {
//     return NO;
// }

// - (BOOL)becomesUnplayableInSeconds {
//     return NO;
// }

// - (BOOL)hasBecomesUnplayableInSeconds {
//     return NO;
// }
// %end

// %hook YTOfflineVideoController
// - (void)reportNotPlayableOfflineWithPlayerResponse:(id)arg1 responseBlock:(id)arg2 {
//     return;
// }
// %end

// %hook YTOfflineVideoPolicyEntityModel
// - (BOOL)hasOfflinePlaybackDisabledReason {
//     return NO;
// }
// %end
// %end

%ctor{
    %init;

    //Get / read values
    BOOL isEnabled = ([[NSUserDefaults standardUserDefaults] objectForKey:@"YTMUltimateIsEnabled"] != nil) ? [[NSUserDefaults standardUserDefaults] boolForKey:@"YTMUltimateIsEnabled"] : YES;
    BOOL oledDarkTheme = ([[NSUserDefaults standardUserDefaults] objectForKey:@"oledDarkTheme_enabled"] != nil) ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oledDarkTheme_enabled"] : NO;
    BOOL oledDarkKeyboard = ([[NSUserDefaults standardUserDefaults] objectForKey:@"oledDarkKeyboard_enabled"] != nil) ? [[NSUserDefaults standardUserDefaults] boolForKey:@"oledDarkKeyboard_enabled"] : NO;
    BOOL playbackRateButton = ([[NSUserDefaults standardUserDefaults] objectForKey:@"playbackRateButton_enabled"] != nil) ? [[NSUserDefaults standardUserDefaults] boolForKey:@"playbackRateButton_enabled"] : NO;

    //Apply patches
    %init(SideloadingFixes);
    %init(SettingsPage);
    
    if (isEnabled){
        %init(Cast);
        %init(BackgroundPlayback);
        %init(EnsurePremiumStatus);
        %init(RemoveAds);
        %init(VideoAndAudioModePatches);
        %init(CarPlay);
        //%init(Offline);

        if (oledDarkTheme) {
            %init(oledTheme);
        }

        if (oledDarkKeyboard) {
            %init(oledKB);
        }

        if (playbackRateButton) {
            %init(RateController);
        }
    }
}
