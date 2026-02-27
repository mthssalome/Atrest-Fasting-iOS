import Foundation

public enum L10n {

    // MARK: - Timer Screen

    public static let timerIdlePrompt = tr("timer.idle.prompt", "Idle state prompt")
    public static let timerActiveLabel = tr("timer.active.label", "Active fast label")
    public static let timerCompletedLabel = tr("timer.completed.label", "Completed fast label")
    public static let timerAbandonedLabel = tr("timer.abandoned.label", "Abandoned fast label")
    public static let timerElapsedFormat = tr("timer.elapsed.format", "Elapsed time format")
    public static let timerActionBegin = tr("timer.action.begin", "Begin fast action")
    public static let timerActionEnd = tr("timer.action.end", "End fast action")
    public static let timerActionAbandon = tr("timer.action.abandon", "End early action")

    // MARK: - Biological Milestones

    public static let milestoneNone = tr("milestone.none", "No milestone reached yet")
    public static let milestoneDigestionCompleting = tr("milestone.digestionCompleting", "0-4 hours: digestion completing")
    public static let milestoneBeginningToShift = tr("milestone.beginningToShift", "4-8 hours: beginning to shift")
    public static let milestoneMetabolicTransition = tr("milestone.metabolicTransition", "8-12 hours: metabolic transition")
    public static let milestoneDeeperRhythm = tr("milestone.deeperRhythm", "12-16 hours: deeper rhythm")
    public static let milestoneExtendedFast = tr("milestone.extendedFast", "16-24 hours: extended fast")
    public static let milestoneProlongedFast = tr("milestone.prolongedFast", "24+ hours: prolonged fast")

    // MARK: - Forest Screen (accessibility only)

    public static let forestA11yTreeComplete = tr("forest.a11y.tree.complete", "Complete tree a11y label")
    public static let forestA11yTreeIncomplete = tr("forest.a11y.tree.incomplete", "Incomplete tree a11y label")
    public static let forestA11yStar = tr("forest.a11y.star", "Star a11y label")
    public static let forestA11yCanvas = tr("forest.a11y.canvas", "Forest canvas a11y label")

    // MARK: - Calendar Screen

    public static let calendarTitle = tr("calendar.title", "Calendar title")
    public static let calendarDetailDuration = tr("calendar.detail.duration", "Duration format in detail overlay")
    public static let calendarDetailCompleted = tr("calendar.detail.completed", "Completed label in detail overlay")
    public static let calendarDetailIncomplete = tr("calendar.detail.incomplete", "Incomplete label in detail overlay")

    // MARK: - Settings Screen

    public static let settingsTitle = tr("settings.title", "Settings title")
    public static let settingsSectionFasting = tr("settings.section.fasting", "Fasting section header")
    public static let settingsFastingTarget = tr("settings.fasting.target", "Target duration label")
    public static let settingsFastingTargetNote = tr("settings.fasting.target.note", "Target duration explanatory note")
    public static let settingsSectionHydration = tr("settings.section.hydration", "Hydration section header")
    public static let settingsHydrationUnit = tr("settings.hydration.unit", "Unit preference label")
    public static let settingsHydrationUnitMl = tr("settings.hydration.unit.ml", "Millilitres unit")
    public static let settingsHydrationUnitOz = tr("settings.hydration.unit.oz", "Fluid ounces unit")
    public static let settingsHydrationQuickAdd = tr("settings.hydration.quickAdd", "Quick-add amount label")
    public static let settingsSectionPremium = tr("settings.section.premium", "Premium section header")
    public static let settingsPremiumGo = tr("settings.premium.go", "Go premium action")
    public static let settingsSectionData = tr("settings.section.data", "Data section header")
    public static let settingsExport = tr("settings.export", "Export data action")
    public static let settingsImport = tr("settings.import", "Import data action")
    public static let settingsImportNote = tr("settings.import.note", "Import explanatory note")
    public static let settingsImportSuccess = tr("settings.import.success", "Import success message")
    public static let settingsDataExplanation = tr("settings.data.explanation", "Local data explanation")
    public static let settingsSectionAccount = tr("settings.section.account", "Account section header")
    public static let settingsManageSubscription = tr("settings.manage.subscription", "Manage subscription link")
    public static let settingsRestore = tr("settings.restore", "Restore purchases action")
    public static let settingsSectionLegal = tr("settings.section.legal", "Legal section header")
    public static let settingsTerms = tr("settings.terms", "Terms of Service link")
    public static let settingsPrivacy = tr("settings.privacy", "Privacy Policy link")
    public static let settingsTermsURL = tr("settings.terms.url", "Terms URL")
    public static let settingsPrivacyURL = tr("settings.privacy.url", "Privacy URL")

