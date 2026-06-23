//
//  PageZoomControlsViewController.swift
//  Reynard
//
//  Created by Reynard on 23/6/26.
//

import UIKit

final class PageZoomControlsViewController: UIViewController {
    private enum UX {
        static let horizontalInset: CGFloat = 20
        static let verticalInset: CGFloat = 20
        static let controlSpacing: CGFloat = 18
        static let buttonSpacing: CGFloat = 12
        static let percentFontSize: CGFloat = 36
        static let hostFontSize: CGFloat = 14
        static let buttonHeight: CGFloat = 44
    }

    var onChange: (() -> Void)?

    private let urlString: String
    private let pageTitle: String
    private let store: PageZoomStore
    private var currentPercent: Int

    private let hostLabel = UILabel()
    private let percentLabel = UILabel()
    private let defaultLabel = UILabel()
    private let slider = UISlider()
    private let zoomOutButton = UIButton(type: .system)
    private let zoomInButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    init(urlString: String, pageTitle: String, store: PageZoomStore = .shared) {
        self.urlString = urlString
        self.pageTitle = pageTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        self.store = store
        self.currentPercent = store.zoomPercent(for: urlString)
        super.init(nibName: nil, bundle: nil)
        title = "Page Zoom"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        configureControls()
        applyCurrentState(notify: false)
    }

    private func configureView() {
        view.backgroundColor = BrowserAppearance.groupedBackgroundColor
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(doneButtonTapped)
        )
    }

    private func configureControls() {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = UX.controlSpacing
        stack.alignment = .fill
        stack.isLayoutMarginsRelativeArrangement = true
        stack.directionalLayoutMargins = NSDirectionalEdgeInsets(
            top: UX.verticalInset,
            leading: UX.horizontalInset,
            bottom: UX.verticalInset,
            trailing: UX.horizontalInset
        )

        hostLabel.font = .systemFont(ofSize: UX.hostFontSize, weight: .medium)
        hostLabel.textColor = .secondaryLabel
        hostLabel.numberOfLines = 2
        hostLabel.textAlignment = .center
        hostLabel.text = hostTitle()

        percentLabel.font = .systemFont(ofSize: UX.percentFontSize, weight: .bold)
        percentLabel.textColor = .label
        percentLabel.textAlignment = .center
        percentLabel.adjustsFontSizeToFitWidth = true
        percentLabel.minimumScaleFactor = 0.7

        defaultLabel.font = .preferredFont(forTextStyle: .footnote)
        defaultLabel.textColor = .secondaryLabel
        defaultLabel.numberOfLines = 2
        defaultLabel.textAlignment = .center

        slider.minimumValue = 0
        slider.maximumValue = Float(max(PageZoomLevel.allowedPercents.count - 1, 0))
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)

        configureButton(
            zoomOutButton,
            title: "Zoom Out",
            image: UIImage(systemName: "minus.magnifyingglass"),
            action: #selector(zoomOutButtonTapped)
        )
        configureButton(
            zoomInButton,
            title: "Zoom In",
            image: UIImage(systemName: "plus.magnifyingglass"),
            action: #selector(zoomInButtonTapped)
        )
        configureButton(
            resetButton,
            title: "Reset",
            image: UIImage(named: "reynard.arrow.clockwise") ?? UIImage(systemName: "arrow.counterclockwise"),
            action: #selector(resetButtonTapped)
        )

        let buttonStack = UIStackView(arrangedSubviews: [zoomOutButton, resetButton, zoomInButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = UX.buttonSpacing
        buttonStack.distribution = .fillEqually

        [hostLabel, percentLabel, slider, buttonStack, defaultLabel].forEach(stack.addArrangedSubview)
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor),
            zoomOutButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            resetButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
            zoomInButton.heightAnchor.constraint(equalToConstant: UX.buttonHeight),
        ])
    }

    private func configureButton(_ button: UIButton, title: String, image: UIImage?, action: Selector) {
        button.setTitle(title, for: .normal)
        button.setImage(image, for: .normal)
        button.tintColor = BrowserAppearance.accentColor
        button.titleLabel?.font = .preferredFont(forTextStyle: .body)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.titleLabel?.minimumScaleFactor = 0.75
        button.layer.cornerCurve = .continuous
        button.layer.cornerRadius = 8
        button.backgroundColor = BrowserAppearance.secondarySurfaceColor
        button.addTarget(self, action: action, for: .touchUpInside)
        if #available(iOS 15.0, *) {
            var configuration = UIButton.Configuration.plain()
            configuration.title = title
            configuration.image = image
            configuration.imagePlacement = .top
            configuration.imagePadding = 4
            configuration.baseForegroundColor = BrowserAppearance.accentColor
            configuration.titleLineBreakMode = .byTruncatingTail
            configuration.background.backgroundColor = BrowserAppearance.secondarySurfaceColor
            configuration.background.cornerRadius = 8
            button.configuration = configuration
        } else {
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -4, bottom: 0, right: 4)
        }
    }

    private func hostTitle() -> String {
        let host = DomainMatcher.host(from: urlString)
        if !pageTitle.isEmpty, let host {
            return "\(pageTitle)\n\(host)"
        }

        return host ?? pageTitle
    }

    private func applyCurrentState(notify: Bool) {
        currentPercent = store.zoomPercent(for: urlString)
        let defaultTitle = PageZoomLevel.displayTitle(for: store.defaultPercent)
        let displayTitle = PageZoomLevel.displayTitle(for: currentPercent)
        percentLabel.text = displayTitle
        defaultLabel.text = store.hasOverride(for: urlString)
        ? "Site override. Default is \(defaultTitle)."
        : "Using the default page zoom of \(defaultTitle)."
        slider.value = Float(PageZoomLevel.sliderIndex(for: currentPercent))
        zoomOutButton.isEnabled = PageZoomLevel.lowerPercent(than: currentPercent) != nil
        zoomInButton.isEnabled = PageZoomLevel.higherPercent(than: currentPercent) != nil
        resetButton.isEnabled = store.hasOverride(for: urlString)

        if notify {
            onChange?()
        }
    }

    private func setSitePercent(_ percent: Int) {
        store.setOverridePercent(percent, for: urlString)
        applyCurrentState(notify: true)
    }

    @objc private func sliderDidChange() {
        let percent = PageZoomLevel.percent(forSliderValue: slider.value)
        guard percent != currentPercent || !store.hasOverride(for: urlString) else {
            slider.value = Float(PageZoomLevel.sliderIndex(for: currentPercent))
            return
        }

        setSitePercent(percent)
    }

    @objc private func zoomOutButtonTapped() {
        guard let percent = store.lowerPercent(for: urlString) else {
            return
        }
        setSitePercent(percent)
    }

    @objc private func zoomInButtonTapped() {
        guard let percent = store.higherPercent(for: urlString) else {
            return
        }
        setSitePercent(percent)
    }

    @objc private func resetButtonTapped() {
        store.resetOverride(for: urlString)
        applyCurrentState(notify: true)
    }

    @objc private func doneButtonTapped() {
        dismiss(animated: true)
    }
}
