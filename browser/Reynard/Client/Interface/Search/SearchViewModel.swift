//
//  SearchViewModel.swift
//  Reynard
//
//  Created by Minh Ton on 11/6/26.
//

import Foundation

struct SearchResults {
    var query: String
    var bestMatch: UserDataSearchResult?
    var completions: [String]
    var userDataResults: [UserDataSearchResult]
    
    static let empty = SearchResults(
        query: "",
        bestMatch: nil,
        completions: [],
        userDataResults: []
    )
}

final class SearchViewModel {
    var resultsDidChange: ((SearchResults) -> Void)?
    var searchSuggestionProvider: SearchCompletion.Provider {
        return searchCompletion.provider
    }
    var completionSectionTitle: String {
        showsRemoteSuggestions ? "\(searchSuggestionProvider.name) Suggestions" : "Local Suggestions"
    }
    
    private let userDataSearch: UserDataSearch
    private var searchCompletion: SearchCompletion
    private var requestID = 0
    private var completionTask: URLSessionDataTask?
    private var completionWorkItem: DispatchWorkItem?
    private var results = SearchResults.empty
    private var showsRemoteSuggestions = false
    
    init(
        userDataSearch: UserDataSearch = UserDataSearch(),
        searchCompletion: SearchCompletion = SearchCompletion(provider: Prefs.SearchSettings.searchSuggestionProvider)
    ) {
        self.userDataSearch = userDataSearch
        self.searchCompletion = searchCompletion
    }
    
    deinit {
        completionTask?.cancel()
        completionWorkItem?.cancel()
    }
    
    func clear() {
        requestID += 1
        completionTask?.cancel()
        completionWorkItem?.cancel()
        completionTask = nil
        completionWorkItem = nil
        showsRemoteSuggestions = false
        results = .empty
        resultsDidChange?(.empty)
    }
    
    func updateQuery(
        _ query: String,
        activeTabMode: TabMode?,
        excludingTabID: UUID?
    ) {
        guard !query.isEmpty else {
            clear()
            return
        }
        
        requestID += 1
        let activeRequestID = requestID
        completionTask?.cancel()
        completionWorkItem?.cancel()
        updateSearchCompletionProviderIfNeeded()
        results.query = query
        results.completions = LocalURLCompletion.completions(for: query)
        resultsDidChange?(results)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else {
                return
            }
            
            let userData = self.userDataSearch.search(
                query: query,
                activeTabMode: activeTabMode,
                excludingTabID: excludingTabID
            )
            
            DispatchQueue.main.async {
                guard activeRequestID == self.requestID else {
                    return
                }
                
                self.results.bestMatch = userData.bestMatch
                self.results.userDataResults = userData.results
                self.resultsDidChange?(self.results)
            }
        }
        
        showsRemoteSuggestions = Prefs.SearchSettings.showSearchSuggestions
        && (activeTabMode != .private || Prefs.SearchSettings.showSearchSuggestionsInPrivateBrowsing)
        guard showsRemoteSuggestions else {
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self,
                  activeRequestID == self.requestID else {
                return
            }

            self.completionTask = self.searchCompletion.fetchCompletions(for: query) { [weak self] completions in
                DispatchQueue.main.async {
                    guard let self,
                          activeRequestID == self.requestID else {
                        return
                    }

                    self.results.completions = Self.mergedCompletions(
                        local: LocalURLCompletion.completions(for: query),
                        remote: completions
                    )
                    self.resultsDidChange?(self.results)
                }
            }
        }
        completionWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18, execute: workItem)
    }
    
    private func updateSearchCompletionProviderIfNeeded() {
        let provider = Prefs.SearchSettings.searchSuggestionProvider
        guard searchCompletion.provider != provider else {
            return
        }
        
        searchCompletion = SearchCompletion(provider: provider)
    }

    private static func mergedCompletions(local: [String], remote: [String]) -> [String] {
        var seen = Set<String>()
        return (local + remote).filter { completion in
            let key = completion.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            return !key.isEmpty && seen.insert(key).inserted
        }
    }
}
