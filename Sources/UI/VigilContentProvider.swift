import Foundation
import Domain

public enum VigilContentProvider {

    // MARK: - Types

    public struct ScriptureFragment {
        public let text: String          // The paraphrased fragment
        public let citation: String      // "Psalm 46" — book and chapter only
    }

    public struct MilestoneVigilContent {
        public let companionAddition: String   // Extends the biological text
        public let scripture: ScriptureFragment
    }

    // MARK: - Idle Daily Fragment

    /// Returns the Scripture fragment for today. Changes daily, not per visit.
    /// Uses day-of-year modulo to cycle through the library.
    public static func idleFragment(for date: Date = Date()) -> ScriptureFragment {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 1
        let index = (dayOfYear - 1) % idleFragments.count
        return idleFragments[index]
    }

    // MARK: - Fast Start

    /// Fixed companion line shown at fast start. NOT Scripture.
    public static let fastStartLine = NSLocalizedString(
        "vigil.fastStart",
        bundle: .module,
        comment: "Vigil: companion line at fast start"
    )

    // MARK: - Milestones

    /// Returns the Vigil content for a given milestone.
    public static func milestoneContent(for milestone: FastingMilestone) -> MilestoneVigilContent {
        switch milestone {
        case .digestionCompleting:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.digestionCompleting.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.digestionCompleting.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.digestionCompleting.citation", bundle: .module, comment: "")
                )
            )
        case .beginningToShift:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.beginningToShift.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.beginningToShift.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.beginningToShift.citation", bundle: .module, comment: "")
                )
            )
        case .metabolicTransition:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.metabolicTransition.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.metabolicTransition.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.metabolicTransition.citation", bundle: .module, comment: "")
                )
            )
        case .deeperRhythm:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.deeperRhythm.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.deeperRhythm.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.deeperRhythm.citation", bundle: .module, comment: "")
                )
            )
        case .extendedFast:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.extendedFast.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.extendedFast.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.extendedFast.citation", bundle: .module, comment: "")
                )
            )
        case .prolongedFast:
            return MilestoneVigilContent(
                companionAddition: NSLocalizedString("vigil.milestone.prolongedFast.companion", bundle: .module, comment: ""),
                scripture: ScriptureFragment(
                    text: NSLocalizedString("vigil.milestone.prolongedFast.scripture", bundle: .module, comment: ""),
                    citation: NSLocalizedString("vigil.milestone.prolongedFast.citation", bundle: .module, comment: "")
                )
            )
        }
    }

    // MARK: - Arrival

    /// Returns the arrival Scripture fragment for the given completed fast index.
    /// Cycles through 5 fragments.
    public static func arrivalFragment(fastIndex: Int) -> ScriptureFragment {
        let index = abs(fastIndex) % arrivalFragments.count
        return arrivalFragments[index]
    }

    // MARK: - Forest Inscription

    public static let forestInscription = ScriptureFragment(
        text: NSLocalizedString("vigil.forest.inscription", bundle: .module, comment: ""),
        citation: NSLocalizedString("vigil.forest.inscription.citation", bundle: .module, comment: "")
    )

    // MARK: - Private Data

    private static let idleFragments: [ScriptureFragment] = [
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.0", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.0.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.1", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.1.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.2", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.2.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.3", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.3.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.4", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.4.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.5", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.5.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.6", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.6.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.7", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.7.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.8", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.8.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.idle.9", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.idle.9.citation", bundle: .module, comment: "")
        ),
    ]

    private static let arrivalFragments: [ScriptureFragment] = [
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.0", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.0.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.1", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.1.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.2", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.2.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.3", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.3.citation", bundle: .module, comment: "")
        ),
        ScriptureFragment(
            text: NSLocalizedString("vigil.arrival.4", bundle: .module, comment: ""),
            citation: NSLocalizedString("vigil.arrival.4.citation", bundle: .module, comment: "")
        ),
    ]
}
