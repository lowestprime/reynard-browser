//  HistoryViewController.swift
//  Reynard
//
//  Created by Minh Ton on 9/3/26.
//

import UIKit

final class HistoryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIGestureRecognizerDelegate, UIDocumentPickerDelegate {
    private enum UX {
        static let estimatedRowHeight: CGFloat = 72
        static let sectionHeaderTopPadding: CGFloat = 0
        static let groupedSectionHeaderHeight: CGFloat = 34
        static let headerClearButtonTrailingInset: CGFloat = 20
    }
    
    private enum Fetch {
        static let pageSize = 100
        static let prefetchThreshold = 8
        static let searchLimit = 50
    }
    
    private enum FetchState {
        case idle
        case loading
    }
    
    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar(frame: .zero)
        searchBar.autocapitalizationType = .none
        searchBar.autocorrectionType = .no
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search History"
        searchBar.delegate = self
        return searchBar
    }()
    
    private lazy var clearHistoryButton = LibraryActionButton(
        target: self,
        iconName: "reynard.clock.badge.xmark",
        action: #selector(didTapHistoryActions)
    )
    private lazy var clearHistoryActionItem: UIBarButtonItem = {
        let item = UIBarButtonItem(
            image: UIImage(named: "reynard.clock.badge.xmark"),
            style: .plain,
            target: self,
            action: #selector(didTapHistoryActions)
        )
        item.tag = LibraryActionButton.historyNavigationActionTag
        return item
    }()
    private var showsNavigationClearAction: Bool {
        if #available(iOS 26.0, *) {
            return true
        }
        
        return false
    }
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let view = UITableView(frame: .zero, style: .insetGrouped)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = BrowserAppearance.groupedBackgroundColor
        view.dataSource = self
        view.delegate = self
        view.rowHeight = UITableView.automaticDimension
        view.estimatedRowHeight = UX.estimatedRowHeight
        view.separatorStyle = .singleLine
        if #available(iOS 15.0, *) {
            view.sectionHeaderTopPadding = UX.sectionHeaderTopPadding
        }
        view.register(HistoryItemCell.self, forCellReuseIdentifier: HistoryItemCell.reuseIdentifier)
        return view
    }()
    
    private let emptyStateView = SidebarEmptyBackgroundView(message: "Your browsing history appears here")
    private var sections: [HistorySection] = []
    private var storeObserver: NSObjectProtocol?
    private var nextOffset = 0
    private var hasMoreItems = true
    private var fetchState: FetchState = .idle
    private var query = ""
    private var loadVersion = 0
    private var skipsNextStoreReload = false
    private var isImportingHistory = false
    
    // MARK: - Lifecycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = BrowserAppearance.groupedBackgroundColor
        
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        installHeader()
        updateHistoryMenu()
        
        storeObserver = NotificationCenter.default.addObserver(
            forName: .historyStoreDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.skipsNextStoreReload {
                self.skipsNextStoreReload = false
                return
            }
            self.reloadHistory()
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSearch))
        tapGesture.cancelsTouchesInView = false
        tapGesture.delegate = self
        tableView.addGestureRecognizer(tapGesture)
        
        refreshHistoryPresence()
        reloadHistory()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        if let storeObserver {
            NotificationCenter.default.removeObserver(storeObserver)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        LibrarySharedUtils.syncTableHeaderWidth(headerView, in: tableView)
        tableView.backgroundView?.frame = tableView.bounds
        emptyStateView.updateContentInsets(from: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        installClearHistoryNavigationActionIfNeeded()
    }
    
    // MARK: - View Setup
    
    private func installHeader() {
        headerView.layoutMargins = tableView.layoutMargins
        headerView.addSubview(searchBar)
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints = [
            searchBar.topAnchor.constraint(equalTo: headerView.layoutMarginsGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.leadingAnchor),
            searchBar.bottomAnchor.constraint(equalTo: headerView.bottomAnchor)
        ]
        
        if showsNavigationClearAction {
            constraints.append(searchBar.trailingAnchor.constraint(equalTo: headerView.layoutMarginsGuide.trailingAnchor))
        } else {
            headerView.addSubview(clearHistoryButton)
            clearHistoryButton.translatesAutoresizingMaskIntoConstraints = false
            constraints.append(contentsOf: [
                searchBar.trailingAnchor.constraint(equalTo: clearHistoryButton.leadingAnchor),
                clearHistoryButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -UX.headerClearButtonTrailingInset),
                clearHistoryButton.centerYAnchor.constraint(equalTo: searchBar.searchTextField.centerYAnchor),
                clearHistoryButton.widthAnchor.constraint(equalTo: clearHistoryButton.heightAnchor),
                clearHistoryButton.heightAnchor.constraint(equalTo: searchBar.searchTextField.heightAnchor),
            ])
        }
        
        NSLayoutConstraint.activate(constraints)
        
        let targetWidth = view.bounds.width > 0 ? view.bounds.width : UIScreen.main.bounds.width
        headerView.frame = CGRect(x: 0, y: 0, width: targetWidth, height: 0)
        LibrarySharedUtils.updateTableHeaderHeight(headerView, in: tableView)
        
    }
    
    private func refreshHistoryPresence() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let hasHistory = !HistoryStore.shared.currentSnapshot(limit: 1, offset: 0).items.isEmpty
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                
                self.updateSearchHeaderVisibility(containsHistory: hasHistory)
            }
        }
    }
    
    private func updateSearchHeaderVisibility(containsHistory: Bool) {
        if containsHistory {
            if tableView.tableHeaderView !== headerView {
                tableView.tableHeaderView = headerView
                LibrarySharedUtils.syncTableHeaderWidth(headerView, in: tableView)
            }
            return
        }
        
        if tableView.tableHeaderView != nil {
            tableView.tableHeaderView = nil
        }
    }
    
    @objc private func dismissSearch() {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - Clear History
    
    @objc private func showClearHistory() {
        searchBar.resignFirstResponder()
        
        let browserViewController = LibrarySharedUtils.resolvedBrowserViewController(from: self)
        let viewController = ClearHistoryViewController(tabCount: browserViewController?.tabManager.regularTabs.count ?? 0) { [weak browserViewController] startDate, shouldCloseTabs in
            HistoryStore.shared.clearVisits(since: startDate)
            
            if shouldCloseTabs {
                browserViewController?.tabManager.removeAllTabs(mode: .regular)
                browserViewController?.tabManager.removeAllTabs(mode: .private)
                browserViewController?.tabManager.createTab(selecting: true, mode: .regular)
            }
        }
        let navigationController = UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = .pageSheet
        present(navigationController, animated: true)
    }

    @objc private func didTapHistoryActions() {
        if #available(iOS 14.0, *) {
            showClearHistory()
            return
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Clear History", style: .destructive) { [weak self] _ in
            self?.showClearHistory()
        })
        alert.addAction(UIAlertAction(title: "Import History", style: .default) { [weak self] _ in
            self?.confirmHistoryImport()
        })
        alert.addAction(UIAlertAction(title: "Export History", style: .default) { [weak self] _ in
            self?.confirmHistoryExport()
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.popoverPresentationController?.sourceView = clearHistoryButton
        alert.popoverPresentationController?.sourceRect = clearHistoryButton.bounds
        present(alert, animated: true)
    }
    
    private func installClearHistoryNavigationActionIfNeeded() {
        guard showsNavigationClearAction,
              let navigationItem = navigationController?.topViewController?.navigationItem else {
            return
        }
        
        clearHistoryActionItem.tintColor = .label
        updateHistoryMenu()
        LibraryActionButton.installNavigationAction(clearHistoryActionItem, in: navigationItem)
    }

    private func updateHistoryMenu() {
        if #available(iOS 14.0, *) {
            let menu = makeHistoryMenu()
            clearHistoryActionItem.menu = menu
            clearHistoryActionItem.target = nil
            clearHistoryActionItem.action = nil
            clearHistoryButton.menu = menu
            clearHistoryButton.showsMenuAsPrimaryAction = true
        }
    }

    @available(iOS 14.0, *)
    private func makeHistoryMenu() -> UIMenu {
        UIMenu(title: "", children: [
            UIAction(
                title: "Clear History",
                image: UIImage(named: "reynard.clock.badge.xmark"),
                attributes: .destructive
            ) { [weak self] _ in
                self?.showClearHistory()
            },
            UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [
                UIAction(title: "Import History", image: UIImage(systemName: "square.and.arrow.down")) { [weak self] _ in
                    self?.confirmHistoryImport()
                },
                UIAction(title: "Export History", image: UIImage(systemName: "square.and.arrow.up")) { [weak self] _ in
                    self?.confirmHistoryExport()
                },
            ]),
        ])
    }

    // MARK: - History Transfer

    private func confirmHistoryExport() {
        let alert = UIAlertController(
            title: "Export History",
            message: "This creates a local CSV file that may include private URLs and page titles.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Export", style: .default) { [weak self] _ in
            self?.exportHistory()
        })
        present(alert, animated: true)
    }

    private func exportHistory() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let items = HistoryStore.shared.currentSnapshot().items
            let data = HistoryCSVTransfer.exportCSV(items: items)
            let exportURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(HistoryCSVTransfer.fileName)

            do {
                try data.write(to: exportURL, options: .atomic)
                DispatchQueue.main.async { [weak self] in
                    self?.presentExportShareSheet(for: exportURL)
                }
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.presentTransferError(message: "Could not create the history export file.")
                }
            }
        }
    }

    private func presentExportShareSheet(for url: URL) {
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        controller.popoverPresentationController?.sourceView = view
        controller.popoverPresentationController?.sourceRect = CGRect(
            x: view.bounds.midX,
            y: view.bounds.midY,
            width: 1,
            height: 1
        )
        present(controller, animated: true)
    }

    private func confirmHistoryImport() {
        let alert = UIAlertController(
            title: "Import History",
            message: "Choose a Reynard CSV history export. Imported rows are stored locally; this is not Firefox Sync.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Choose File", style: .default) { [weak self] _ in
            self?.presentHistoryImporter()
        })
        present(alert, animated: true)
    }

    private func presentHistoryImporter() {
        isImportingHistory = true
        let controller = UIDocumentPickerViewController(
            documentTypes: ["public.comma-separated-values-text", "public.text"],
            in: .import
        )
        controller.delegate = self
        controller.allowsMultipleSelection = false
        present(controller, animated: true)
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard isImportingHistory, let url = urls.first else {
            isImportingHistory = false
            return
        }

        isImportingHistory = false
        importHistory(from: url)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        isImportingHistory = false
    }

    private func importHistory(from url: URL) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let didStartAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if didStartAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async { [weak self] in
                    self?.presentTransferError(message: "Could not read the selected history file.")
                }
                return
            }

            let importedItems = HistoryCSVTransfer.parseHistory(from: data)
            for item in importedItems {
                HistoryStore.shared.recordVisit(url: item.url, title: item.title, visitedAt: item.visitedAt)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.reloadHistory()
                self?.presentImportSummary(DataImportSummary(imported: importedItems.count, skipped: 0))
            }
        }
    }

    private func presentImportSummary(_ summary: DataImportSummary) {
        let alert = UIAlertController(
            title: "Import Complete",
            message: "Imported \(summary.imported) history rows. Skipped \(summary.skipped).",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func presentTransferError(message: String) {
        let alert = UIAlertController(title: "Transfer Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Loading
    
    private func reloadHistory() {
        refreshHistoryPresence()
        if !query.isEmpty {
            searchHistory(term: query)
            return
        }
        
        reloadFirstHistoryPage()
    }
    
    private func reloadFirstHistoryPage() {
        loadVersion += 1
        nextOffset = 0
        hasMoreItems = true
        fetchState = .idle
        loadNextHistoryPage()
    }
    
    private func loadNextHistoryPage() {
        guard query.isEmpty, hasMoreItems, fetchState == .idle else {
            return
        }
        
        fetchState = .loading
        let offset = nextOffset
        let generation = loadVersion
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            
            let items = HistoryStore.shared.currentSnapshot(limit: Fetch.pageSize, offset: offset).items
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                
                guard self.loadVersion == generation, self.query.isEmpty else {
                    return
                }
                
                self.appendHistoryPage(items, reset: offset == 0)
                self.nextOffset += items.count
                self.hasMoreItems = items.count == Fetch.pageSize
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.fetchState = .idle
                }
            }
        }
    }
    
    // MARK: - Paging
    
    private func appendHistoryPage(_ items: [HistorySiteSnapshot], reset: Bool) {
        let fetchedSections = HistorySection.make(from: items)
        
        if reset {
            sections = fetchedSections
            updateEmptyState()
            tableView.reloadData()
            return
        }
        
        guard !fetchedSections.isEmpty else {
            updateEmptyState()
            return
        }
        
        updateEmptyState()
        
        if sections.isEmpty {
            sections = fetchedSections
            tableView.reloadData()
            return
        }
        
        var updatedSections = sections
        var mergedRowIndexPaths: [IndexPath] = []
        var sectionsToInsert = fetchedSections[...]
        
        if let lastSectionIndex = updatedSections.indices.last,
           let firstFetchedSection = sectionsToInsert.first,
           updatedSections[lastSectionIndex].day == firstFetchedSection.day {
            let startRow = updatedSections[lastSectionIndex].items.count
            updatedSections[lastSectionIndex].items.append(contentsOf: firstFetchedSection.items)
            mergedRowIndexPaths = firstFetchedSection.items.indices.map {
                IndexPath(row: startRow + $0, section: lastSectionIndex)
            }
            sectionsToInsert = sectionsToInsert.dropFirst()
        }
        
        let insertStartIndex = updatedSections.count
        updatedSections.append(contentsOf: sectionsToInsert)
        sections = updatedSections
        
        tableView.performBatchUpdates {
            if !mergedRowIndexPaths.isEmpty {
                tableView.insertRows(at: mergedRowIndexPaths, with: .none)
            }
            
            if !sectionsToInsert.isEmpty {
                let insertedIndexes = IndexSet(insertStartIndex..<(insertStartIndex + sectionsToInsert.count))
                tableView.insertSections(insertedIndexes, with: .none)
            }
        }
    }
    
    // MARK: - Search
    
    private func searchHistory(term: String, preserveFocusOnClear: Bool = false) {
        let normalizedTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if normalizedTerm.isEmpty {
            query = ""
            HistoryStore.shared.interruptReader()
            reloadFirstHistoryPage()
            if preserveFocusOnClear {
                DispatchQueue.main.async { [weak self] in
                    guard let self, self.searchBar.window != nil else {
                        return
                    }
                    
                    self.searchBar.becomeFirstResponder()
                }
            }
            return
        }
        
        query = normalizedTerm
        
        HistoryStore.shared.interruptReader()
        loadVersion += 1
        let generation = loadVersion
        fetchState = .loading
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            
            let items = HistoryStore.shared.search(matching: normalizedTerm, limit: Fetch.searchLimit).items
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }
                
                guard self.loadVersion == generation, self.query == normalizedTerm else {
                    return
                }
                
                self.sections = HistorySection.make(from: items)
                self.hasMoreItems = false
                self.updateEmptyState()
                self.tableView.reloadData()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    self?.fetchState = .idle
                }
            }
        }
    }
    
    // MARK: - Display State
    
    private func updateEmptyState() {
        let hasRows = !sections.isEmpty
        emptyStateView.message = query.isEmpty ? "Your browsing history appears here" : "No matching history"
        tableView.backgroundView = hasRows ? nil : emptyStateView
        emptyStateView.updateContentInsets(from: tableView)
    }
    
    private func item(at indexPath: IndexPath) -> HistorySiteSnapshot? {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].items.indices.contains(indexPath.row) else {
            return nil
        }
        
        return sections[indexPath.section].items[indexPath.row]
    }
    
    private var loadedItemCount: Int {
        return sections.reduce(0) { $0 + $1.items.count }
    }
    
    private func flatRowIndex(for indexPath: IndexPath) -> Int {
        let priorCount = sections[..<indexPath.section].reduce(0) { $0 + $1.items.count }
        return priorCount + indexPath.row
    }
    
    private func loadNextPageIfNeeded(for indexPath: IndexPath) {
        let remainingItems = loadedItemCount - flatRowIndex(for: indexPath) - 1
        guard remainingItems <= Fetch.prefetchThreshold else {
            return
        }
        
        loadNextHistoryPage()
    }
    
    // MARK: - Navigation
    
    private func openHistoryItem(_ item: HistorySiteSnapshot) {
        guard let browserViewController = LibrarySharedUtils.resolvedBrowserViewController(from: self) else {
            return
        }
        
        browserViewController.loadViewIfNeeded()
        browserViewController.tabManager.browse(to: item.url.absoluteString)
        
        if navigationController?.presentingViewController is BrowserViewController {
            navigationController?.dismiss(animated: true)
        }
    }
    
    // MARK: - Deletion
    
    private func deleteVisibleRow(at indexPath: IndexPath) {
        guard sections.indices.contains(indexPath.section),
              sections[indexPath.section].items.indices.contains(indexPath.row) else {
            return
        }
        
        sections[indexPath.section].items.remove(at: indexPath.row)
        
        if sections[indexPath.section].items.isEmpty {
            sections.remove(at: indexPath.section)
            tableView.deleteSections(IndexSet(integer: indexPath.section), with: .automatic)
        } else {
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        
        updateEmptyState()
        refreshHistoryPresence()
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard sections.indices.contains(section) else {
            return 0
        }
        
        return sections[section].items.count
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: HistoryItemCell.reuseIdentifier,
            for: indexPath
        ) as? HistoryItemCell,
              let item = item(at: indexPath) else {
            return UITableViewCell()
        }
        
        cell.configure(with: item)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard sections.indices.contains(section) else {
            return nil
        }
        
        return LibrarySharedUtils.makeGroupedSectionHeader(title: sections[section].title)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return UX.groupedSectionHeaderHeight
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        loadNextPageIfNeeded(for: indexPath)
    }
    
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self, let item = self.item(at: indexPath) else {
                completion(false)
                return
            }
            
            self.skipsNextStoreReload = true
            HistoryStore.shared.removeSite(id: item.id)
            self.deleteVisibleRow(at: indexPath)
            completion(true)
        }
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = true
        return configuration
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let item = item(at: indexPath) else {
            return
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
        openHistoryItem(item)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let preserveFocusOnClear = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && searchBar.isFirstResponder
        searchHistory(term: searchText, preserveFocusOnClear: preserveFocusOnClear)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    // MARK: - UIGestureRecognizerDelegate
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard gestureRecognizer.view === tableView else {
            return true
        }
        
        return LibrarySharedUtils.isTapOutsideSearchBar(touch, in: tableView, ignoring: searchBar)
    }
}