    // MARK: - Paywall / Premium Surface

    public static let paywallValues = tr("paywall.values", "Values statement on paywall")
    public static let paywallDescription = tr("paywall.description", "Experiential description of premium")
    public static let paywallAnnual = tr("paywall.annual", "Annual price label")
    public static let paywallLifetime = tr("paywall.lifetime", "Lifetime price label")
    public static let paywallRestore = tr("paywall.restore", "Restore purchases action")
    public static let paywallAppleNote = tr("paywall.apple.note", "Apple purchase reassurance")
    public static let paywallRenewalNote = tr("paywall.renewal.note", "Renewal disclosure")
    public static let paywallTerms = tr("paywall.terms", "Terms of Service label")
    public static let paywallPrivacy = tr("paywall.privacy", "Privacy Policy label")
    public static let paywallTermsURL = tr("settings.terms.url", "Terms URL (shared)")
    public static let paywallPrivacyURL = tr("settings.privacy.url", "Privacy URL (shared)")
    public static let paywallStatusProcessing = tr("paywall.status.processing", "Processing purchase")
    public static let paywallStatusRestoring = tr("paywall.status.restoring", "Restoring purchase")
    public static let paywallStatusError = tr("paywall.status.error", "Purchase error")
    public static let paywallStatusSuccess = tr("paywall.status.success", "Purchase success")

    // MARK: - Transition Moment (after 10th fast)

    public static let transitionBody = tr("transition.body", "Transition moment body text")
    public static let transitionContinue = tr("transition.continue", "Continue with premium action")
    public static let transitionLater = tr("transition.later", "Dismiss transition moment")

    // MARK: - Water (Inline Element)

    public static let waterTodayTotal = tr("water.today.total", "Today's water total format")
    public static let waterAdd = tr("water.add", "Water quick-add button format")
    public static let waterA11yDrop = tr("water.a11y.drop", "Water drop a11y label")

    // MARK: - Navigation (Accessibility)

    public static let navA11yEscape = tr("nav.a11y.escape", "Escape hatch a11y label")
    public static let navA11yForest = tr("nav.a11y.forest", "Forest nav a11y label")
    public static let navA11yCalendar = tr("nav.a11y.calendar", "Calendar nav a11y label")
    public static let navA11ySettings = tr("nav.a11y.settings", "Settings nav a11y label")

    // MARK: - Vigil (Depth Layer)

    public static let vigilSectionTitle = tr("vigil.section.title", "Vigil section header in settings")
    public static let vigilSectionExplanation = tr("vigil.section.explanation", "Vigil toggle explanation")
    public static let vigilFastStart = tr("vigil.fastStart", "Vigil: fast start companion line")
    public static let vigilA11yScripture = tr("vigil.a11y.scripture", "Scripture accessibility format")
    public static let vigilA11yCitation = tr("vigil.a11y.citation", "Citation accessibility format")

    // MARK: - Internal

    private static func tr(_ key: String, _ comment: String) -> String {
        NSLocalizedString(key, bundle: .module, comment: comment)
    }
}
