import UIKit

protocol StatsLoadingProgressDelegate {
    func didBeginLoadingStats(viewController: UIViewController)
    func statsLoadingProgress(viewController: UIViewController, percentage: Float)
    func didEndLoadingStats(viewController: UIViewController)
}

public class SiteStatsViewController: UIViewController {

    // MARK: - Properties

    @IBOutlet weak var filterTabBar: FilterTabBar!
    @IBOutlet weak var insightsContainerView: UIView!
    @IBOutlet weak var statsContainerView: UIView!
    @IBOutlet weak var progressView: UIProgressView!

    // TODO: replace UITableViewController with real controller names that
    // correspond to Insights and Stats.
    var insightsTableViewController: UITableViewController?
    var statsTableViewController: UITableViewController?

    // MARK: - View

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupFilterBar()
        getSelectedPeriodFromUserDefaults()
    }

    // MARK: - StatsLoadingProgressDelegate methods

    func didBeginLoadingStats(viewController: UIViewController) {

        guard shouldShowProgressView(viewController: viewController) else {
            return
        }

        progressView.isHidden = false
        progressView.setProgress(Constants.progressViewInitialProgress, animated: true)
    }

    func statsLoadingProgress(viewController: UIViewController, percentage: Float) {

        guard shouldShowProgressView(viewController: viewController) else {
            return
        }

        progressView.setProgress(percentage, animated: true)
    }

    func didEndLoadingStats(viewController: UIViewController) {

        guard shouldShowProgressView(viewController: viewController) else {
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.progressViewHideDelay)) {
            UIView.animate(withDuration: Constants.progressViewHideDuration, animations: {
                self.progressView.alpha = 0.0
            }, completion: { _ in
                self.progressView.isHidden = true
                self.progressView.alpha = 1.0
                self.progressView.progress = 0.0
            })
        }
    }

}

// MARK: - Private Extension

private extension SiteStatsViewController {

    struct Constants {
        static let userDefaultsKey = "LastSelectedStatsPeriodType"
        static let progressViewInitialProgress = Float(0.03)
        static let progressViewHideDelay = 1
        static let progressViewHideDuration = 0.25
    }

    enum StatsPeriodType: Int {
        case insights = 0
        case days = 1
        case weeks = 2
        case months = 3
        case years = 4

        static let allPeriods = [StatsPeriodType.insights, .days, .weeks, .months, .years]

        var filterTitle: String {
            switch self {
            case .insights: return NSLocalizedString("Insights", comment: "Title of Insights stats filter.")
            case .days: return NSLocalizedString("Days", comment: "Title of Days stats filter.")
            case .weeks: return NSLocalizedString("Weeks", comment: "Title of Weeks stats filter.")
            case .months: return NSLocalizedString("Months", comment: "Title of Months stats filter.")
            case .years: return NSLocalizedString("Years", comment: "Title of Years stats filter.")
            }
        }
    }

    var currentSelectedPeriod: StatsPeriodType {
        get {
            let selectedIndex = filterTabBar?.selectedIndex ?? StatsPeriodType.insights.rawValue
            return StatsPeriodType(rawValue: selectedIndex) ?? .insights
        }
        set {
            filterTabBar?.setSelectedIndex(newValue.rawValue)
            setContainerViewVisibility()
            saveSelectedPeriodToUserDefaults()
        }
    }

    func setContainerViewVisibility() {
        statsContainerView.isHidden = currentSelectedPeriod == .insights
        insightsContainerView.isHidden = !statsContainerView.isHidden
    }

    func shouldShowProgressView(viewController: UIViewController) -> Bool {

        var shouldShow = false

        if viewController == insightsTableViewController {
            shouldShow = !insightsContainerView.isHidden
        } else if viewController == statsTableViewController {
            shouldShow = !statsContainerView.isHidden
        }

        return shouldShow
    }

}

// MARK: - FilterTabBar Support

private extension SiteStatsViewController {

    func setupFilterBar() {
        filterTabBar.tintColor = WPStyleGuide.wordPressBlue()
        filterTabBar.deselectedTabColor = WPStyleGuide.greyDarken10()
        filterTabBar.dividerColor = WPStyleGuide.greyLighten20()

        filterTabBar.items = StatsPeriodType.allPeriods.map { $0.filterTitle }
        filterTabBar.addTarget(self, action: #selector(selectedFilterDidChange(_:)), for: .valueChanged)
    }

    @objc func selectedFilterDidChange(_ filterBar: FilterTabBar) {
        currentSelectedPeriod = StatsPeriodType(rawValue: filterBar.selectedIndex) ?? StatsPeriodType.insights

        // TODO: reload view based on selected tab
    }

}

// MARK: - User Defaults Support

private extension SiteStatsViewController {

    func saveSelectedPeriodToUserDefaults() {
        UserDefaults.standard.set(currentSelectedPeriod.rawValue, forKey: Constants.userDefaultsKey)
    }

    func getSelectedPeriodFromUserDefaults() {
        currentSelectedPeriod = StatsPeriodType(rawValue: UserDefaults.standard.integer(forKey: Constants.userDefaultsKey)) ?? .insights
    }
}