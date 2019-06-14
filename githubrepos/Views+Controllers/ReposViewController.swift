//
//  ReposViewController.swift
//  githubrepos
//
//  Created by user on 2019. 06. 13..
//  Copyright © 2019. poimas. All rights reserved.
//

import UIKit

class ReposViewController: UITableViewController {
    
    var detailViewController: ContributorsViewController? = nil
    var objects = [GithubRepoElement]()
    var offset = 0
    
    let maximumDisplayedElementsCount = 25
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? ContributorsViewController
        }
        loadRepos()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }
    
    // MARK: - Segues
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let githubrepoElement = objects[indexPath.row + offset]
                let controller = (segue.destination as! UINavigationController).topViewController as! ContributorsViewController
                controller.detailItem = githubrepoElement
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if offset > objects.count - maximumDisplayedElementsCount {
            return objects.count - maximumDisplayedElementsCount
        }
        return maximumDisplayedElementsCount
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let object = objects[indexPath.row + offset]
        cell.textLabel!.text = object.name
        cell.detailTextLabel?.text = object.fullName
        return cell
    }
    
    
    @IBOutlet weak var previousButton: UIButton!
    @IBAction func previousPressed(_ sender: UIButton) {
        nextButton.isEnabled = true
        if offset >= maximumDisplayedElementsCount {
            offset -= maximumDisplayedElementsCount
        }
        if offset < maximumDisplayedElementsCount {
            previousButton.isEnabled = false
        }
        tableView.reloadData()
    }
    
    @IBOutlet weak var nextButton: UIButton!
    @IBAction func nextPressed(_ sender: UIButton) {
        offset += maximumDisplayedElementsCount
        if offset > objects.count - maximumDisplayedElementsCount {
            nextButton.isEnabled = false
        }
        if offset == objects.count - maximumDisplayedElementsCount {
            loadRepos(since: objects.last!.id + 1)
        }
        previousButton.isEnabled = true
        tableView.reloadData()
        
        let indexPath = IndexPath(row: 0, section: 0)
        self.tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        
    }
    
    // MARK: - Service
    
    func loadRepos(since: Int = 0) {
        guard let url = URL(string: "https://api.github.com/repositories?since=\(since)") else { return }
        nextButton.isEnabled = false
        let task = URLSession.shared.githubReposTask(with: url) {[weak self] githubRepoElements, response, error in
            guard let githubRepoElements = githubRepoElements else {
                let alert = UIAlertController(title: "A technical error occurred", message: "Please restart the app", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Exit", style: UIAlertAction.Style.default, handler: { _ in exit(1) }))
                self?.present(alert, animated: true, completion: nil)
                return
            }
            self?.objects += githubRepoElements
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.nextButton.isEnabled = true
            }
            
        }
        task.resume()
    }
}

